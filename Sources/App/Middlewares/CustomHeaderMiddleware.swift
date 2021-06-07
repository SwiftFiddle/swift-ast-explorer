import Vapor

final class CustomHeaderMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).map { (response) in
            response.headers.add(name: "X-Frame-Options", value: "DENY")
            response.headers.add(name: "Permissions-Policy", value: "interest-cohort=()")
            return response
        }
    }
}
