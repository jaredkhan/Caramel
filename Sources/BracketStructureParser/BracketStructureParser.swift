public enum BracketStructure {
  case text(String)
  case container([BracketStructure])

  public init(string: String) throws {
    self = try BracketStructureParser.parse(string)
  }
}

extension BracketStructure: Equatable {
  public static func ==(lhs: BracketStructure, rhs: BracketStructure) -> Bool {
    switch (lhs, rhs) {
      case (.text(let lString), .text(let rString)):
        return lString == rString
      case (.container(let lChildren), .container(let rChildren)):
        return lChildren == rChildren
      default: return false
    }
  }
}

private struct BracketStructureParser {
  static func parse(_ input: String) throws -> BracketStructure {

    enum Container {
      case roundBracket
      case squareBracket
      case singleQuote
      case doubleQuote
    }

    enum BracketStructureParseError: Error {
      case invalidStructure(String)
    }

    // This remainder is a substring where the startIndex will approach the endIndex
    var remainder = Substring(input)

    /// Move the startIndex forward until we hit non-whitespace
    func consumeWhitespace() {
      let whitespaces = Set<Character>(["\n", " ", "\t", "\r\n"])
      while let first = remainder.first, whitespaces.contains(first) {
        remainder.removeFirst()
      }
    }

    /// Move the startIndex forward past the next structure, returning that structure
    func consumeNextStructure() throws -> BracketStructure {
      consumeWhitespace()
      assert(!remainder.isEmpty)
      
      if let first = remainder.first {
        switch first { 
          case "(": return try consumeContainer()
          case ")": throw BracketStructureParseError.invalidStructure("Found surplus ) \(remainder)")
          case "]": throw BracketStructureParseError.invalidStructure("Found surplus ]")
          default: return try consumeText()
        }
      } else {
        throw BracketStructureParseError.invalidStructure("Trying to consume from empty buffer")
      }
    }
    
    /// Stops when it sees an unmatched closing bracket
    /// Throws if it sees a mismatched closing bracket
    func consumeText() throws -> BracketStructure {
      assert(!remainder.isEmpty)
      assert(remainder.first != "(")

      var containerStack: [Container] = []

      let startingPoint = remainder.startIndex

      /// Move the startIndex forward over the next text node
      scanOverText: while let currentChar = remainder.first {
        switch (currentChar) {
          case "(":
            containerStack.append(.roundBracket)
            remainder.removeFirst()
          case ")":
            if containerStack.last == .roundBracket {
              // We've reached a matched closing bracket
              containerStack.removeLast()
              remainder.removeFirst()
            } else {
              if containerStack.isEmpty {
                // We've reached an unmatched closing bracket
                break scanOverText
              } else {
                throw BracketStructureParseError.invalidStructure("Found mismatched )")
              }
            }
          case "[":
            containerStack.append(.squareBracket)
            remainder.removeFirst()
          case "]":
            if containerStack.last == .squareBracket {
              // We've reached a matched closing bracket
              containerStack.removeLast()
              remainder.removeFirst()
            } else {
              if containerStack.isEmpty {
                // We've reached an unmatched closing bracket
                break scanOverText
              } else {
                // We've reached a mismatched closing bracket
                throw BracketStructureParseError.invalidStructure("Found mismatched ]")
              }
            }
          case "\"":
            remainder.removeFirst()
            if let nextQuoteIndex = remainder.index(of: "\"") {
              // skip over everything in the quotes
              remainder = remainder[remainder.index(after: nextQuoteIndex) ..< remainder.endIndex]
            } else {
              throw BracketStructureParseError.invalidStructure("Found mismatched \"")
            }
          case "\'":
            remainder.removeFirst()
            if let nextQuoteIndex = remainder.index(of: "\'") {
              // skip over everything in the quotes
              remainder = remainder[remainder.index(after: nextQuoteIndex) ..< remainder.endIndex]
            } else {
              throw BracketStructureParseError.invalidStructure("Found mismatched \'")
            }
          case " ", "\n", "\t", "\r":
            if containerStack.isEmpty {
              // We have found an unenclosed whitespace, 
              break scanOverText
            } else {
              // Whitespace is enclosed, consume it
              consumeWhitespace()
            }
          default:
            remainder.removeFirst()
        }
      }

      let resultText = input[startingPoint ..< remainder.startIndex]
      consumeWhitespace()
      return .text(String(resultText))
    }

    func consumeContainer() throws -> BracketStructure {
      assert(!remainder.isEmpty)
      assert(remainder.first == "(")
      
      remainder.removeFirst() // advance over the opening bracket
      consumeWhitespace()

      var children: [BracketStructure] = []
      while remainder.first != ")" {
        children.append(try consumeNextStructure())
        consumeWhitespace()
      }

      assert(remainder.first == ")")
      remainder.removeFirst() // advance over the closing bracket
      return .container(children)
    }

    var structures: [BracketStructure] = []

    consumeWhitespace()
    while !remainder.isEmpty {
      structures.append(try consumeNextStructure())
      consumeWhitespace()
    }

    if structures.count == 1, case .container(_) = structures[0] {
      return structures[0]
    } else {
      return .container(structures)
    }
  }
}  