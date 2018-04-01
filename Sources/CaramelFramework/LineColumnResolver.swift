/// A utility for resolving lines and columns of files into byte offsets
public struct LineColumnResolver {
  /// Represents a line in a file
  public struct Line: Equatable {
    /// Byte offset of the start of the line (the character after the previous newline)
    let offset: Int
    /// The length of the line in bytes up to and including the newline character
    let length: Int
  }

  /// Maps line numbers to Lines
  public let lines: [Int: Line]

  public enum Error: Swift.Error {
    case locationOutOfRange
  }

  // MARK: Initialisation and indexing

  public init(filePath: String) throws {
    let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)

    var nextLineNumber = 1
    var lines: [Int: Line] = [:]
    var pointer = fileContents.startIndex

    while (true) {
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

  // MARK: Resolution of lines and columns

  /// Takes a line and column number and returns a byte offset to that position
  /// Throws if the position does not exist in the file
  public func resolve(line lineNum: Int, column columnNum: Int) throws -> Int {
    if let line = lines[lineNum] {
      if 0 < columnNum && columnNum <= line.length {
        return line.offset + columnNum - 1
      }
    }

    throw Error.locationOutOfRange
  }

  // MARK: Convenience Static API 
  // This section adds a way to resolve lines without explicitly instantiating a resolver

  private static var indexCache: [String: LineColumnResolver] = [:]

  /// Resolve a line and column of a given file to a byte offset
  /// Runtime O(filesize)
  /// File line locations are cached so subsequent calls on the same file are O(1)
  /// This cache assumes files are not changing during the runtime of the program
  public static func resolve(line: Int, column: Int, filePath: String) throws -> Int {
    let resolver: LineColumnResolver
    if let cachedResolver = indexCache[filePath] {
      resolver = cachedResolver
    } else {
      resolver = try LineColumnResolver(filePath: filePath)
      indexCache[filePath] = resolver
    }

    return try resolver.resolve(line: line, column: column)
  }
}
