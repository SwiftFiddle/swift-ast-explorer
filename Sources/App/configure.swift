import Vapor
import Leaf

public func configure(_ app: Application) async throws {
  app.middleware = Middlewares()
  app.middleware.use(CommonErrorMiddleware())
  app.middleware.use(CustomHeaderMiddleware())

  let publicDirectory = "\(app.directory.publicDirectory)/dist"
  app.middleware.use(FileMiddleware(publicDirectory: publicDirectory))

  app.http.server.configuration.port = Environment.process.PORT.flatMap { Int($0) } ?? 8080
  app.http.server.configuration.requestDecompression = .enabled
  app.http.server.configuration.responseCompression = .enabled
  app.http.server.configuration.supportPipelining = true

  app.views.use(.leaf)
  app.leaf.configuration.rootDirectory = publicDirectory
  app.leaf.cache.isEnabled = app.environment.isRelease

  try routes(app)
}
