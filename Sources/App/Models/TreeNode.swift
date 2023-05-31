import Foundation

final class TreeNode: Codable {
  var id: Int
  var parent: Int?
  
  var text: String
  var range = Range(startRow: 0, startColumn: 0, endRow: 0, endColumn: 0)
  var structure = [StructureProperty]()
  var type: SyntaxType
  var token: Token?

  init(id: Int, text: String, range: Range, type: SyntaxType) {
    self.id = id
    self.text = text
    self.range = range
    self.type = type
  }
}

struct Range: Codable {
  var startRow: Int
  var startColumn: Int
  var endRow: Int
  var endColumn: Int
}

struct StructureProperty: Codable {
  let name: String
  let value: StructureValue?
  let ref: String?

  init(name: String, value: StructureValue? = nil, ref: String? = nil) {
    self.name = name
    self.value = value
    self.ref = ref
  }
}

struct StructureValue: Codable {
  let text: String
  let kind: String?

  init(text: String, kind: String? = nil) {
    self.text = text
    self.kind = kind
  }
}

enum SyntaxType: String, Codable {
  case decl
  case expr
  case pattern
  case type
  case collection
  case other
}

struct Token: Codable {
  var kind: String
  var leadingTrivia: String
  var trailingTrivia: String
}
