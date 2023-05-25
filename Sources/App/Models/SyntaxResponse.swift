import Vapor

struct SyntaxResponse: Content {
  let syntaxHTML: String
  let syntaxJSON: String
  let swiftVersion: String
}
