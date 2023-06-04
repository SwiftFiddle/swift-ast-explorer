@testable import App
import XCTVapor
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class AppTests: XCTestCase {
  func testRootPath() async throws {
    let app = Application(.testing)
    defer { app.shutdown() }
    try await configure(app)

    try app.test(.GET, "/healthz", afterResponse: { res in
      XCTAssertEqual(res.status, .ok)
    })
  }

  func testGistPath() throws {
    let path = "/b4f866efb1c1dc63b0a9cce000cf5688"


    let matches = try #/^/([a-f0-9]{32})$/#
      .ignoresCase()
      .wholeMatch(in: path)

    let gistId = try XCTUnwrap(matches).output.1

    let ex = expectation(description: "")

    let session = URLSession(configuration: .default)
    let request = URLRequest(url: URL(string: "https://api.github.com/gists/\(gistId)")!)
    session.dataTask(with: request) { (data, response, error) in
      guard let data = data else {
        XCTFail()
        return
      }
      if let contents = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
         let files = contents["files"] as? [String: Any],
         let filename = files.keys.first, let file = files[filename] as? [String: Any],
         let content = file["content"] as? String {
        XCTAssertEqual(
          content,
          """
          struct Player {
              var name: String
              var highScore: Int = 0
              var history: [Int] = []

              init(_ name: String) {
                  self.name = name
              }
          }

          var player = Player("Tomas")

          """
        )
      } else {
        XCTFail()
      }

      ex.fulfill()
    }
    .resume()

    waitForExpectations(timeout: 5)
  }

  func testParser1() throws {
    let response = try SyntaxParser.parse(
      code: """
        let number = 0
        """
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-1-1.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-1-1.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )
  }

  func testParser2() throws {
    let response = try SyntaxParser.parse(
      code: """
        var temperatureInFahrenheit = 90

        if temperatureInFahrenheit <= 32 {
          print("It's very cold. Consider wearing a scarf.")
        } else if temperatureInFahrenheit >= 86 {
          print("It's really warm. Don't forget to wear sunscreen.")
        } else {
          print("It's not that cold. Wear a t-shirt.")
        }

        // Prints "It's really warm. Don't forget to wear sunscreen."
        """
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-1-2.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-1-2.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )
  }

  func testParser3() throws {
    let response = try SyntaxParser.parse(
      code: #"""
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
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-1-3.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-1-3.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )
  }

  func testParserFolding1() throws {
    let response = try SyntaxParser.parse(
      code: """
        let number = 0
        """,
      options: ["fold"]
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-2-1.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-2-1.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )
  }

  func testParserFolding2() throws {
    let response = try SyntaxParser.parse(
      code: """
        var temperatureInFahrenheit = 90

        if temperatureInFahrenheit <= 32 {
          print("It's very cold. Consider wearing a scarf.")
        } else if temperatureInFahrenheit >= 86 {
          print("It's really warm. Don't forget to wear sunscreen.")
        } else {
          print("It's not that cold. Wear a t-shirt.")
        }

        // Prints "It's really warm. Don't forget to wear sunscreen."
        """,
      options: ["fold"]
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-2-2.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-2-2.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )
  }

  func testParserFolding3() throws {
    let response = try SyntaxParser.parse(
      code: #"""
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

        """#,
      options: ["fold"]
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-2-3.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-2-3.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )
  }
}
