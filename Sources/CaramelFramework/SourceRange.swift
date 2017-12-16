public struct SourceRange {
  let fileName: String
  let range: ClosedRange<SourceFileLocation>
}

extension SourceRange: Equatable {
  public static func == (lhs: SourceRange, rhs: SourceRange) -> Bool {
    return (lhs.fileName, lhs.range) == (rhs.fileName, rhs.range)
  }
}

public struct SourceFileLocation: Equatable, Comparable {
  let line: Int
  let column: Int

  public static func == (lhs: SourceFileLocation, rhs: SourceFileLocation) -> Bool {
    return (lhs.line, lhs.column) == (rhs.line, rhs.column)
  }

  public static func < (lhs: SourceFileLocation, rhs: SourceFileLocation) -> Bool {
    return (lhs.line < rhs.line) ||
      (lhs.line == rhs.line && lhs.column < rhs.column)
  }
}