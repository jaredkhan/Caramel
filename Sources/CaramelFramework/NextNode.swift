/// Points to a next hop in a control flow graph
/// For use in PartialCFGs
public enum NextNode {
  case node(Node)

  // Next node types that need to be resolved to actual nodes
  case passiveNext
  case switchFallthrough
  case breakStatement
  case labelledBreakStatement(String)
  case continueStatement
  case labelledContinueStatement(String)
  case returnStatement
  case throwStatement
  case nextCase
  case conditionHold
  case conditionFail
  case patternMatch
  case patternNotMatch
}

extension NextNode: Equatable, Hashable {
  public static func == (lhs: NextNode, rhs: NextNode) -> Bool {
    switch (lhs, rhs) {
      case (.node(let lBlock), .node(let rBlock)): return lBlock == rBlock
      case (.passiveNext, .passiveNext): return true
      case (.switchFallthrough, .switchFallthrough): return true
      case (.breakStatement, .breakStatement): return true
      case (.labelledBreakStatement(let llabel), .labelledBreakStatement(let rlabel)): return llabel == rlabel
      case (.continueStatement, .continueStatement): return true
      case (.labelledContinueStatement(let llabel), .labelledContinueStatement(let rlabel)): return llabel == rlabel
      case (.returnStatement, .returnStatement): return true
      case (.throwStatement, .throwStatement): return true
      case (.nextCase, .nextCase): return true
      case (.conditionHold, .conditionHold): return true
      case (.conditionFail, .conditionFail): return true
      case (.patternMatch, .patternMatch): return true
      case (.patternNotMatch, .patternNotMatch): return true
      default: return false
    }
  }

  public var hashValue: Int {
    switch self {
      case .node(let node): return node.hashValue
      case .passiveNext: return 2
      case .switchFallthrough: return 3
      case .breakStatement: return 4
      case .labelledBreakStatement(let str): return str.hashValue
      case .continueStatement: return 6
      case .labelledContinueStatement(let str): return str.hashValue
      case .returnStatement: return 8
      case .throwStatement: return 9
      case .nextCase: return 10
      case .conditionHold: return 11
      case .conditionFail: return 12
      case .patternMatch: return 13
      case .patternNotMatch: return 14
    }
  }
}
