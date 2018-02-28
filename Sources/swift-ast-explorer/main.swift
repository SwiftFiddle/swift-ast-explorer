import Foundation
import Basic
import SwiftSyntax

class TokenVisitor : SyntaxVisitor {
    var list = [String]()
    var types = [ImportDeclSyntax.self, StructDeclSyntax.self, ClassDeclSyntax.self, UnknownDeclSyntax.self, FunctionDeclSyntax.self, VariableDeclSyntax.self,
                 IfStmtSyntax.self, SwitchStmtSyntax.self, ForInStmtSyntax.self, WhileStmtSyntax.self, RepeatWhileStmtSyntax.self,
                 DoStmtSyntax.self, CatchClauseSyntax.self, FunctionCallExprSyntax.self] as [Any.Type]

    override func visitPre(_ node: Syntax) {
        for t in types {
            if type(of: node) == t {
                list.append("<div class=\"box \(type(of: node))\" data-tooltip=\"\(type(of: node))\">")
            }
        }
    }

    override func visit(_ token: TokenSyntax) {
        token.leadingTrivia.forEach { (piece) in
            processTriviaPiece(piece)
        }
        processToken(token)
        token.trailingTrivia.forEach { (piece) in
            processTriviaPiece(piece)
        }
    }

    override func visitPost(_ node: Syntax) {
        for t in types {
            if type(of: node) == t {
                list.append("</div>")
            }
        }
    }

    private func processToken(_ token: TokenSyntax) {
        var kind = "\(token.tokenKind)"
        if let index = kind.index(of: "(") {
            kind = String(kind.prefix(upTo: index))
        }
        if kind.hasSuffix("Keyword") {
            kind = "keyword"
        }
        list.append(withSpanTag(class: kind, text: token.text))
    }

    private func processTriviaPiece(_ piece: TriviaPiece) {
        switch piece {
        case .spaces(let count):
            list.append(String(repeating: "&nbsp;", count: count))
        case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
            var count = count
            if let last = list.last, last.hasPrefix("<div") {
                count -= 1
            }
            for _ in 0..<count {
                list.append("<br>\n")
            }
        case .backticks(let count):
            list.append(String(repeating: "`", count: count))
        case .lineComment(let text), .blockComment(let text), .docLineComment(let text), .docBlockComment(let text):
            list.append(withSpanTag(class: "comment", text: text))
        default:
            break
        }
    }

    private func withSpanTag(class c: String, text: String) -> String {
        return "<span class='\(c)'>" + text + "</span>"
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
let filePath = URL(fileURLWithPath: arguments[0])

let sourceFile = try! SourceFileSyntax.parse(filePath)
let visitor = TokenVisitor()
visitor.visit(sourceFile)
let html = visitor.list.joined()

let htmlPath = filePath.deletingPathExtension().appendingPathExtension("html")
let fileSystem = Basic.localFileSystem
try! fileSystem.writeFileContents(AbsolutePath(htmlPath.path), bytes: ByteString(encodingAsUTF8: html))
