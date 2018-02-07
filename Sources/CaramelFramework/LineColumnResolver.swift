public struct LineColumnResolver {
  public enum Error: Swift.Error {
    case locationOutOfRange
  }

  public struct Line: Equatable {
    /// Byte offset of the start of the line (the character after the previous newline)
    let offset: Int
    /// The length of the line in bytes up to and including the newline character
    let length: Int

    public static func ==(lhs: Line, rhs: Line) -> Bool {
      return (lhs.offset, lhs.length) == (rhs.offset, rhs.length)
    }
  }

  /// Maps line numbers to Lines
  public let lines: [Int: Line]

  public init(filePath: String) throws {
    let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)

    var nextLineNumber = 1
    var lines: [Int: Line] = [:]

    var pointer = fileContents.startIndex
    // As long as there are characters left in the buffer, add another line up to and including the next newline character

    while (true) {
      // Find the index of the next newline
      if let nextNewLineIndex = fileContents[pointer ..< fileContents.endIndex].index(of: "\n") {
        let nextPointer = fileContents.index(nextNewLineIndex, offsetBy: 1)
        lines[nextLineNumber] = Line(
          offset: pointer.encodedOffset,
          length: nextPointer.encodedOffset - pointer.encodedOffset
        )
        pointer = nextPointer
        nextLineNumber += 1
      } else {
        lines[nextLineNumber] = Line(
          offset: pointer.encodedOffset,
          length: fileContents.endIndex.encodedOffset - pointer.encodedOffset
        )
        break
      }

    }

    self.lines = lines
  }

  public func resolve(line lineNum: Int, column columnNum: Int) throws -> Int {
    if let line = lines[lineNum] {
      if 0 < columnNum && columnNum <= line.length {
        return line.offset + columnNum - 1
      }
    }

    throw Error.locationOutOfRange
  }
}
