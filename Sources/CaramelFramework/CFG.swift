/// Control Flow Graph
// Nodes are basic blocks
// Edges are directed and point to possible next blocks
struct CFG {
  let nodes: Set<BasicBlock>
  var edges: [BasicBlock: [NextBlock]]
  let entryPoint: BasicBlock

  // Resolve NextBlocks to other NextBlocks
  // e.g. resolving a .passiveNext to a basicBlock
  // e.g. resolving a .breakStatement to a .passiveNext
  mutating func applying(context: [NextBlock: NextBlock]) {
    edges = edges.mapValues { nextBlocks in
      nextBlocks.map { nextBlock in
        context[nextBlock] ?? nextBlock
      }
    }
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
    }
  }
}