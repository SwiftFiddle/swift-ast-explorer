import Vapor

let swiftVersion = Environment.get("SWIFT_VERSION") ?? ""

func routes(_ app: Application) throws {
    app.get { req in
        req.view.render("index", [
            "title": "Swift AST Explorer",
            "swiftVersion": swiftVersion
        ])
    }
    app.get("index.html") { req in
        req.view.render("index", [
            "title": "Swift AST Explorer",
            "swiftVersion": swiftVersion
        ])
    }

    app.post("update") { req -> EventLoopFuture<Response> in
        let parameter = try req.content.decode(RequestParameter.self)

        let promise = req.eventLoop.makePromise(of: Response.self)
        DispatchQueue.global().async {
            do {
                promise.succeed(try Parser.parse(code: parameter.code))
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

struct Response: Content {
    let syntaxHTML: String
    let syntaxJSON: String
    let swiftVersion: String
}
