import AST
import Parser
import Sema
import Source

/// Partial Control Flow Graph
/// Nodes are basic blocks. Edges are directed and point to possible next blocks
/// This graph is 'partial' in the sense that it does not contain the start and end blocks
/// and may have unresolved edges.
public struct PartialCFG: Equatable {
  public let nodes: Set<BasicBlock>
  public var edges: [BasicBlock: Set<NextBlock>]
  public var entryPoint: NextBlock

  // Resolve NextBlocks to other NextBlocks
  // e.g. resolving a .passiveNext to a basicBlock
  // e.g. resolving a .breakStatement to a .passiveNext
  mutating func apply(context: [NextBlock: NextBlock?]) {
    edges = edges.mapValues { nextBlocks in
      Set(
        nextBlocks.flatMap { nextBlock in
          context[nextBlock] ?? nextBlock
        }
      )
    }
    entryPoint = (context[entryPoint] ?? entryPoint) ?? entryPoint
  }

  // Return another PartialCFG with NextBlocks resolved to other NextBlocks
  // e.g. resolving a .passiveNext to a basicBlock
  // e.g. resolving a .breakStatement to a .passiveNext
  func applying(context: [NextBlock: NextBlock?]) -> PartialCFG {
    var result = self
    result.apply(context: context)
    return result
  }

  /// Pulls in all the nodes and edges of the given CFGs
  /// Useful for combining subgraphs into a larger graph
  /// Resulting entry point is the entry point of self
  func merging(with otherCFGs: PartialCFG...) -> PartialCFG {
    return self.merging(with: otherCFGs)
  }

  /// Pulls in all the nodes and edges of the given CFGs
  /// Useful for combining subgraphs into a larger graph
  /// Resulting entry point is the entry point of self
  func merging(with otherCFGs: [PartialCFG]) -> PartialCFG {
    let mergedNodes = otherCFGs.reduce(self.nodes, { $0.union($1.nodes) })
    let mergedEdges = otherCFGs.reduce(self.edges, { $0.merging($1.edges, uniquingKeysWith: { $0.union($1) }) })
    return PartialCFG(
      nodes: mergedNodes,
      edges: mergedEdges,
      entryPoint: entryPoint
    )
  }

  /// An empty partial CFG with no nodes and no edges
  public static let empty = PartialCFG(
    nodes: [],
    edges: [:],
    entryPoint: .passiveNext
  )

  /// Returns a Boolean value that indicates whether a CFGs set of edges is equal to
  /// another CFGs set of edges
  public static func edgesMatch(_ lhs: PartialCFG, _ rhs: PartialCFG) -> Bool {
    if lhs.edges.count != rhs.edges.count { return false }
    for key in lhs.edges.keys {
      if lhs.edges[key] != rhs.edges[key] { return false }
    }
    return true
  }

  public static func ==(lhs: PartialCFG, rhs: PartialCFG) -> Bool {
    return lhs.nodes == rhs.nodes && edgesMatch(lhs, rhs) && lhs.entryPoint == rhs.entryPoint
  }
}

// MARK: Initialisers

public extension PartialCFG {
  public init(contentsOfFile filePath: String) {
    let parser = Parser(source: try! SourceReader.read(at: filePath))
    let topLevelDecl = try! parser.parse()

    // Nested expressions need to be folded explicitly
    let seqExprFolding = SequenceExpressionFolding()
    seqExprFolding.fold([topLevelDecl])

    self = getCFG(topLevelDecl)
  }

  /// Takes an array of PartialCFGs and chains them together using the given context function
  /// Context takes a pair (cfg, nextCFG) and returns the context to apply to the cfg to chain it to nextCFG
  /// Example:
  /// PartialCFG(chainingCFGs: [myCFG1, myCFG2], withContext: { [.passiveNext: $1?.entryPoint ?? .passiveNext] })
  /// This will connect the 'passiveNext' pointers of each CFG to the entry points of the next CFG in the chain
  init(chainingCFGs cfgs: [PartialCFG], withContext context: ((PartialCFG, PartialCFG?) -> [NextBlock: NextBlock?])) {
    var cfgList: [PartialCFG] = []

    for cfg in cfgs.reversed() {
      cfgList.append(cfg.applying(context: context(cfg, cfgList.last)))
    }

    // At this point we have added the CFGs, in reverse, to cfgList
    cfgList.reverse()
    let partialCFG = PartialCFG(
      nodes: [],
      edges: [:],
      // Default entry point to just a passiveNext
      // so that empty CFGs can be chained without problems
      entryPoint: cfgList.first?.entryPoint ?? .passiveNext
    )
    self = partialCFG.merging(with: cfgList)
  }
}
