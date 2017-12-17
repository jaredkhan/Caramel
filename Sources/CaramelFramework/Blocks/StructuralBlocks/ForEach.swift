import SourceKittenFramework

class ForEach: StructuralBlock {
  let offset: Int64
  let length: Int64
  let id: Block // elements > source.lang.swift.structure.elem.id
  let sequence: Block // elements > source.lang.swift.structure.elem.expr
  let body: BlockSequence // substructure > source.lang.swift.stmt.brace


  enum Error: Swift.Error {
    case missingLocation
    case missingId
    case missingSequence
    case missingBody
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

    // Get the elements
    guard
      let elements = dict["key.elements"] as? [[String: SourceKitRepresentable]]
      else {
      throw Error.missingId
    }
    
    // Get the id
    guard
      let idDict = elements.first(where: { ($0["key.kind"] as? String) == "source.lang.swift.structure.elem.id" }),
      let idOffset = idDict["key.offset"] as? Int64,
      let idLength = idDict["key.length"] as? Int64
      else {
      throw Error.missingId  
    }
    id = BasicBlock(
      offset: idOffset,
      length: idLength,
      type: .forInId
    )

    // Get the sequence
    guard 
      let sequenceDict = elements.first(where: { ($0["key.kind"] as? String) == "source.lang.swift.structure.elem.expr" }),
      let sequenceOffset = sequenceDict["key.offset"] as? Int64,
      let sequenceLength = sequenceDict["key.length"] as? Int64
      else {
      throw Error.missingSequence
    }
    sequence = BasicBlock(
      offset: sequenceOffset,
      length: sequenceLength,
      type: .forInSequence
    )

    // Get the body
    guard 
      let substructure = dict["key.substructure"] as? [[String: SourceKitRepresentable]],
      let braceDict = substructure.first(where: { ($0["key.kind"] as? String) == "source.lang.swift.stmt.brace" })
      else {
      throw Error.missingBody
    }
    body = try BlockSequence(braceDict: braceDict)
  }
}