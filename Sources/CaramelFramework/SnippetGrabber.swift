import Source

/// A utility for efficiently grabbing substrings from files
public struct SnippetGrabber {
  public enum Error: Swift.Error {
    case invalidOffset
  }

  /// Map paths to string file contents
  private static var memo: [String: String] = [:]

  public static func get(filePath: String, startOffset: Int, endOffset: Int) throws -> Substring {
    let content = try memo[filePath] ?? { 
      let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
      memo[filePath] = fileContents
      return fileContents
    }()

    guard startOffset <= content.count && endOffset <= content.count else {
      throw Error.invalidOffset
    }

    let startIndex = content.index(content.startIndex, offsetBy: startOffset)
    let endIndex = content.index(content.startIndex, offsetBy: endOffset)

    return content[startIndex ..< endIndex]
  }
}