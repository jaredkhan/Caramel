import Source
import SourceKittenFramework
import AST

public typealias USR = String

public class BasicBlock {
  public let range: SourceRange
  public let type: BasicBlockType
  // A range within this block of symbols being defined (e.g. on the left hand side of an assignment operator)
  let defRange: SourceRange?

  init(range: SourceRange, type: BasicBlockType, defRange: SourceRange? = nil) {
    self.range = range
    self.type = type
    self.defRange = defRange
  }

  // If we are getting the PartialCFG of a BasicBlock directly,
  // then we just want a wrapper that has this basic block as an entry point and moves on
  // TODO: Implement guard, break etc.
  func getCFG() -> PartialCFG {
    return PartialCFG(
      nodes: [self],
      edges: [self: [.passiveNext]],
      entryPoint: .basicBlock(self)
    )
  }

  /// Lists all the symbols that are defined in this block
  public func definitions() -> Set<USR> {
    guard self.type != .start && self.type != .end else {
      return Set<USR>()
    }

    let filePath = range.start.identifier
    let startOffset = try! range.start.offset()
    let endOffset = try! range.end.offset()

    var definitions = Set<USR>()

    for offset in startOffset ..< endOffset {
      let cursorInfo: [String: SourceKitRepresentable] = Request.cursorInfo(
        file: filePath,
        offset: Int64(offset),
        arguments: [filePath]
      ).send()
      if let kind = cursorInfo["key.kind"] as? String,
        kind.contains("swift.decl"),
        let usr = cursorInfo["key.usr"] as? String {
          definitions.insert(usr)
      }
    }

    // Add the references e.g on the left hand side of assignment expressions
    if let defOffsetRange = defRange.map({ (try! $0.start.offset()) ..< (try! $0.end.offset()) }) {
      for offset in defOffsetRange {
        let cursorInfo: [String: SourceKitRepresentable] = Request.cursorInfo(
          file: filePath,
          offset: Int64(offset),
          arguments: [filePath]
        ).send()
        if let kind = cursorInfo["key.kind"] as? String,
          kind.contains("swift.ref"),
          let usr = cursorInfo["key.usr"] as? String {
            definitions.insert(usr)
        }
      }
    }

    return definitions
  }

  /// Lists all the symbols that are referred to in this block
  public func references() -> Set<USR> {
     guard self.type != .start && self.type != .end else {
      return Set<USR>()
    }

    let filePath = range.start.identifier
    let startOffset = try! range.start.offset()
    let endOffset = try! range.end.offset()

    var references = Set<USR>()

    let defOffsetRange = defRange.map {
      (try! $0.start.offset()) ..< (try! $0.end.offset())
    }

    for offset in startOffset ..< endOffset {
      if let defOffsetRange = defOffsetRange, defOffsetRange ~= offset {
        // This offset is in a spot which is being defined (rather than referenced)
        continue
      }

      let cursorInfo: [String: SourceKitRepresentable] = Request.cursorInfo(
        file: filePath,
        offset: Int64(offset),
        arguments: [filePath]
      ).send()
      if let kind = cursorInfo["key.kind"] as? String,
        kind.contains("swift.ref"),
        let usr = cursorInfo["key.usr"] as? String {
          references.insert(usr)
      }
    }

    return references
  }

  public func getCursorInfo(filePath: String, offset: Int64) -> [String: SourceKitRepresentable] {
  let req = Request.cursorInfo(file: filePath, offset: offset, arguments: [filePath])
  print(req.description)
  return req.send()
}

public func getRefUSR(filePath: String, offset: Int64) -> String? {
  let cursorInfo = getCursorInfo(filePath: filePath, offset: offset)
  let usr = cursorInfo["key.usr"] as? String
  return usr
}
}

extension BasicBlock: Hashable {
  public static func == (lhs: BasicBlock, rhs: BasicBlock) -> Bool {
    return (lhs.range, lhs.type) == (rhs.range, rhs.type) && lhs.defRange == rhs.defRange
  }

  public var hashValue: Int {
    return range.hashValue ^ type.hashValue
  }
}

public enum BasicBlockType {
  /// Synthesized start block for the CFG
  case start
  /// Synthesized end block for the CFG
  case end
  case condition
  case breakStatement
  case continueStatement
  case fallthroughStatement
  case pattern
  case repeatWhileCondition
  case functionParameter
  case functionReturnStatement
  case throwStatement
  case expression
}
