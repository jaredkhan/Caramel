/// Control Flow Graph
// Nodes are basic blocks
// Edges are directed and point to possible next blocks
public struct CFG {
  let nodes: Set<BasicBlock>
  var edges: [BasicBlock: [NextBlock]]
  var entryPoint: NextBlock

  // Resolve NextBlocks to other NextBlocks
  // e.g. resolving a .passiveNext to a basicBlock
  // e.g. resolving a .breakStatement to a .passiveNext
  mutating func apply(context: [NextBlock: NextBlock?]) {
    edges = edges.mapValues { nextBlocks in
      nextBlocks.flatMap { nextBlock in
        context[nextBlock] ?? nextBlock
      }
    }
    entryPoint = (context[entryPoint] ?? entryPoint) ?? entryPoint
  }

  func applying(context: [NextBlock: NextBlock?]) -> CFG {
    var result = self
    result.apply(context: context)
    return result
  }

  /// Pulls in all the nodes and edges of the given CFGs
  /// Useful for combining subgraphs into a larger graph
  func merging(with otherCFGs: CFG...) -> CFG {
    return self.merging(with: otherCFGs)
  }

  func merging(with otherCFGs: [CFG]) -> CFG {
    let mergedNodes = otherCFGs.reduce(self.nodes, { $0.union($1.nodes) })
    let mergedEdges = otherCFGs.reduce(self.edges, { $0.merging($1.edges, uniquingKeysWith: +) })
    return CFG(
      nodes: mergedNodes,
      edges: mergedEdges,
      entryPoint: entryPoint
    )
  }
}

enum NextBlock {
  case basicBlock(BasicBlock)

  // Next block types that need to be resolved to basic blocks
  case passiveNext
  case switchFallthrough
  case breakStatement
  case labelledBreakStatement(String)
  case continueStatement
  case labelledContinueStatement(String)
  case returnStatement
  case throwStatement
  case nextCase
}

extension NextBlock: Hashable {
  public static func == (lhs: NextBlock, rhs: NextBlock) -> Bool {
    switch (lhs, rhs) {
      case (.basicBlock(let lBlock), .basicBlock(let rBlock)): return lBlock == rBlock
      case (.passiveNext, .passiveNext): return true
      case (.switchFallthrough, .switchFallthrough): return true
      case (.breakStatement, .breakStatement): return true
      case (.labelledBreakStatement(let llabel), .labelledBreakStatement(let rlabel)): return llabel == rlabel
      case (.continueStatement, .continueStatement): return true
      case (.labelledContinueStatement(let llabel), .labelledContinueStatement(let rlabel)): return llabel == rlabel
      case (.returnStatement, .returnStatement): return true
      case (.throwStatement, .throwStatement): return true
      case (.nextCase, .nextCase): return true
      default: return false
    }
  }

  public var hashValue: Int {
    switch self {
      case .basicBlock(let block): return block.hashValue
      case .passiveNext: return 2
      case .switchFallthrough: return 3
      case .breakStatement: return 4
      case .labelledBreakStatement(let str): return str.hashValue
      case .continueStatement: return 6
      case .labelledContinueStatement(let str): return str.hashValue
      case .returnStatement: return 8
      case .throwStatement: return 9
      case .nextCase: return 10
    }
  }
}