import Foundation
@_spi(RawSyntax) import SwiftSyntax

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

    let sourceRange = node.sourceRange(converter: converter)
    let start = sourceRange.start
    let end = sourceRange.end

    list.append(
      "<span class='\(className)' " +
      "data-title='\("\(escapeHTML("\(node.trimmed)"))".replacingOccurrences(of: "\n", with: "↲"))' " +
      "data-content='\(escapeHTML(content))' " +
      "data-type='\(escapeHTML(type))' " +
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
        endRow: end.line,
        endColumn: end.column
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

          switch syntaxNode[keyPath: keyPath] {
          case let value as TokenSyntax:
            if let tokenView = value.raw.tokenView, tokenView.presence == .missing {
              treeNode.structure.append(
                StructureProperty(
                  name: name,
                  value: StructureValue(
                    text: "MISSING",
                    kind: "\(value.tokenKind)"
                  )
                )
              )
            } else {
              treeNode.structure.append(
                StructureProperty(
                  name: name,
                  value: StructureValue(
                    text: "\(value)"
                      .replacingOccurrences(of: " ", with: "␣")
                      .replacingOccurrences(of: "\n", with: "↲"),
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
    current.text = escapeHTML(token.text)
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

    let sourceRange = token.sourceRange(converter: converter)
    let start = sourceRange.start
    let end = sourceRange.end
    let text = token.presence == .present ? token.text : ""
    list.append(
      "<span class='token \(escapeHTML(kind))' " +
      "data-title='\(escapeHTML("\(token.trimmed)"))' " +
      "data-content='\(escapeHTML("\(token.tokenKind)"))' " +
      "data-type='Token' " +
      #"data-range='{"startRow":\#(start.line),"startColumn":\#(start.column),"endRow":\#(end.line),"endColumn":\#(end.column)}'>"# +
      "\(escapeHTML(text))</span>"
    )
  }

  private func processTriviaPiece(_ piece: TriviaPiece) -> String {
    func wrapWithSpanTag(class c: String, text: String) -> String {
      "<span class='\(escapeHTML(c))' data-title='\(escapeHTML("\(piece)"))' data-content='\(escapeHTML(c))' data-type='Trivia'>\(escapeHTML(text))</span>"
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
    case .backslashes(let count):
      trivia += String(repeating: #"\"#, count: count)
    case .pounds(let count):
      trivia += String(repeating: "#", count: count)
    }
    return trivia
  }

  private func replaceSymbols(text: String) -> String {
    text.replacingOccurrences(of: "&nbsp;", with: "␣").replacingOccurrences(of: "<br>", with: "↲")
  }
}

func escapeHTML(_ string: String) -> String {
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
    .replacingOccurrences(of: " ", with: "&nbsp;")
    .replacingOccurrences(of: "\n", with: "<br>")
}
