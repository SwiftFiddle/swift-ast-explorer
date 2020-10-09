import Foundation
import SwiftSyntax

struct Parser {
    static func parse(code: String) throws -> SyntaxResponse {
        let sourceFile = try SyntaxParser.parse(source: code)

        let visitor = TokenVisitor()
        visitor.visitPre(sourceFile._syntaxNode)
        _ = visitor.visit(sourceFile)

        let html = "\(visitor.list.joined())"

        let tree = visitor.tree
        let encoder = JSONEncoder()
        let json = String(data: try encoder.encode(tree), encoding: .utf8)!

        let statistics = visitor.statistics.keys
            .sorted()
            .map {
                [
                    "syntax": $0,
                    "count": "\(visitor.statistics[$0]?.count ?? 0)",
                    "ranges": "[\((visitor.statistics[$0] ?? []).map { #"{ "startRow": \#($0.range.startRow), "startColumn": \#($0.range.startColumn), "endRow": \#($0.range.endRow), "endColumn": \#($0.range.endColumn) }"# }.joined(separator: ","))]",
                ]
            }

        return SyntaxResponse(syntaxHTML: html, syntaxJSON: json, statistics: statistics, swiftVersion: swiftVersion)
    }
}
