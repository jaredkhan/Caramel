import SourceKittenFramework

class GuardStatement: StructuralBlock {
  let offset: Int64
  let length: Int64
  let conditionBlock: BasicBlock
  let elseBlock: Block
  
  enum Error: Swift.Error {
    case missingCondition
    case missingElseBlock
    case missingLocation
  }

  public func getCFG() -> CFG {
    let elseCFG = elseBlock.getCFG()

    // If statement has no context it can pass down

    let partialCFG = CFG(
      nodes: [conditionBlock],
      edges: [
        conditionBlock: [
          .passiveNext,
          elseCFG.entryPoint
        ],
      ],
      entryPoint: .basicBlock(conditionBlock)
    )

    return partialCFG.merging(with: elseCFG)
  }

  init(dict: [String: SourceKitRepresentable]) throws {
    // Get location
    guard
      let offset = dict["key.offset"] as? Int64,
      let length = dict["key.length"] as? Int64
      else {
      throw Error.missingLocation
    }
    self.offset = offset
    self.length = length

    // Get condition block
    guard
      let elements = dict["key.elements"] as? [[String: SourceKitRepresentable]],
      let conditionDict = elements.first(where: {
        ($0["key.kind"] as? String) == "source.lang.swift.structure.elem.condition_expr"
      }),
      let conditionOffset = conditionDict["key.offset"] as? Int64,
      let conditionLength = conditionDict["key.length"] as? Int64
      else {
      throw Error.missingCondition
    }

    conditionBlock = BasicBlock(
      offset: conditionOffset,
      length: conditionLength,
      type: .ifCondition
    )

    // Else blocks are in brace statements
    guard
      let substructure = dict["key.substructure"] as? [[String: SourceKitRepresentable]]
      else {
      throw Error.missingElseBlock
    }

    let subBraces = substructure.filter { ($0["key.kind"] as? String) == "source.lang.swift.stmt.brace" }

    guard subBraces.count >= 1 else { throw Error.missingElseBlock }

    elseBlock = try BlockSequence(braceDict: subBraces[0])
  }
}