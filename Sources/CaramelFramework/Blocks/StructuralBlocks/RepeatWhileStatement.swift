import SourceKittenFramework

class RepeatWhileStatement: StructuralBlock {
  let offset: Int64
  let length: Int64
  let conditionBlock: BasicBlock // elements > source.lang.swift.structure.elem.expr
  let body: BlockSequence // substructure  > source.lang.swift.stmt.brace
  
  enum Error: Swift.Error {
    case missingCondition
    case missingBody
    case missingLocation
  }

  public func getCFG() -> CFG {
    let bodyCFG = body.getCFG().applying(context: [
      .passiveNext: .basicBlock(conditionBlock),
      .continueStatement: .basicBlock(conditionBlock),
      .breakStatement: .passiveNext
    ])

    // If statement has no context it can pass down

    let partialCFG = CFG(
      nodes: [conditionBlock],
      edges: [
        conditionBlock: [
          bodyCFG.entryPoint,
          .passiveNext
        ]
      ],
      entryPoint: bodyCFG.entryPoint
    )

    return partialCFG.merging(with: bodyCFG)
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
        ($0["key.kind"] as? String) == "source.lang.swift.structure.elem.expr"
      }),
      let conditionOffset = conditionDict["key.offset"] as? Int64,
      let conditionLength = conditionDict["key.length"] as? Int64
      else {
      throw Error.missingCondition
    }

    conditionBlock = BasicBlock(
      offset: conditionOffset,
      length: conditionLength,
      type: .repeatWhileCondition
    )

    // Get body
    guard 
      let substructure = dict["key.substructure"] as? [[String: SourceKitRepresentable]],
      let braceDict = substructure.first(where: { ($0["key.kind"] as? String) == "source.lang.swift.stmt.brace" })
      else {
      throw Error.missingBody
    }
    body = try BlockSequence(braceDict: braceDict)
  }
}