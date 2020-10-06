import Foundation
import SwiftSyntax

struct Parser {
    static func parse(code: String) throws -> Response {
        let sourceFile = try SyntaxParser.parse(source: code)

        let visitor = TokenVisitor()
        visitor.visitPre(sourceFile._syntaxNode)
        _ = visitor.visit(sourceFile)

        let html = "\(visitor.list.joined())"

        let tree = visitor.tree
        let encoder = JSONEncoder()
        let json = String(data: try encoder.encode(tree), encoding: .utf8)!

        return Response(syntaxHTML: html, syntaxJSON: json, swiftVersion: swiftVersion)
    }
}
