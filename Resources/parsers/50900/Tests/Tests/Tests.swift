@testable import parser
import XCTest

final class Tests: XCTestCase {
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

    write(response.syntaxJSON, filename: "test-1-1.json")
    write(response.syntaxHTML, filename: "test-1-1.html")
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

    write(response.syntaxJSON, filename: "test-1-2.json")
    write(response.syntaxHTML, filename: "test-1-2.html")
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

    write(response.syntaxJSON, filename: "test-1-3.json")
    write(response.syntaxHTML, filename: "test-1-3.html")
  }

  func testParser4() throws {
    let response = try SyntaxParser.parse(
      code: """
        struct Result< {{
          let text: String
          let someOtherThing: String
        }
        """,
      options: ["showmissing"]
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-1-4.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-1-4.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )

    write(response.syntaxJSON, filename: "test-1-4.json")
    write(response.syntaxHTML, filename: "test-1-4.html")
  }

  func testParser5() throws {
    let response = try SyntaxParser.parse(
      code: """
        if a + b * c {
          return
        }
        """
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-1-5.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-1-5.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )

    write(response.syntaxJSON, filename: "test-1-5.json")
    write(response.syntaxHTML, filename: "test-1-5.html")
  }

  func testParser6() throws {
    let response = try SyntaxParser.parse(
      code: """
        if a + b × c {
          return
        }
        """
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-1-6.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-1-6.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )

    write(response.syntaxJSON, filename: "test-1-6.json")
    write(response.syntaxHTML, filename: "test-1-6.html")
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

    write(response.syntaxJSON, filename: "test-2-1.json")
    write(response.syntaxHTML, filename: "test-2-1.html")
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

    write(response.syntaxJSON, filename: "test-2-2.json")
    write(response.syntaxHTML, filename: "test-2-2.html")
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

    write(response.syntaxJSON, filename: "test-2-3.json")
    write(response.syntaxHTML, filename: "test-2-3.html")
  }

  func testParserFolding4() throws {
    let response = try SyntaxParser.parse(
      code: """
        struct Result< {{
          let text: String
          let someOtherThing: String
        }
        """,
      options: ["fold", "showmissing"]
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-2-4.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-2-4.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )

    write(response.syntaxJSON, filename: "test-2-4.json")
    write(response.syntaxHTML, filename: "test-2-4.html")
  }

  func testParserFolding5() throws {
    let response = try SyntaxParser.parse(
      code: """
        if a + b * c {
          return
        }
        """,
      options: ["fold"]
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-2-5.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-2-5.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )

    write(response.syntaxJSON, filename: "test-2-5.json")
    write(response.syntaxHTML, filename: "test-2-5.html")
  }

  func testParserFolding6() throws {
    let response = try SyntaxParser.parse(
      code: """
        if a + b × c {
          return
        }
        """,
      options: ["fold"]
    )

    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode([TreeNode].self, from: Data(response.syntaxJSON.utf8)),
      try decoder.decode(
        [TreeNode].self, from: Data(
          contentsOf: Bundle.module.url(forResource: "test-2-6.json", withExtension: nil)!
        )
      )
    )
    XCTAssertEqual(
      response.syntaxHTML,
      try String(
        contentsOf: Bundle.module.url(forResource: "test-2-6.html", withExtension: nil)!
      )
      .replacingOccurrences(of: "\n", with: "")
    )

    write(response.syntaxJSON, filename: "test-2-6.json")
    write(response.syntaxHTML, filename: "test-2-6.html")
  }
}

func write(_ text: String, filename: String) {
  let directory: String? = nil
  if let directory {
    try! text.write(toFile: "\(directory)/\(filename)", atomically: true, encoding: .utf8)
  }
}
