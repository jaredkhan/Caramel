/// Points to a next hop in a control flow graph
/// For use in PartialCFGs
public enum NextNode: Equatable, Hashable {
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
