import Foundation
import SwiftSyntax
import SwiftOperators
import SwiftParser

struct SyntaxParser {
  static func parse(code: String, options: [String] = []) throws -> SyntaxResponse {
    let sourceFile = Parser.parse(source: code)

    let syntax: Syntax
    if options.contains("fold") {
      syntax = OperatorTable.standardOperators.foldAll(sourceFile, errorHandler: { _ in })
    } else {
      syntax = Syntax(sourceFile)
    }

    let visitor = TokenVisitor(
      locationConverter: SourceLocationConverter(file: "", tree: sourceFile),
      showMissingTokens: options.contains("showmissing")
    )
    _ = visitor.rewrite(syntax)

    let html = "\(visitor.list.joined())"

    let tree = visitor.tree
    let encoder = JSONEncoder()
    let json = String(decoding: try encoder.encode(tree), as: UTF8.self)

    return SyntaxResponse(syntaxHTML: html, syntaxJSON: json, swiftVersion: version)
  }
}
