import Vapor

public func configure(_ app: Application) throws {
    app.http.server.configuration.port = 3000
    app.http.server.configuration.supportPipelining = true
    app.http.server.configuration.requestDecompression = .enabled
    app.http.server.configuration.responseCompression = .enabled
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    try routes(app)
}
