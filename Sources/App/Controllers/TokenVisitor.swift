import Foundation
import SwiftSyntax

final class TokenVisitor: SyntaxRewriter {
  var list = [String]()

  var tree = [TreeNode]()
  var current: TreeNode!

  var index = 0

  let converter: SourceLocationConverter

  init(converter: SourceLocationConverter) {
    self.converter = converter
  }

  override func visitPre(_ node: Syntax) {
    var syntax = "\(node.syntaxNodeType)"
    if syntax.hasSuffix("Syntax") {
      syntax = String(syntax.dropLast(6))
    }
    list.append("<span class='\(syntax)' data-title='Syntax' data-content='\(syntax)'>")

    let syntaxType: SyntaxType
    switch node {
    case _ where node.is(DeclSyntax.self):
      syntaxType = .decl
    case _ where node.is(ExprSyntax.self):
      syntaxType = .expr
    case _ where node.is(PatternSyntax.self):
      syntaxType = .pattern
    case _ where node.is(TypeSyntax.self):
      syntaxType = .type
    default:
      syntaxType = .other
    }

    let sourceRange = node.sourceRange(converter: converter)
    let start = sourceRange.start
    let end = sourceRange.end

    let treeNode = TreeNode(
      id: index,
      text: syntax,
      range: Range(
        startRow: start.line.flatMap { $0 - 1 } ?? 1,
        startColumn: start.column.flatMap { $0 - 1 } ?? 1,
        endRow: end.line.flatMap { $0 - 1 } ?? 1,
        endColumn: end.column.flatMap { $0 - 1 } ?? 1
      ),
      type: syntaxType
    )
    
    tree.append(treeNode)
    index += 1

    switch node.syntaxNodeType.structure {
    case .layout(let keyPaths):
      if let syntaxNode = node.as(node.syntaxNodeType) {
        for (index, keyPath) in keyPaths.enumerated() {
          let mirror = Mirror(reflecting: syntaxNode)
          if let label = mirror.children.map({ $0 })[index].label {
            let key = label
            switch syntaxNode[keyPath: keyPath] {
            case let value as TokenSyntax:
              treeNode.structure.append(
                StructureProperty(
                  name: key,
                  value: StructureValue(
                    text: "\(value)"
                      .replacingOccurrences(of: " ", with: "␣")
                      .replacingOccurrences(of: "\n", with: "↲"),
                    kind: "\(value.tokenKind)"
                  )
                )
              )
            case let value?:
              if let value = value as? SyntaxProtocol {
                treeNode.structure.append(StructureProperty(name: key, value: StructureValue(text: "\(value.syntaxNodeType)(...)")))
              } else {
                treeNode.structure.append(StructureProperty(name: key, value: StructureValue(text: "\(value)")))
              }
            case .none:
              treeNode.structure.append(StructureProperty(name: key))
            }
          }
        }
      }
    case .collection, .choices:
      break
    }

    if let current {
      treeNode.parent = current.id
    }
    current = treeNode
  }

  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    current.text = token.text
    current.token = Token(kind: "\(token.tokenKind)", leadingTrivia: "", trailingTrivia: "")

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

    return token
  }

  override func visitPost(_ node: Syntax) {
    list.append("</span>")
    if let parent = current.parent {
      current = tree[parent]
    } else {
      current = nil
    }
  }

  private func processToken(_ token: TokenSyntax) {
    var kind = "\(token.tokenKind)"
    if let index = kind.firstIndex(of: "(") {
      kind = String(kind.prefix(upTo: index))
    }
    if kind.hasSuffix("Keyword") {
      kind = "keyword"
    }

    list.append(
      "<span class='token \(kind)' data-title='Token' data-content='\(token.tokenKind)'>\(escapeHtmlSpecialCharacters(token.text))</span>"
    )
  }

  private func processTriviaPiece(_ piece: TriviaPiece) -> String {
    func wrapWithSpanTag(class c: String, text: String) -> String {
      "<span class='\(c)' data-title='Trivia' data-content='\(c)'>\(escapeHtmlSpecialCharacters(text))</span>"
    }

    var trivia = ""
    switch piece {
    case .spaces(let count):
      trivia += String(repeating: "&nbsp;", count: count)
    case .tabs(let count):
      trivia += String(repeating: "&nbsp;", count: count * 2)
    case .verticalTabs, .formfeeds:
      break
    case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
      trivia += String(repeating: "<br>", count: count)
    case .lineComment(let text):
      trivia += wrapWithSpanTag(class: "lineComment", text: text)
    case .blockComment(let text):
      trivia += wrapWithSpanTag(class: "blockComment", text: text)
    case .docLineComment(let text):
      trivia += wrapWithSpanTag(class: "docLineComment", text: text)
    case .docBlockComment(let text):
      trivia += wrapWithSpanTag(class: "docBlockComment", text: text)
    case .unexpectedText(let text):
      trivia += wrapWithSpanTag(class: "unexpectedText", text: text)
    case .shebang(let text):
      trivia += wrapWithSpanTag(class: "shebang", text: text)
    }
    return trivia
  }

  private func replaceSymbols(text: String) -> String {
    text.replacingOccurrences(of: "&nbsp;", with: "␣").replacingOccurrences(of: "<br>", with: "↲")
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
