import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
app.http.server.configuration.port = Environment.process.PORT.flatMap { Int($0) } ?? 8080
try configure(app)
try app.run()
