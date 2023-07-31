import Foundation

@main
struct Main {
  static func main() throws {
    do {
      let arguments = CommandLine.arguments
      let code = CommandLine.arguments[1]
      let options: [String]
      if arguments.count > 2 {
        options = Array(CommandLine.arguments.dropFirst(2))
      } else {
        options = []
      }

      let response = try SyntaxParser.parse(code: code, options: options)

      let data = try JSONEncoder().encode(response)
      print(String(decoding: data, as: UTF8.self))
    } catch {
      print("\(error)", to:&standardError)
    }
  }
}

var standardError = FileHandle.standardError

extension FileHandle : TextOutputStream {
  public func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    self.write(data)
  }
}
