import Foundation
import SwiftSyntax
import SwiftOperators
import SwiftSyntaxParser

struct Parser {
  static func parse(code: String, options: [String] = []) throws -> SyntaxResponse {
    let sourceFile = try SyntaxParser.parse(source: code, enableBareSlashRegexLiteral: true)
    let syntax: Syntax
    if options.contains("fold"), let folded = try? OperatorTable.standardOperators.foldAll(sourceFile) {
      syntax = folded
    } else {
      syntax = Syntax(sourceFile)
    }

    let visitor = TokenVisitor(converter: SourceLocationConverter(file: "", tree: sourceFile))
    _ = visitor.visit(syntax)

    let html = "\(visitor.list.joined())"

    let tree = visitor.tree
    let encoder = JSONEncoder()
    let json = String(decoding: try encoder.encode(tree), as: UTF8.self)

    return SyntaxResponse(syntaxHTML: html, syntaxJSON: json, swiftVersion: swiftVersion)
  }
}
