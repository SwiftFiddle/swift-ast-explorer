import Vapor
import TSCBasic

func routes(_ app: Application) throws {
  app.get("healthz") { _ in ["status": "pass"] }

  app.get { (req) in try await index(req) }
  app.get("index.html") { (req) in try await index(req) }
  func index(_ req: Request) async throws -> View {
    try await req.view.render(
      "index", [
        "title": "Swift AST Explorer",
        "defaultSampleCode": defaultSampleCode,
        "swiftVersion": swiftVersion,
      ]
    )
  }

  app.get("*") { (req) -> View in
    let matches = try #/^/([a-f0-9]{32})$/#
      .ignoresCase()
      .wholeMatch(in: req.url.path)
    guard let matches else { throw Abort(.notFound) }
    let gistId = matches.output.1

    let response = try await req.client.get(
      URI(string: "https://api.github.com/gists/\(gistId)"), headers: HTTPHeaders([("User-Agent", "Swift AST Explorer")])
    )

    guard let body = response.body else {
      throw Abort(.notFound)
    }
    guard
      let contents = try? JSONSerialization.jsonObject(with: Data(body.readableBytesView), options: []) as? [String: Any],
      let files = contents["files"] as? [String: Any],
      let filename = files.keys.first, let file = files[filename] as? [String: Any],
      let content = file["content"] as? String else {
      throw Abort(.notFound)
    }

    return try await req.view.render(
      "index", [
        "title": "Swift AST Explorer",
        "defaultSampleCode": content,
        "swiftVersion": swiftVersion,
      ]
    )
  }

  app.on(.POST, "update", body: .collect(maxSize: "10mb")) { (req) -> SyntaxResponse in
    let parameter = try req.content.decode(RequestParameter.self)
    let options = parameter.options ?? []
    if let branch = parameter.branch, branch != "branch_stable" {
      let response = try await experimentalParser(branch: branch, arguments: [parameter.code] + options)
      return try JSONDecoder().decode(SyntaxResponse.self, from: Data(response.stdout.utf8))
    } else {
      return try SyntaxParser.parse(code: parameter.code, options: options)
    }
  }

  func experimentalParser(branch: String, arguments: [String]) async throws -> (stdout: String, stderr: String) {
    let process = TSCBasic.Process(
      arguments: ["parser"] + arguments,
      environment: [
        "NSUnbufferedIO": "YES",
      ],
      workingDirectory: try! AbsolutePath.init(validating: "\(app.directory.resourcesDirectory)\(branch)/.build/debug/")
    )

    try process.launch()
    let processResult = try await process.waitUntilExit()

    let stdout = try processResult.utf8Output()
    let stderr = try processResult.utf8stderrOutput()

    return (stdout, stderr)
  }
}

let swiftVersion = Environment.get("SWIFT_VERSION") ?? ""

private struct RequestParameter: Decodable {
  let code: String
  let options: [String]?
  let branch: String?
}

private let defaultSampleCode = #"""
import Foundation

struct BlackjackCard {
  // nested Suit enumeration
  enum Suit: Character {
    case spades = "♠"
    case hearts = "♡"
    case diamonds = "♢"
    case clubs = "♣"
  }

  // nested Rank enumeration
  enum Rank: Int {
    case two = 2
    case three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    struct Values {
      let first: Int, second: Int?
    }

    var values: Values {
      switch self {
      case .ace:
        return Values(first: 1, second: 11)
      case .jack, .queen, .king:
        return Values(first: 10, second: nil)
      default:
        return Values(first: self.rawValue, second: nil)
      }
    }
  }

  // BlackjackCard properties and methods
  let rank: Rank, suit: Suit
  var description: String {
    var output = "suit is \(suit.rawValue),"
    output += " value is \(rank.values.first)"
    if let second = rank.values.second {
      output += " or \(second)"
    }
    return output
  }
}

"""#
