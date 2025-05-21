import Foundation

@main
struct Main {
  static func main() throws {
    do {
      let code = String(decoding: FileHandle.standardInput.availableData, as: UTF8.self)
      let options = Array(CommandLine.arguments.dropFirst(1))

      let response = try SyntaxParser.parse(code: code, options: options)

      let data = try JSONEncoder().encode(response)
      print(String(decoding: data, as: UTF8.self))
    } catch {
      var standardError = FileHandle.standardError
      print("\(error)", to:&standardError)
    }
  }
}

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ string: String) {
    self.write(Data(string.utf8))
  }
}
