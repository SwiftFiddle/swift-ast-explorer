import Vapor

struct SyntaxResponse: Content {
    let syntaxHTML: String
    let syntaxJSON: String
    let statistics: [SyntaxStatistics.Row]
    let swiftVersion: String
}

final class SyntaxStatistics: Content {
    private var rows = [String: Row]()
    var sorted: [Row] { rows.keys.sorted().compactMap { rows[$0] } }

    func append(node: Node) {
        if let row = rows[node.text] {
            row.nodes.append(node)
        } else {
            rows[node.text] = Row(syntax: node.text, node: node)
        }
    }

    final class Row: Content {
        let syntax: String
        var nodes = [Node]()

        enum CodingKeys: CodingKey {
            case syntax
            case ranges
        }

        init(syntax: String, node: Node) {
            self.syntax = syntax
            nodes.append(node)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            syntax = try container.decode(String.self, forKey: .syntax)
            let ranges = try container.decode([Node.Range].self, forKey: .ranges)
            nodes = ranges.map {
                let node = Node(text: syntax)
                node.range = $0
                return node
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(syntax, forKey: .syntax)
            try container.encode(nodes.map { $0.range }, forKey: .ranges)
        }
    }
}
