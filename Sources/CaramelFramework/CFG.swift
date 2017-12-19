enum NextBlockType {
  /// When the expression doesn't make any decision about control flow
  case passiveNext
  case switchFallthrough
  case breakStatement
  case labelledBreakStatement(String)
  case continueStatement
  case labelledContinueStatement(String)
  case returnStatement
  case throwStatement
}
