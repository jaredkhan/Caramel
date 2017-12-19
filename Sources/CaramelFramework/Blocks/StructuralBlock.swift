import SourceKittenFramework

public protocol StructuralBlock: Block {
  // What do I want to define on structural block?
  // var description
}

public enum StructuralBlockError: Swift.Error {
    case unsupportedKind(String)
    case unsupportedObject
  }

public func structuralBlock(filePath: String) throws -> StructuralBlock {
    let structure = Structure(file: File(path: filePath)!)
    return try structure.structuralBlock()
  }

public func structuralBlock(dict: [String: SourceKitRepresentable]) throws -> StructuralBlock {
  if let kind = dict["key.kind"] as? String {
    switch kind {
    case "source.lang.swift.stmt.if": return try IfStatement(dict: dict)
    case "source.lang.swift.stmt.repeatwhile": return try RepeatWhileStatement(dict: dict)
    case "source.lang.swift.stmt.foreach": return try ForEach(dict: dict)
    case "source.lang.swift.decl.function.free": return try Function(dict: dict)
    case "source.lang.swift.stmt.guard": return try GuardStatement(dict: dict)
    case "source.lang.swift.stmt.switch": return try SwitchStatement(dict: dict)
    case "source.lang.swift.stmt.while": return try WhileStatement(dict: dict)
    default: throw StructuralBlockError.unsupportedKind(kind)
    }
  } else if
      let diagnosticStage = dict["key.diagnostic_stage"] as? String,
      let offset = dict["key.offset"] as? Int64,
      let length = dict["key.length"] as? Int64,
      let substructure = dict["key.substructure"] as? [[String: SourceKitRepresentable]],
      diagnosticStage == "source.diagnostic.stage.swift.parse" {
      // This is the top level structure, form a block sequence
      return try BlockSequence(
        offset: offset,
        length: length,
        children: substructure
      )
  } else {
    dump(dict)
    throw StructuralBlockError.unsupportedObject
  }
}

extension Structure {
  func structuralBlock() throws -> StructuralBlock {
    return try CaramelFramework.structuralBlock(dict: dictionary)
  }
}
