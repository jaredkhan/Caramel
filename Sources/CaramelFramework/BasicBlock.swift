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
  lazy var definitions: Set<USR> = {
    guard self.type != .start && self.type != .end else {
      return Set<USR>()
    }

    let definitions = defRange.map { try! IdentifierIndex.references(inFile: range.start.identifier, within: $0) } ?? []
    let declarations = try! IdentifierIndex.declarations(inFile: range.start.identifier, within: range)
    return definitions.union(declarations)
  }()

  /// Lists all the symbols that are referred to in this block
  lazy var references: Set<USR> = {
     guard self.type != .start && self.type != .end else {
      return Set<USR>()
    }

    return try! IdentifierIndex.references(inFile: range.start.identifier, within: range, excludingRange: defRange)
  }()
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
