import Source
import SourceKittenFramework

public typealias USR = String

public class BasicBlock {
  let range: SourceRange
  let type: BasicBlockType

  init(range: SourceRange, type: BasicBlockType) {
    self.range = range
    self.type = type
  }

  // If we are getting the CFG of a BasicBlock directly,
  // then we just want a wrapper that has this basic block as an entry point and moves on
  // TODO: Implement guard, break etc.
  func getCFG() -> CFG {
    return CFG(
      nodes: [self],
      edges: [self: [.passiveNext]],
      entryPoint: .basicBlock(self)
    )
  }

  /// Lists all the symbols that are defined in this block
  public func definitions() -> Set<USR> {
    guard self.type != .start else {
      return Set<USR>()
    }

    let filePath = range.start.identifier
    let startOffset = try! range.start.offset()
    let endOffset = try! range.end.offset()

    var references = Set<USR>()

    for offset in startOffset ..< endOffset {
      let cursorInfo: [String: SourceKitRepresentable] = Request.cursorInfo(
        file: filePath,
        offset: Int64(offset),
        arguments: [filePath]
      ).send()
      if let kind = cursorInfo["key.kind"] as? String,
        kind.contains("swift.decl"),
        let usr = cursorInfo["key.usr"] as? String {
          references.insert(usr)
      }
    }

    return references
  }

  /// Lists all the symbols that are referred to in this block
  public func references() -> Set<USR> {
    guard self.type != .start else {
      return Set<USR>()
    }

    let filePath = range.start.identifier
    let startOffset = try! range.start.offset()
    let endOffset = try! range.end.offset()

    var references = Set<USR>()

    for offset in startOffset ..< endOffset {
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
    return (lhs.range, lhs.type) == (rhs.range, rhs.type)
  }

  public var hashValue: Int {
    return range.hashValue ^ type.hashValue
  }
}

enum BasicBlockType {
  /// Synthesized start block for the CFG
  case start
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