import Foundation

func lineDiff(_ expected: String, _ actual: String) -> String {
  let actualLines = actual.components(separatedBy: .newlines)
  let expectedLines = expected.components(separatedBy: .newlines)

  let difference = actualLines.difference(from: expectedLines)

  var result = ""

  var insertions = [Int: String]()
  var removals = [Int: String]()

  for change in difference {
    switch change {
    case .insert(let offset, let element, _):
      insertions[offset] = element
    case .remove(let offset, let element, _):
      removals[offset] = element
    }
  }

  var expectedLine = 0
  var actualLine = 0

  while expectedLine < expectedLines.count || actualLine < actualLines.count {
    if let removal = removals[expectedLine] {
      result += "–\(removal)\n"
      expectedLine += 1
    } else if let insertion = insertions[actualLine] {
      result += "+\(insertion)\n"
      actualLine += 1
    } else {
      result += " \(expectedLines[expectedLine])\n"
      expectedLine += 1
      actualLine += 1
    }
  }

  return result
}

func wordDiff(_ expected: String, _ actual: String) -> String {
  let difference = actual.difference(from: expected)
  var insertions = [Int: Character]()
  var removals = [Int: Character]()
  for change in difference {
    switch change {
    case .insert(let offset, let element, _):
      insertions[offset] = element
    case .remove(let offset, let element, _):
      removals[offset] = element
    }
  }

  var expectedColumn = 0
  var actualColumn = 0
  var insertion = ""
  var removal = ""
  var unchanged = ""

  var result = [WordDiff]()
  while expectedColumn < expected.count || actualColumn < actual.count {
    if let removalChar = removals[expectedColumn] {
      if !insertion.isEmpty {
        result.append(.insertion(insertion))
        insertion = ""
      }
      if !unchanged.isEmpty {
        result.append(.unchanged(unchanged))
        unchanged = ""
      }

      removal.append(removalChar)
      expectedColumn += 1
    } else if let insertionChar = insertions[actualColumn] {
      if !removal.isEmpty {
        result.append(.removal(removal))
        removal = ""
      }
      if !unchanged.isEmpty {
        result.append(.unchanged(unchanged))
        unchanged = ""
      }

      insertion.append(insertionChar)
      actualColumn += 1
    } else {
      if !insertion.isEmpty {
        result.append(.insertion(insertion))
        insertion = ""
      }
      if !removal.isEmpty {
        result.append(.removal(removal))
        removal = ""
      }

      unchanged.append(expected[expected.index(expected.startIndex, offsetBy: expectedColumn)])
      expectedColumn += 1
      actualColumn += 1
    }
  }
  if !insertion.isEmpty {
    result.append(.insertion(insertion))
    insertion = ""
  }
  if !removal.isEmpty {
    result.append(.removal(removal))
    removal = ""
  }
  if !unchanged.isEmpty {
    result.append(.unchanged(unchanged))
    unchanged = ""
  }

  return result.map { "\($0)" }.joined()
}

private enum WordDiff: CustomStringConvertible {
  case insertion(String)
  case removal(String)
  case unchanged(String)

  var description: String {
    switch self {
    case .removal(let removal):
      return "[-\(removal)-]"
    case .insertion(let insertion):
      return "{+\(insertion)+}"
    case .unchanged(let unchanged):
      return unchanged
    }
  }
}
