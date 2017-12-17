import SourceKittenFramework

class Function: StructuralBlock {
  let offset: Int64
  let length: Int64
  let parameters: [Block] // substructure > source.lang.swift.decl.var.parameter
  let body: Block // substructure > !source.lang.swift.decl.var.parameter

  
  enum Error: Swift.Error {
    case missingLocation
    case missingSubstructure
    case missingBody
  }

  init(dict: [String: SourceKitRepresentable]) throws {
    print("PARSING FUNCTION")
    // Get location
    guard
      let offset = dict["key.offset"] as? Int64,
      let length = dict["key.length"] as? Int64
      else {
      throw Error.missingLocation
    }
    self.offset = offset
    self.length = length

    // Get substructure
    // Function can have empty substructure if no params and no internal structure
    let substructure = dict["key.substructure"] as? [[String: SourceKitRepresentable]]

    // Get parameters
    let parameterDicts = substructure?.filter {
      ($0["key.kind"] as? String) == "source.lang.swift.decl.var.parameter"
    } ?? []
    parameters = parameterDicts.flatMap { parameterDict in
      guard
        let parameterOffset = parameterDict["key.offset"] as? Int64,
        let parameterLength = parameterDict["key.length"] as? Int64
        else {
        return nil
      }

      return BasicBlock(
        offset: parameterOffset,
        length: parameterLength,
        type: .functionParameter 
      )
    }

    // Get body
    let nonParameterSubstructure = substructure?.filter {
      ($0["key.kind"] as? String) != "source.lang.swift.decl.var.parameter"
    } ?? []

    guard 
      let bodyOffset = dict["key.bodyoffset"] as? Int64,
      let bodyLength = dict["key.bodylength"] as? Int64
      else {
      throw Error.missingBody
    }
    
    print("GETTING FUNCTION BODY")
    body = try BlockSequence(
      offset: bodyOffset,
      length: bodyLength,
      children: nonParameterSubstructure
    )
  }
}