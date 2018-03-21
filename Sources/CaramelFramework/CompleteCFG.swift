import AST
import Parser
import Sema
import Source

/// Represents the Control Flow Graph of a complete, well-formed program
public class CompleteCFG: Equatable {
  public let nodes: Set<BasicBlock>
  public let edges: [BasicBlock: Set<BasicBlock>]
  public let reverseEdges: [BasicBlock: Set<BasicBlock>]
  public let start: BasicBlock
  public let end: BasicBlock

  public init(
    nodes: Set<BasicBlock>,
    edges: [BasicBlock: Set<BasicBlock>],
    reverseEdges: [BasicBlock: Set<BasicBlock>],
    start: BasicBlock,
    end: BasicBlock
  ) {
    self.nodes = nodes
    self.edges = edges
    self.reverseEdges = reverseEdges
    self.start = start
    self.end = end
  }

  /// Initialise a CompleteCFG from a partial CFG
  /// Complexity: O(E) time
  public init(cfg: CFG) throws {
    self.start = BasicBlock(
      range: SourceRange.EMPTY,
      type: .start
    )

    self.end = BasicBlock(
      range: SourceRange.EMPTY,
      type: .end
    )

    self.nodes = cfg.nodes.union([start, end])

    var edges = [BasicBlock: Set<BasicBlock>]()
    var reverseEdges = [BasicBlock: Set<BasicBlock>]()

    for node in self.nodes {
      edges[node] = []
      reverseEdges[node] = []
    }

    if case .basicBlock(let node) = cfg.entryPoint {
      edges[self.start]!.insert(node)
      reverseEdges[node]!.insert(self.start)
    }
    
    for source in cfg.nodes {
      var nextBlocks = cfg.edges[source] ?? []
      if nextBlocks.isEmpty { nextBlocks.insert(.passiveNext) } // Hack, make every node flow to the end node
      for nextBlock in nextBlocks {
        switch nextBlock {
          case .basicBlock(let destination):
            edges[source]!.insert(destination)
            reverseEdges[destination]!.insert(source)
          case .passiveNext:
            edges[source]!.insert(self.end)
            reverseEdges[self.end]!.insert(source)
          default:
            print("UNRESOLVED EDGE:")
            dump(nextBlock)
            throw Error.unresolvedEdge
        }
      }
    }

    self.edges = edges
    self.reverseEdges = reverseEdges
  }

  public enum Error: Swift.Error {
    /// All nodes except the end node should have at least 1 outgoing edge
    case noOutgoingEdge
    /// All edges should point directly to a BasicBlock
    case unresolvedEdge
  }

  private static func edgesMatch(_ lhs: CompleteCFG, _ rhs: CompleteCFG) -> Bool {
    
    if lhs.edges.count != rhs.edges.count { return false }
    for key in lhs.edges.keys {
      if lhs.edges[key] != rhs.edges[key] { return false }
    }
    
    if lhs.reverseEdges.count != rhs.reverseEdges.count { return false }
    for key in lhs.reverseEdges.keys {
      if lhs.reverseEdges[key] != rhs.reverseEdges[key] { return false }
    }
    return true
  }

  public static func ==(lhs: CompleteCFG, rhs: CompleteCFG) -> Bool {
    return lhs.nodes == rhs.nodes && edgesMatch(lhs, rhs) && lhs.start == rhs.start && lhs.end == rhs.end
  }
}
