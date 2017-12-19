import SourceKittenFramework

class CaseStatement: StructuralBlock {
  let offset: Int64
  let length: Int64
  let patterns: [BasicBlock] // elements > source.lang.swift.structure.elem.pattern
  let body: BlockSequence

  enum Error: Swift.Error {
    case missingLocation
    case missingPattern
  }

  public func getCFG() -> CFG {
    assert(patterns.count >= 1)

    let bodyCFG = body.getCFG()

    var edges: [BasicBlock: [NextBlock]] = [:]
    for (index, pattern) in patterns.enumerated() {
      var nextBlocks: [NextBlock] = []
      // If has successor, point to it
      if patterns.count > index + 1 {
        nextBlocks.append(.basicBlock(patterns[index + 1]))
      } else {
        nextBlocks.append(.nextCase)
      }
      // Point to the body entryPoint
      nextBlocks.append(bodyCFG.entryPoint)

      edges[pattern] = nextBlocks
    }

    let partialCFG = CFG(
      nodes: Set(patterns),
      edges: edges,
      entryPoint: .basicBlock(patterns[0])
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

    // Get pattern
    guard let elements = dict["key.elements"] as? [[String: SourceKitRepresentable]] else {
        throw Error.missingPattern
    }

    let patternDicts = elements.filter({ ($0["key.kind"] as? String) == "source.lang.swift.structure.elem.pattern" })

    guard patternDicts.count >= 1 else {
      throw Error.missingPattern
    }

    patterns = patternDicts.flatMap { patternDict in 
      guard
        let patternLength = patternDict["key.length"] as? Int64,
        let patternOffset = patternDict["key.offset"] as? Int64
        else {
        return nil
      }
      return BasicBlock(
        offset: patternOffset,
        length: patternLength,
        type: .switchCasePattern
      )
    }

    // sourcekit doesn't give us the position of case bodies so this is an approximation
    // adding one because we assume there is a `:` after the final pattern
    // (Note, not necessarily the case because whitespace is allowed)
    let bodyOffset = patterns.last!.offset + patterns.last!.length + 1
    // The end of the body is the end of the case so last position is the same
    // i.e. bodyOffset + bodyLength == offset + length
    // i.e. bodyLength = offset + length - bodyOffset
    let bodyLength = offset + length - bodyOffset
    // There may be no substructures in the case so have a default here
    let substructure = (dict["key.substructure"] as? [[String: SourceKitRepresentable]]) ?? []
    body = try BlockSequence(
      offset: bodyOffset,
      length: bodyLength,
      children: substructure
    )
  }
}
