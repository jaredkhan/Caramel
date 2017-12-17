struct BasicBlock: Block {
  let offset: Int64
  let length: Int64
  let type: BasicBlockType
  // /// Lists all the symbols that are defined in this block
  // func definitions() -> [USR]

  // /// Lists all the symbols that are referred to in this block
  // func references() -> [USR]
}

enum BasicBlockType {
  case ifCondition

  case whileCondition

  case guardCondition

  case breakStatement

  case continueStatement

  case fallthroughStatement

  case forInSequence
  case forInId

  case switchSubject
  case switchCasePattern

  case repeatWhileCondition

  case functionParameter
  case functionReturnStatement

  case throwStatement
  case expression
}