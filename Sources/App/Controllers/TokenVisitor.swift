import Foundation
import SwiftSyntax

final class TokenVisitor: SyntaxRewriter {
    var list = [String]()

    var tree = [Node]()
    var current: Node!

    var statistics = SyntaxStatistics()

    var row = 0
    var column = 0

    override func visitPre(_ node: Syntax) {
        var syntax = "\(node.syntaxNodeType)"
        if syntax.hasSuffix("Syntax") {
            syntax = String(syntax.dropLast(6))
        }
        list.append("<span class='\(syntax)' data-tooltip-title='Syntax' data-tooltip-content='\(syntax)'>")

        let n = Node(text: syntax)
        n.range.startRow = row
        n.range.startColumn = column
        n.range.endRow = row
        n.range.endColumn = column

        switch node.syntaxNodeType.structure {
        case .layout(let keyPaths):
            if let syntaxNode = node.as(node.syntaxNodeType) {
                for keyPath in keyPaths {
                    if let value = syntaxNode[keyPath: keyPath] {
                        let key = "\(keyPath)".replacingOccurrences(of: #"\\#(node.syntaxNodeType)."#, with: "")
                        n.structure[key] = "\(value)"
                    }
                }
            }
        case .collection, .choices:
            break
        }

        if current == nil {
            tree.append(n)
        } else {
            current.add(node: n)
            statistics.append(node: n)
        }
        current = n
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        current.text = token.text
        current.token = Node.Token(kind: "\(token.tokenKind)", leadingTrivia: "", trailingTrivia: "")

        current.range.startRow = row
        current.range.startColumn = column

        token.leadingTrivia.forEach { (piece) in
            let trivia = processTriviaPiece(piece)
            list.append(trivia)
            current.token?.leadingTrivia += replaceSymbols(text: trivia)
        }
        processToken(token)
        token.trailingTrivia.forEach { (piece) in
            let trivia = processTriviaPiece(piece)
            list.append(trivia)
            current.token?.trailingTrivia += replaceSymbols(text: trivia)
        }

        current.range.endRow = row
        current.range.endColumn = column

        return token
    }

    override func visitPost(_ node: Syntax) {
        list.append("</span>")
        current.range.endRow = row
        current.range.endColumn = column
        current = current.parent
    }

    private func processToken(_ token: TokenSyntax) {
        var kind = "\(token.tokenKind)"
        if let index = kind.firstIndex(of: "(") {
            kind = String(kind.prefix(upTo: index))
        }
        if kind.hasSuffix("Keyword") {
            kind = "keyword"
        }

        list.append("<span class='token \(kind)' data-tooltip-title='Token' data-tooltip-content='\(token.tokenKind)'>\(escapeHtmlSpecialCharacters(token.text))</span>")
        column += token.text.count
    }

    private func processTriviaPiece(_ piece: TriviaPiece) -> String {
        func wrapWithSpanTag(class c: String, text: String) -> String {
            return "<span class='\(c)' data-tooltip-title='Trivia' data-tooltip-content='\(c)'>\(escapeHtmlSpecialCharacters(text))</span>"
        }

        var trivia = ""
        switch piece {
        case .spaces(let count):
            trivia += String(repeating: "&nbsp;", count: count)
            column += count
        case .tabs(let count):
            trivia += String(repeating: "&nbsp;", count: count * 2)
            column += count * 2
        case .verticalTabs, .formfeeds:
            break
        case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
            trivia += String(repeating: "<br>", count: count)
            row += count
            column = 0
        case .lineComment(let text):
            trivia += wrapWithSpanTag(class: "lineComment", text: text)
            processComment(text: text)
        case .blockComment(let text):
            trivia += wrapWithSpanTag(class: "blockComment", text: text)
            processComment(text: text)
        case .docLineComment(let text):
            trivia += wrapWithSpanTag(class: "docLineComment", text: text)
            processComment(text: text)
        case .docBlockComment(let text):
            trivia += wrapWithSpanTag(class: "docBlockComment", text: text)
            processComment(text: text)
        case .unexpectedText(let text):
            trivia += wrapWithSpanTag(class: "unexpectedText", text: text)
            processComment(text: text)
        case .shebang(let text):
            trivia += wrapWithSpanTag(class: "shebang", text: text)
            processComment(text: text)
        }
        return trivia
    }

    private func replaceSymbols(text: String) -> String {
        return text.replacingOccurrences(of: "&nbsp;", with: "␣").replacingOccurrences(of: "<br>", with: "↲")
    }

    private func processComment(text: String) {
        let comments = text.split(separator: "\n", omittingEmptySubsequences: false)
        row += comments.count - 1
        column += comments.last!.count
    }

    private func escapeHtmlSpecialCharacters(_ string: String) -> String {
        var newString = string
        let specialCharacters = [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;"),
            ("\"", "&quot;"),
            ("'", "&apos;"),
        ];
        for (unescaped, escaped) in specialCharacters {
            newString = newString.replacingOccurrences(of: unescaped, with: escaped, options: .literal, range: nil)
        }
        return newString
    }
}
