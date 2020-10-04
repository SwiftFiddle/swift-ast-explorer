import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.eventLoop.makeSucceededFuture(
            req.fileio.streamFile(at: "Public/index.html")
        )
    }

    app.post("update") { req -> EventLoopFuture<[String: [String: String]]> in
        let parameter = try req.content.decode(RequestParameter.self)

        let promise = req.eventLoop.makePromise(of: [String: [String: String]].self)
        DispatchQueue.global().async {
            do {
                promise.succeed(["output": try Parser.parse(code: parameter.code)])
            } catch {
                promise.fail(error)
            }
        }

        return promise.futureResult
    }
}

struct RequestParameter: Decodable {
    let code: String
}
