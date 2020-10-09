import Vapor
import Leaf

public func configure(_ app: Application) throws {
    app.middleware = .init()
    app.middleware.use(CommonErrorMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.http.server.configuration.supportPipelining = true
    app.http.server.configuration.requestDecompression = .enabled
    app.http.server.configuration.responseCompression = .enabled

    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease

    try routes(app)
}
