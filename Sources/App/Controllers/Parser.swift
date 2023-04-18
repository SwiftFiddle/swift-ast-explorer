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

        let visitor = TokenVisitor()
        visitor.visitPre(syntax._syntaxNode)
        _ = visitor.visit(syntax)

        let html = "\(visitor.list.joined())"

        let tree = visitor.tree
        let encoder = JSONEncoder()
        let json = String(data: try encoder.encode(tree), encoding: .utf8) ?? "{}"

        let statistics = visitor.statistics.sorted

        return SyntaxResponse(syntaxHTML: html, syntaxJSON: json, statistics: statistics, swiftVersion: swiftVersion)
    }
}
