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
    self.text = escapeHTML(text)
    self.range = range
    self.type = type
  }
}

extension TreeNode: Equatable {
  static func == (lhs: TreeNode, rhs: TreeNode) -> Bool {
    lhs.id == rhs.id &&
    lhs.parent == rhs.parent &&
    lhs.text == rhs.text &&
    lhs.range == rhs.range &&
    lhs.structure == rhs.structure &&
    lhs.type == rhs.type &&
    lhs.token == rhs.token
  }
}

extension TreeNode: CustomStringConvertible {
  var description: String {
    """
    {
      id: \(id)
      parent: \(String(describing: parent))
      text: \(text)
      range: \(range)
      structure: \(structure)
      type: \(type)
      token: \(String(describing: token))
    }
    """
  }
}

struct Range: Codable, Equatable {
  var startRow: Int
  var startColumn: Int
  var endRow: Int
  var endColumn: Int
}

extension Range: CustomStringConvertible {
  var description: String {
    """
    {
      startRow: \(startRow)
      startColumn: \(startColumn)
      endRow: \(endRow)
      endColumn: \(endColumn)
    }
    """
  }
}

struct StructureProperty: Codable, Equatable {
  let name: String
  let value: StructureValue?
  let ref: String?

  init(name: String, value: StructureValue? = nil, ref: String? = nil) {
    self.name = escapeHTML(name)
    self.value = value
    if let ref {
      self.ref = escapeHTML(ref)
    } else {
      self.ref = nil
    }
  }
}

extension StructureProperty: CustomStringConvertible {
  var description: String {
    """
    {
      name: \(name)
      value: \(String(describing: value))
      ref: \(String(describing: ref))
    }
    """
  }
}

struct StructureValue: Codable, Equatable {
  let text: String
  let kind: String?

  init(text: String, kind: String? = nil) {
    self.text = escapeHTML(text)
    if let kind {
      self.kind = escapeHTML(kind)
    } else {
      self.kind = nil
    }
  }
}

extension StructureValue: CustomStringConvertible {
  var description: String {
    """
    {
      text: \(text)
      kind: \(String(describing: kind))
    }
    """
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

struct Token: Codable, Equatable {
  var kind: String
  var leadingTrivia: String
  var trailingTrivia: String

  init(kind: String, leadingTrivia: String, trailingTrivia: String) {
    self.kind = escapeHTML(kind)
    self.leadingTrivia = leadingTrivia
    self.trailingTrivia = trailingTrivia
  }
}

extension Token: CustomStringConvertible {
  var description: String {
    """
    {
      kind: \(kind)
      leadingTrivia: \(leadingTrivia)
      trailingTrivia: \(trailingTrivia)
    }
    """
  }
}
