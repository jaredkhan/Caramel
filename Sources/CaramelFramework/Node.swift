import Source
import SourceKittenFramework
import AST

public typealias USR = String

public class Node {
  public let range: SourceRange
  public let type: NodeType
  // A range, within this node, of symbols being defined (e.g. on the left hand side of an assignment operator)
  let defRange: SourceRange?

  init(range: SourceRange, type: NodeType, defRange: SourceRange? = nil) {
    self.range = range
    self.type = type
    self.defRange = defRange
  }

  // If we are getting the PartialCFG of a Node directly,
  // then we just want a wrapper that has this node as an entry point and moves on
  // TODO: Implement guard, break etc.
  func getCFG() -> PartialCFG {
    return PartialCFG(
      nodes: [self],
      edges: [self: [.passiveNext]],
      entryPoint: .node(self)
    )
  }

  /// Lists all the symbols that are defined in this node
  lazy var definitions: Set<USR> = {
    guard self.type != .start && self.type != .end else {
      return Set<USR>()
    }

    let definitions = defRange.map { try! IdentifierIndex.references(inFile: range.start.identifier, within: $0) } ?? []
    let declarations = try! IdentifierIndex.declarations(inFile: range.start.identifier, within: range)
    return definitions.union(declarations)
  }()

  /// Lists all the symbols that are referred to in this node
  lazy var references: Set<USR> = {
     guard self.type != .start && self.type != .end else {
      return Set<USR>()
    }

    return try! IdentifierIndex.references(inFile: range.start.identifier, within: range, excludingRange: defRange)
  }()
}

extension Node: Hashable {
  public static func == (lhs: Node, rhs: Node) -> Bool {
    return (lhs.range, lhs.type) == (rhs.range, rhs.type) && lhs.defRange == rhs.defRange
  }

  public var hashValue: Int {
    return range.hashValue ^ type.hashValue
  }
}

public enum NodeType: Equatable {
  /// Synthesized start node for the CFG
  case start
  /// Synthesized end node for the CFG
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
