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

  func rewrite(_ node: Syntax) -> Syntax {
    visit(node)
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

    let title: String
    let content: String
    let type: String
    if let token = node.as(TokenSyntax.self) {
      title = sourceAccurateText(token)
      content = "\(token.tokenKind)"
      type = "Token"
    } else {
      title = sourceAccurateText(node)
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

    let graphemeStartColumn: Int
    if let prefix = String(locationConverter.sourceLines[startRow - 1].utf8.prefix(startColumn - 1)) {
      graphemeStartColumn = prefix.utf16.count + 1
    } else {
      graphemeStartColumn = startColumn
    }
    let graphemeEndColumn: Int
    if let prefix = String(locationConverter.sourceLines[endRow - 1].utf8.prefix(endColumn - 1)) {
      graphemeEndColumn = prefix.utf16.count + 1
    } else {
      graphemeEndColumn = endColumn
    }

    list.append(
      "<span class='\(className)' " +
      "data-title='\(title.escapeHTML().replaceInvisiblesWithSymbols())' " +
      "data-content='\(content.escapeHTML().replaceInvisiblesWithHTML())' " +
      "data-type='\(type.escapeHTML())' " +
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
        graphemeStartColumn: graphemeStartColumn,
        endRow: endRow,
        endColumn: endColumn,
        graphemeEndColumn: graphemeEndColumn
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
                    text: value.text,
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

    let text = sourceAccurateText(token)
    current.text = text
      .escapeHTML()
      .replaceInvisiblesWithHTML()
      .replaceHTMLWhitespacesWithSymbols()
    if token.presence == .missing {
      current.class = token.presence.rawValue.lowercased()
    }
    current.token = Token(kind: "\(token.tokenKind)", leadingTrivia: "", trailingTrivia: "")

    token.leadingTrivia.forEach { (piece) in
      let trivia = processTriviaPiece(piece)
      list.append(trivia)
      current.token?.leadingTrivia += trivia.replaceHTMLWhitespacesWithSymbols()
    }
    processToken(token)
    token.trailingTrivia.forEach { (piece) in
      let trivia = processTriviaPiece(piece)
      list.append(trivia)
      current.token?.trailingTrivia += trivia.replaceHTMLWhitespacesWithSymbols()
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
    let text: String
    switch token.presence {
    case .present:
      text = sourceAccurateText(token)
    case .missing:
      if showMissingTokens {
        text = sourceAccurateText(token)
      } else {
        text = ""
      }
    }

    list.append(
      "<span class='token \(kind.escapeHTML()) \(token.presence.rawValue.lowercased())' " +
      "data-title='\(token.text.escapeHTML().replaceInvisiblesWithSymbols())' " +
      "data-content='\("\(token.tokenKind)".escapeHTML().replaceInvisiblesWithHTML())' " +
      "data-type='Token' " +
      #"data-range='{"startRow":\#(startRow),"startColumn":\#(startColumn),"endRow":\#(endRow),"endColumn":\#(endColumn)}'>"# +
      "\(text.escapeHTML().replaceInvisiblesWithHTML())</span>"
    )
  }

  private func processTriviaPiece(_ piece: TriviaPiece) -> String {
    func wrapWithSpanTag(class c: String, text: String) -> String {
      "<span class='\(c.escapeHTML())' " +
      "data-title='\("\(piece)".escapeHTML().replaceInvisiblesWithSymbols())' " +
      "data-content='\(c.escapeHTML().replaceInvisiblesWithHTML())' " +
      "data-type='Trivia'>\(text.escapeHTML().replaceInvisiblesWithHTML())</span>"
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

private func sourceAccurateText(_ syntax: Syntax) -> String {
  let text = "\(syntax.withoutTrivia())"
  let utf8Length = syntax.contentLength.utf8Length
  if text.utf8.count == utf8Length {
    return text
  } else {
    return String(decoding: syntax.syntaxTextBytes.prefix(utf8Length), as: UTF8.self)
  }
}

private func sourceAccurateText(_ token: TokenSyntax) -> String {
  let text = token.text
  let utf8Length = token.contentLength.utf8Length
  if text.utf8.count == utf8Length {
    return text
  } else {
    return String(decoding: token.syntaxTextBytes.prefix(utf8Length), as: UTF8.self)
  }
}

private extension String {
  func escapeHTML() -> String {
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

  func replaceInvisiblesWithHTML() -> String {
    self
      .replacingOccurrences(of: " ", with: "&nbsp;")
      .replacingOccurrences(of: "\n", with: "<br/>")
  }

  func replaceInvisiblesWithSymbols() -> String {
    self
      .replacingOccurrences(of: " ", with: "␣")
      .replacingOccurrences(of: "\n", with: "↲")
  }

  func replaceHTMLWhitespacesWithSymbols() -> String {
    self
      .replacingOccurrences(of: "&nbsp;", with: "<span class='whitespace'>␣</span>")
      .replacingOccurrences(of: "<br/>", with: "<span class='newline'>↲</span><br/>")
  }
}
