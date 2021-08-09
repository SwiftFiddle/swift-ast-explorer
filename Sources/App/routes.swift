import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.view.render("index", [
            "title": "Swift AST Explorer",
            "defaultSampleCode": defaultSampleCode,
            "swiftVersion": swiftVersion,
        ])
    }

    app.get("index.html") { req -> EventLoopFuture<View> in
        req.view.render("index", [
            "title": "Swift AST Explorer",
            "defaultSampleCode": defaultSampleCode,
            "swiftVersion": swiftVersion,
        ])
    }

    app.get("*") { req -> EventLoopFuture<View> in
        let pattern = try! NSRegularExpression(pattern: #"^\/([a-f0-9]{32})$"#, options: [.caseInsensitive])
        let matches = pattern.matches(in: req.url.path, options: [], range: NSRange(location: 0, length: NSString(string: req.url.path).length))
        guard matches.count == 1 && matches[0].numberOfRanges == 2 else {
            throw Abort(.notFound)
        }
        let gistId = NSString(string: req.url.path).substring(with: matches[0].range(at: 1))

        let promise = req.eventLoop.makePromise(of: View.self)
        req.client.get(
            URI(string: "https://api.github.com/gists/\(gistId)"), headers: HTTPHeaders([("User-Agent", "Swift AST Explorer")])
        ).whenComplete {
            switch $0 {
            case .success(let response):
                guard let body = response.body else {
                    promise.fail(Abort(.notFound))
                    return
                }
                guard
                    let contents = try? JSONSerialization.jsonObject(with: Data(body.readableBytesView), options: []) as? [String: Any],
                    let files = contents["files"] as? [String: Any],
                    let filename = files.keys.first, let file = files[filename] as? [String: Any],
                    let content = file["content"] as? String else {
                    promise.fail(Abort(.notFound))
                    return
                }

                return req.view.render(
                    "index", [
                        "title": "Swift AST Explorer",
                        "defaultSampleCode": content,
                        "swiftVersion": swiftVersion,
                    ]
                )
                .cascade(to: promise)
            case .failure(let error):
                promise.fail(error)
            }
        }

        return promise.futureResult
    }

    app.on(.POST, "update", body: .collect(maxSize: "10mb")) { req -> EventLoopFuture<SyntaxResponse> in
        let parameter = try req.content.decode(RequestParameter.self)

        let promise = req.eventLoop.makePromise(of: SyntaxResponse.self)
        DispatchQueue.global().async {
            do {
                promise.succeed(try Parser.parse(code: parameter.code))
            } catch {
                promise.fail(error)
            }
        }

        return promise.futureResult
    }
}

let swiftVersion = Environment.get("SWIFT_VERSION") ?? ""

private struct RequestParameter: Decodable {
    let code: String
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
