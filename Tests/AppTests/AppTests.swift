@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testRootPath() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "/", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }

    func testGistPath() throws {
        let path = "/b4f866efb1c1dc63b0a9cce000cf5688"

        let pattern = try! NSRegularExpression(pattern: #"^\/([a-f0-9]{32})$"#, options: [.caseInsensitive])
        let matches = pattern.matches(in: path, options: [], range: NSRange(location: 0, length: NSString(string: path).length))
        guard matches.count == 1 && matches[0].numberOfRanges == 2 else {
            XCTFail()
            return
        }
        let gistId = NSString(string: path).substring(with: matches[0].range(at: 1))

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
                XCTAssertEqual(content, """
                    struct Player {
                        var name: String
                        var highScore: Int = 0
                        var history: [Int] = []

                        init(_ name: String) {
                            self.name = name
                        }
                    }

                    var player = Player("Tomas")

                    """)
            } else {
                XCTFail()
            }

            ex.fulfill()
        }
        .resume()

        waitForExpectations(timeout: 5)
    }
}
