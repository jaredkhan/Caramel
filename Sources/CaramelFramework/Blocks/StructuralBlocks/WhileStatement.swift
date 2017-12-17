import SourceKittenFramework

class WhileStatement: StructuralBlock {
  let offset: Int64
  let length: Int64
  let conditionBlock: Block // elements > source.lang.swift.structure.elem.condition_expr
  let body: Block // substructure > source.lang.swift.stmt.brace

  enum Error: Swift.Error {
    case missingCondition
    case missingBody
    case missingLocation
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
      type: .whileCondition
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
