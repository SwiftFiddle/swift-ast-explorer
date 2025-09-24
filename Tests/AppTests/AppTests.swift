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
}
