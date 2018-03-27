import SourceKittenFramework
import Source

struct IdentifierIndex {

  enum Error: Swift.Error {
    case invalidFilePath(String)
  }

  let filePath: String
  let referenceIndex: [(offset: Int, usr: USR)]
  let declarationIndex: [(offset: Int, usr: USR)]

  public init(filePath: String) throws {
    guard let file = File(path: filePath) else {
      throw Error.invalidFilePath(filePath)
    }
    self.filePath = filePath

    print("Making SK call")
    let syntaxMap = SyntaxMap(file: file)
    let identifierOffsets = syntaxMap.tokens.filter {
      $0.type == SyntaxKind.identifier.rawValue
    }.map {
      $0.offset
    }.sorted()

    var referenceIndex: [(offset: Int, usr: USR)] = []
    var declarationIndex: [(offset: Int, usr: USR)] = []

    for identifierOffset in identifierOffsets {
      print("Making SK call")
      let cursorInfo: [String: SourceKitRepresentable] = Request.cursorInfo(
        file: filePath,
        offset: Int64(identifierOffset),
        arguments: [filePath]
      ).send()
      if let kind = cursorInfo["key.kind"] as? String,
        let usr = cursorInfo["key.usr"] as? String {
        if kind.contains("swift.ref") {
          referenceIndex.append((offset: identifierOffset, usr: usr))
        } else if kind.contains("swift.decl") {
          declarationIndex.append((offset: identifierOffset, usr: usr))
        }
      }
    }

    self.referenceIndex = referenceIndex
    self.declarationIndex = declarationIndex
  }

  public func references(within offsetRange: Range<Int>, excludingRange rangeToExclude: Range<Int>? = nil) -> Set<USR> {
    func isWithinRange(_ offset: Int) -> Bool {
      guard offsetRange ~= offset else { return false }
      if let rangeToExclude = rangeToExclude {
        return !(rangeToExclude ~= offset)
      } else {
        return true
      }
    }
    if let startIndex = referenceIndex.index(where: { isWithinRange($0.offset) }) {
      var index = startIndex
      var results = Set<USR>()
      while offsetRange ~= referenceIndex[index].offset {
        if isWithinRange(referenceIndex[index].offset) {
          results.insert(referenceIndex[index].usr)
        }
        index = index + 1
        guard index < referenceIndex.count else {
          break
        }
      }
      return results
    } else {
      return []
    }
  }

  public func references(within range: SourceRange, excludingRange rangeToExclude: SourceRange? = nil) throws -> Set<USR> {
    let offsetRange: Range<Int> = (try range.start.offset()) ..< (try range.end.offset())
    let offsetRangeToExclude: Range<Int>? = try rangeToExclude.map { (try $0.start.offset()) ..< (try $0.end.offset()) }
    return references(within: offsetRange, excludingRange: offsetRangeToExclude)
  }

  public func declarations(within offsetRange: Range<Int>) -> Set<USR> {
    if let startIndex = declarationIndex.index(where: { offsetRange ~= $0.offset }) {
      var index = startIndex
      var results = Set<USR>()
      while offsetRange ~= declarationIndex[index].offset {
        results.insert(declarationIndex[index].usr)
        index = index + 1
        guard index < declarationIndex.count else {
          break
        }
      }
      return results
    } else {
      return []
    }
  }

  public func declarations(within range: SourceRange) throws -> Set<USR> {
    let offsetRange: Range<Int> = (try range.start.offset()) ..< (try range.end.offset())
    return declarations(within: offsetRange)
  }

  /// MARK: Convenience Static API

  private static var indexCache: [String: IdentifierIndex] = [:]

  private static func index(forPath filePath: String) -> IdentifierIndex {
    if let index = indexCache[filePath] {
      return index
    } else {
      let index = try! IdentifierIndex(filePath: filePath)
      indexCache[filePath] = index
      return index
    }
  }

  public static func references(inFile filePath: String, within offsetRange: Range<Int>, excludingRange rangeToExclude: Range<Int>? = nil) -> Set<USR> {
    return index(forPath: filePath).references(within: offsetRange, excludingRange: rangeToExclude)
  }
  public static func references(inFile filePath: String, within range: SourceRange, excludingRange rangeToExclude: SourceRange? = nil) throws -> Set<USR> {
    return try index(forPath: filePath).references(within: range, excludingRange: rangeToExclude)
  }
  public static func declarations(inFile filePath: String, within offsetRange: Range<Int>) -> Set<USR> {
    return index(forPath: filePath).declarations(within: offsetRange)
  }
  public static func declarations(inFile filePath: String, within range: SourceRange) throws -> Set<USR> {
    return try index(forPath: filePath).declarations(within: range)
  }
}
