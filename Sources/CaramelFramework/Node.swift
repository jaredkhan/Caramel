import Source
import SourceKittenFramework
import AST

public typealias USR = String

public class Node {
  public let range: SourceRange
  public let type: NodeType
  // A range, within this node, of symbols being defined (e.g. on the left hand side of an assignment operator)
  let defRange: SourceRange?
  // Whether the items in the def range are also referenced (e.g. "x += 4" where x is both referenced and defined)
  let defRangeContainsRefs: Bool

  var artificialDefinitions: Set<USR> = []
  var artificialReferences: Set<USR> = []

  init(range: SourceRange, type: NodeType, defRange: SourceRange? = nil, defRangeContainsRefs: Bool = false) {
    self.range = range
    self.type = type
    self.defRange = defRange
    self.defRangeContainsRefs = defRangeContainsRefs
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
    return definitions.union(declarations).union(artificialDefinitions)
  }()

  /// Lists all the symbols that are referred to in this node
  lazy var references: Set<USR> = {
     guard self.type != .start && self.type != .end else {
      return Set<USR>()
    }

    return try! IdentifierIndex.references(
      inFile: range.start.identifier,
      within: range,
      excludingRange: defRangeContainsRefs ? nil : defRange
    ).union(artificialReferences)
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
  case returnStatement
  case functionSignature
  case declaration
  case pattern
  case repeatWhileCondition
  case functionParameter
  case functionReturnStatement
  case throwStatement
  case expression
}
