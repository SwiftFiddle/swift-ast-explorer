import Foundation
import SwiftSyntax

final class TokenVisitor: SyntaxRewriter {
  var list = [String]()
  var tree = [TreeNode]()

  private var current: TreeNode!
  private var index = 0

  private let locationConverter: SourceLocationConverter
  private let showMissingTokens: Bool

  init(locationConverter: SourceLocationConverter, showMissingTokens: Bool) {
    self.locationConverter = locationConverter
    self.showMissingTokens = showMissingTokens
  }

  override func visitPre(_ node: Syntax) {
    if let token = node.as(TokenSyntax.self), token.presence == .missing, !showMissingTokens {
      return
    }

    let syntaxNodeType = node.syntaxNodeType

    let className: String
    if "\(syntaxNodeType)".hasSuffix("Syntax") {
      className = String("\(syntaxNodeType)".dropLast(6))
    } else {
      className = "\(syntaxNodeType)"
    }

    let content: String
    let type: String
    if let tokenSyntax = node.as(TokenSyntax.self) {
      content = "\(tokenSyntax.tokenKind)"
      type = "Token"
    } else {
      content = "\(syntaxNodeType)"
      type = "Syntax"
    }

    let sourceRange = node.sourceRange(converter: locationConverter)
    let start = sourceRange.start
    let end = sourceRange.end
    let startRow = start.line ?? 1
    let startColumn = start.column ?? 1
    let endRow = end.line ?? 1
    let endColumn = end.column ?? 1

    list.append(
      "<span class='\(className)' " +
      "data-title='\("\(node.withoutTrivia())".htmlEscaped().displayInvisibles())' " +
      "data-content='\(content.htmlEscaped().substituteInvisibles())' " +
      "data-type='\(type.htmlEscaped())' " +
      #"data-range='{"startRow":\#(startRow),"startColumn":\#(startColumn),"endRow":\#(endRow),"endColumn":\#(endColumn)}'>"#
    )

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

    let treeNode = TreeNode(
      id: index,
      text: className,
      range: Range(
        startRow: startRow,
        startColumn: startColumn,
        endRow: endRow,
        endColumn: endColumn
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
                    text: "\(value.text)"
                      .replacingOccurrences(of: " ", with: "␣")
                      .replacingOccurrences(of: "\n", with: "↲"),
                    kind: "\(value.tokenKind)"
                  )
                )
              )
            case let value?:
              if let value = value as? SyntaxProtocol {
                let type = "\(value.syntaxNodeType)"
                treeNode.structure.append(StructureProperty(name: key, value: StructureValue(text: "\(type)"), ref: "\(type)"))
              } else {
                treeNode.structure.append(StructureProperty(name: key, value: StructureValue(text: "\(value)")))
              }
            case .none:
              treeNode.structure.append(StructureProperty(name: key))
            }
          }
        }
      }
    case .collection(let syntax):
      treeNode.type = .collection
      treeNode.structure.append(StructureProperty(name: "Element", value: StructureValue(text: "\(syntax)")))
      treeNode.structure.append(StructureProperty(name: "Count", value: StructureValue(text: "\(node.children(viewMode: .all).count)")))
      break
    case .choices:
      break
    }

    if let current {
      treeNode.parent = current.id
    }
    current = treeNode
  }

  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    if token.presence == .missing && !showMissingTokens {
      return token
    }

    current.text = token
      .text
      .htmlEscaped()
      .substituteInvisibles()
      .transformWhitespaces()
    if token.presence == .missing {
      current.class = token.presence.rawValue.lowercased()
    }
    current.token = Token(kind: "\(token.tokenKind)", leadingTrivia: "", trailingTrivia: "")

    token.leadingTrivia.forEach { (piece) in
      let trivia = processTriviaPiece(piece)
      list.append(trivia)
      current.token?.leadingTrivia += trivia.transformWhitespaces()
    }
    processToken(token)
    token.trailingTrivia.forEach { (piece) in
      let trivia = processTriviaPiece(piece)
      list.append(trivia)
      current.token?.trailingTrivia += trivia.transformWhitespaces()
    }

    return token
  }

  override func visitPost(_ node: Syntax) {
    if let token = node.as(TokenSyntax.self), token.presence == .missing, !showMissingTokens {
      return
    }

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

    let sourceRange = token.sourceRange(converter: locationConverter)
    let start = sourceRange.start
    let end = sourceRange.end
    let startRow = start.line ?? 1
    let startColumn = start.column ?? 1
    let endRow = end.line ?? 1
    let endColumn = end.column ?? 1
    let text = token.presence == .present || showMissingTokens ? token.text : ""
    list.append(
      "<span class='token \(kind.htmlEscaped()) \(token.presence.rawValue.lowercased())' " +
      "data-title='\("\(token.withoutTrivia())".htmlEscaped().displayInvisibles())' " +
      "data-content='\("\(token.tokenKind)".htmlEscaped().substituteInvisibles())' " +
      "data-type='Token' " +
      #"data-range='{"startRow":\#(startRow),"startColumn":\#(startColumn),"endRow":\#(endRow),"endColumn":\#(endColumn)}'>"# +
      "\(text.htmlEscaped().substituteInvisibles())</span>"
    )
  }

  private func processTriviaPiece(_ piece: TriviaPiece) -> String {
    func wrapWithSpanTag(class c: String, text: String) -> String {
      "<span class='\(c.htmlEscaped())' " +
      "data-title='\("\(piece)".htmlEscaped().displayInvisibles())' " +
      "data-content='\(c.htmlEscaped().substituteInvisibles())' " +
      "data-type='Trivia'>\(text.htmlEscaped().substituteInvisibles())</span>"
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
      trivia += String(repeating: "<br/>", count: count)
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
}

private extension String {
  func htmlEscaped() -> String {
    var string = self
    let specialCharacters = [
      ("&", "&amp;"),
      ("<", "&lt;"),
      (">", "&gt;"),
      ("\"", "&quot;"),
      ("'", "&apos;"),
    ];
    for (unescaped, escaped) in specialCharacters {
      string = string.replacingOccurrences(of: unescaped, with: escaped, options: .literal, range: nil)
    }
    return string
  }

  func substituteInvisibles() -> String {
    self
      .replacingOccurrences(of: " ", with: "&nbsp;")
      .replacingOccurrences(of: "\n", with: "<br/>")
  }

  func displayInvisibles() -> String {
    self
      .replacingOccurrences(of: " ", with: "␣")
      .replacingOccurrences(of: "\n", with: "↲")
  }

  func transformWhitespaces() -> String {
    self
      .replacingOccurrences(of: "&nbsp;", with: "␣")
      .replacingOccurrences(of: "<br/>", with: "↲<br/>")
  }
}
