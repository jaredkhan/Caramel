import SourceKittenFramework

class SwitchStatement: StructuralBlock {
  let offset: Int64
  let length: Int64
  let subject: BasicBlock // elements > source.lang.swift.structure.elem.expr
  let cases: [CaseStatement] // substructure > source.lang.swift.stmt.case
  
  enum Error: Swift.Error {
    case missingLocation
    case missingSubject
  }

  public func getCFG() -> CFG {
    var caseCFGs: [CFG] = []
    
    for caseStatement in cases.reversed() {
      caseCFGs.append(caseStatement.getCFG().applying(context: [
        // For each case, if it's not the last then point it to the next one
        // Remove the nextCase edge from the final case cfg
        // because if we enter the final case, by Swift semantics, it cannot fail
        // Not every case can fail so shold never propagate a nextCase to a passiveNext
        .nextCase: caseCFGs.last?.entryPoint
      ]))
    }

    let partialCFG = CFG(
      nodes: [subject],
      edges: [
        subject: [
          caseCFGs.first?.entryPoint ?? .passiveNext
        ]
      ],
      entryPoint: .basicBlock(subject)
    )

    return partialCFG.merging(with: caseCFGs)
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