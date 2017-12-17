import SourceKittenFramework

class SwitchStatement: StructuralBlock {
  let offset: Int64
  let length: Int64
  let subject: Block // elements > source.lang.swift.structure.elem.expr
  let cases: [CaseStatement] // substructure > source.lang.swift.stmt.case
  
  enum Error: Swift.Error {
    case missingLocation
    case missingSubject
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

    // Get subject block
    guard
      let elements = dict["key.elements"] as? [[String: SourceKitRepresentable]],
      let subjectDict = elements.first(where: {
        ($0["key.kind"] as? String) == "source.lang.swift.structure.elem.expr"
      }),
      let subjectOffset = subjectDict["key.offset"] as? Int64,
      let subjectLength = subjectDict["key.length"] as? Int64
      else {
      throw Error.missingSubject
    }
    subject = BasicBlock(
      offset: subjectOffset,
      length: subjectLength,
      type: .switchSubject
    )

    // switch can have no cases (e.g. switch on an empty enumeration type)
    let substructure = (dict["key.substructure"] as? [[String: SourceKitRepresentable]]) ?? []
    cases = substructure.filter {
      ($0["key.kind"] as? String) == "source.lang.swift.stmt.case"
    }.flatMap {
      try? CaseStatement(dict: $0)
    }
  }
}