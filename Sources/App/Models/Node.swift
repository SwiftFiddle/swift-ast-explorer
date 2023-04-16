import Foundation

final class Node: Encodable {
    var text: String
    var children = [Node]()
    weak var parent: Node?
    var range = Range(startRow: 0, startColumn: 0, endRow: 0, endColumn: 0)
    var structure = [String: StructureValue]()
    var token: Token?

    struct Range: Codable {
        var startRow: Int
        var startColumn: Int
        var endRow: Int
        var endColumn: Int
    }

    struct Token: Encodable {
        var kind: String
        var leadingTrivia: String
        var trailingTrivia: String
    }

    enum CodingKeys: CodingKey {
        case text
        case children
        case range
        case structure
        case token
    }

    init(text: String) {
        self.text = text
    }

    func add(node: Node) {
        node.parent = self
        children.append(node)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(children, forKey: .children)
        try container.encode(range, forKey: .range)
        try container.encode(structure, forKey: .structure)
        try container.encode(token, forKey: .token)
    }
}

class StructureValue: Encodable {
    let text: String
    let kind: String?

    init(text: String, kind: String? = nil) {
        self.text = text
        self.kind = kind
    }
}
