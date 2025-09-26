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
}
