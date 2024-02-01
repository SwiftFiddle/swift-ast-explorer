import Foundation
@_spi(RawSyntax) import SwiftSyntax

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
    super.init(viewMode: showMissingTokens ? .all : .sourceAccurate)
  }

  override func visitPre(_ node: Syntax) {
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
    if let tokenSyntax = node.as(TokenSyntax.self) {
      title = tokenSyntax.text
      content = "\(tokenSyntax.tokenKind)"
      type = "Token"
    } else {
      title = "\(node.trimmed)"
      content = "\(syntaxNodeType)"
      type = "Syntax"
    }

    let sourceRange = node.sourceRange(converter: locationConverter)
    let start = sourceRange.start
    let end = sourceRange.end

    let graphemeStartColumn: Int
    if let prefix = String(locationConverter.sourceLines[start.line - 1].utf8.prefix(start.column - 1)) {
      graphemeStartColumn = prefix.utf16.count + 1
    } else {
      graphemeStartColumn = start.column
    }
    let graphemeEndColumn: Int
    if let prefix = String(locationConverter.sourceLines[end.line - 1].utf8.prefix(end.column - 1)) {
      graphemeEndColumn = prefix.utf16.count + 1
    } else {
      graphemeEndColumn = end.column
    }

    list.append(
      "<span class='\(className)' " +
      "data-title='\(title.escapeHTML().replaceInvisiblesWithSymbols())' " +
      "data-content='\(content.escapeHTML().replaceInvisiblesWithHTML())' " +
      "data-type='\(type.escapeHTML())' " +
      #"data-range='{"startRow":\#(start.line),"startColumn":\#(start.column),"endRow":\#(end.line),"endColumn":\#(end.column)}'>"#
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
        startRow: start.line,
        startColumn: start.column,
        graphemeStartColumn: graphemeStartColumn,
        endRow: end.line,
        endColumn: end.column,
        graphemeEndColumn: graphemeEndColumn
      ),
      type: syntaxType
    )

    tree.append(treeNode)
    index += 1

    let allChildren = node.children(viewMode: .all)

    switch node.syntaxNodeType.structure {
    case .layout(let keyPaths):
      if let syntaxNode = node.as(node.syntaxNodeType) {
        for keyPath in keyPaths {
          guard let name = childName(keyPath) else {
            continue
          }
          guard allChildren.contains(where: { (child) in child.keyPathInParent == keyPath }) else {
            treeNode.structure.append(StructureProperty(name: name, value: StructureValue(text: "nil")))
            continue
          }

          let keyPath = keyPath as AnyKeyPath
          switch syntaxNode[keyPath: keyPath] {
          case let value as TokenSyntax:
            if value.presence == .missing {
              treeNode.structure.append(
                StructureProperty(
                  name: name,
                  value: StructureValue(
                    text: value.text,
                    kind: "\(value.tokenKind)"
                  )
                )
              )
            } else {
              treeNode.structure.append(
                StructureProperty(
                  name: name,
                  value: StructureValue(
                    text: value.text,
                    kind: "\(value.tokenKind)"
                  )
                )
              )            }
          case let value?:
            if let value = value as? SyntaxProtocol {
              let type = "\(value.syntaxNodeType)"
              treeNode.structure.append(StructureProperty(name: name, value: StructureValue(text: "\(type)"), ref: "\(type)"))
            } else {
              treeNode.structure.append(StructureProperty(name: name, value: StructureValue(text: "\(value)")))
            }
          case .none:
            treeNode.structure.append(StructureProperty(name: name))
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
    current.text = token
      .text
      .escapeHTML()
      .replaceInvisiblesWithHTML()
      .replaceHTMLWhitespacesWithSymbols()
    if token.presence == .missing {
      current.class = "\(token.presence)"
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
    let text = token.presence == .present || showMissingTokens ? token.text : ""
    list.append(
      "<span class='token \(kind.escapeHTML()) \(token.presence)' " +
      "data-title='\(token.text.escapeHTML().replaceInvisiblesWithSymbols())' " +
      "data-content='\("\(token.tokenKind)".escapeHTML().replaceInvisiblesWithHTML())' " +
      "data-type='Token' " +
      #"data-range='{"startRow":\#(start.line),"startColumn":\#(start.column),"endRow":\#(end.line),"endColumn":\#(end.column)}'>"# +
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
    case .backslashes(let count):
      trivia += String(repeating: #"\"#, count: count)
    case .pounds(let count):
      trivia += String(repeating: "#", count: count)
    }
    return trivia
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
