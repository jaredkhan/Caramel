import SourceKittenFramework

/// Represents a simple linear sequence of blocks
class BlockSequence: StructuralBlock {
  let offset: Int64
  let length: Int64
  let blocks: [Block]

  enum Error: Swift.Error {
    case missingLocation
  }

  public func getCFG() -> CFG {
    if blocks.isEmpty {
      // Return a filler block so that we can demo this
      // TODO: Tear this out and go straight for the passiveNext
      let fillerBlock = BasicBlock(
        offset: offset,
        length: length,
        type: .fillerBlock
      )

      return CFG(
        nodes: [fillerBlock],
        edges: [fillerBlock: [.passiveNext]],
        entryPoint: .basicBlock(fillerBlock)
      )
    }

    let blockCFGs = blocks.map { $0.getCFG() }

    var resolvedBlockCFGs: [CFG] = []

    // Go in reverse order because each one here relies on the following one being resolved
    for cfg in blockCFGs.reversed() {
      if let nextCFG = resolvedBlockCFGs.first {
        var cfg = cfg
        cfg.apply(context: [.passiveNext: nextCFG.entryPoint])
        resolvedBlockCFGs = [cfg] + resolvedBlockCFGs
      } else {
        resolvedBlockCFGs = [cfg] + resolvedBlockCFGs
      }
    }

    let partialCFG = CFG(
      nodes: [],
      edges: [:],
      entryPoint: resolvedBlockCFGs.first?.entryPoint ?? .passiveNext
    )

    return partialCFG.merging(with: blockCFGs)
  }

  /// Take a dictionary representing a brace object
  init(braceDict: [String: SourceKitRepresentable]) throws {
    // Get position
    guard
      let offset = braceDict["key.offset"] as? Int64,
      let length = braceDict["key.length"] as? Int64
      else {
      throw Error.missingLocation
    }
    self.offset = offset
    self.length = length

    print("GET SUBSTRUCTURE OFFSET")

    // Get the substructure and map children to blocks
    let substructure = braceDict["key.substructure"] as? [[String: SourceKitRepresentable]] ?? []
    blocks = substructure.flatMap { 
      print("Parsing substructure")
      do {
        return try structuralBlock(dict: $0)
      } catch {
        print("Error info: \(error)")
        return nil
      }
    }
  }

  /// Take a position and an array of children
  init(offset: Int64, length: Int64, children: [[String: SourceKitRepresentable]]) throws {
    self.offset = offset
    self.length = length
    blocks = children.flatMap {
      do {
        return try structuralBlock(dict: $0)
      } catch {
        print(type(of: error))
        print("Error info: \(error)")
        return nil
      }
    }
  }

}