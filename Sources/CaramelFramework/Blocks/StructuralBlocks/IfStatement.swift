import SourceKittenFramework

class IfStatement: StructuralBlock {
  let offset: Int64
  let length: Int64
  let conditionBlock: BasicBlock // elements > source.lang.swift.structure.elem.condition_expr
  let thenBlock: BlockSequence // substructure[0]
  let elseBlock: BlockSequence? // substructure[1]

  enum Error: Swift.Error {
    case missingCondition
    case missingThenBlock
    case missingLocation
  }

  public func getCFG() -> CFG {
    let thenCFG = thenBlock.getCFG()
    let elseCFG = elseBlock?.getCFG()

    // If statement has no context it can pass down

    var conditionBlockOutgoings = [thenCFG.entryPoint]
    if let elseEntry = elseCFG?.entryPoint {
      conditionBlockOutgoings.append(elseEntry)
    }

    let partialCFG = CFG(
      nodes: [conditionBlock],
      edges: [
        conditionBlock: conditionBlockOutgoings
      ],
      entryPoint: .basicBlock(conditionBlock)
    )

    return partialCFG.merging(with: [thenCFG, elseCFG].flatMap({ $0 }))
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

    // Both then and else blocks are in brace statements
    guard let substructure = dict["key.substructure"] as? [[String: SourceKitRepresentable]] else {
      throw Error.missingThenBlock
    }

    let subBraces = substructure.filter { ($0["key.kind"] as? String) == "source.lang.swift.stmt.brace" }
    
    guard subBraces.count >= 1 else { throw Error.missingThenBlock }

    thenBlock = try BlockSequence(braceDict: subBraces[0])
    elseBlock = subBraces.count >= 2 ? try BlockSequence(braceDict: subBraces[1]) : nil
  }
}
