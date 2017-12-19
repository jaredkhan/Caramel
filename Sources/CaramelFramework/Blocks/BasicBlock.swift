class BasicBlock: Block {
  let offset: Int64
  let length: Int64
  let type: BasicBlockType

  init(offset: Int64, length: Int64, type: BasicBlockType) {
    self.offset = offset
    self.length = length
    self.type = type
  }

  // If we are getting the CFG of a BasicBlock directly,
  // then we just want a wrapper that has this basic block as an entry point and moves on
  // TODO: Implement guard, break etc.
  func getCFG() -> CFG {
    return CFG(
      nodes: [self],
      edges: [self: [.passiveNext]],
      entryPoint: .basicBlock(self)
    )
  }

  // /// Lists all the symbols that are defined in this block
  // func definitions() -> [USR]

  // /// Lists all the symbols that are referred to in this block
  // func references() -> [USR]
}

extension BasicBlock: Hashable {
  public static func == (lhs: BasicBlock, rhs: BasicBlock) -> Bool {
    return (lhs.offset, lhs.length, lhs.type) == (rhs.offset, rhs.length, rhs.type)
  }

  public var hashValue: Int {
    return Int(offset) ^ Int(length) ^ type.hashValue
  }
}

enum BasicBlockType {
  /// Synthesized start block for the CFG
  case start

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

  /// Just here until we get the real expressions in
  case fillerBlock
}