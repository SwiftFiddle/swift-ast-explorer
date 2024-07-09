import Vapor

final class CustomHeaderMiddleware: AsyncMiddleware {
  func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response {
    let response = try await next.respond(to: request)
    response.headers.add(name: "X-Frame-Options", value: "DENY")
    response.headers.add(name: "Permissions-Policy", value: "interest-cohort=()")
    return response
  }
}
