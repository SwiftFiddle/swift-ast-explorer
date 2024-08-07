import Vapor

struct CommonErrorMiddleware: AsyncMiddleware {
  func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response {
    do {
      return try await next.respond(to: request)
    } catch let error {
      let headers: HTTPHeaders
      let status: HTTPResponseStatus
      switch error {
      case let abort as AbortError:
        headers = abort.headers
        status = abort.status
      default:
        headers = [:]
        status = .internalServerError
      }

      let errotTitles: [UInt: String] = [
        400: "Bad Request",
        401: "Unauthorized",
        403: "Access Denied",
        404: "Resource not found",
        500: "Webservice currently unavailable",
        503: "Webservice currently unavailable",
      ]

      let errotReasons: [UInt: String] = [
        400: "The server cannot process the request due to something that is perceived to be a client error.",
        401: "The requested resource requires an authentication.",
        403: "The requested resource requires an authentication.",
        404: "The requested resource could not be found but may be available again in the future.",
        500: "An unexpected condition was encountered. Our service team has been dispatched to bring it back online.",
        503: "We&#39;ve got some trouble with our backend upstream cluster. Our service team has been dispatched to bring it back online.",
      ]

      if request.headers[.accept].map({ $0.lowercased() }).contains("application/json") {
        let data = try JSONEncoder().encode(["error": status.code])
        
        return .init(
          status: status,
          headers: headers,
          body: .init(data: data)
        )
      } else {
        let view = try await request.view.render(
          "error",
          [
            "title": "We've got some trouble",
            "error": errotTitles[status.code],
            "reason": errotReasons[status.code],
            "status": "\(status.code)",
          ]
        ).get()

        return try await view.encodeResponse(
          status: status,
          headers: headers,
          for: request
        )
      }
    }
  }
}
