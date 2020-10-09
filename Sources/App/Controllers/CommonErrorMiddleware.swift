import Vapor

final class CommonErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).flatMapError { (error) in
            let headers: HTTPHeaders
            let status: HTTPResponseStatus
            let reason: String
            let title: String
            switch error {
            case let abort as AbortError:
                headers = abort.headers
                status = abort.status
                title = "Not Found"
                reason = status == .notFound ? "Sorry, an error has occured, Requested page not found!" : abort.reason
            default:
                headers = [:]
                status = .internalServerError
                title = "Internal Server Error"
                reason = "Something went wrong."
            }

            return request.view.render("error", [
                "title": title,
                "status": "\(status.code)",
                "reason": reason,
            ])
            .encodeResponse(status: status, headers: headers, for: request)
        }
    }
}
