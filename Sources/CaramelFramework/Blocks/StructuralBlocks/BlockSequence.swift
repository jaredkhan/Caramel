import SourceKittenFramework

/// Represents a simple linear sequence of blocks
class BlockSequence: StructuralBlock {
  let offset: Int64
  let length: Int64
  let blocks: [Block]

  enum Error: Swift.Error {
    case missingLocation
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