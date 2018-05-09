import BracketStructureParser
import Source
import Regex

/// Represents a node in a Swift abstract syntax tree
public struct ASTNode {
  public let type: String
  public let attributes: [String]
  public let children: [ASTNode]

  enum Error: Swift.Error {
    case parseFailure(String)
  }

  public var range: SourceRange? {
    let rangeRegex = Regex("range=\\[(.*\\.swift):(\\d+):(\\d+) - line:(\\d+):(\\d+)\\]")
    return (attributes.lazy.flatMap { rangeRegex.firstMatch(in: $0) }).first.map { rangeRegexMatch in
      SourceRange(
        start: SourceLocation(
          identifier: rangeRegexMatch.captures[0]!,
          line: Int(rangeRegexMatch.captures[1]!)!,
          column: Int(rangeRegexMatch.captures[2]!)!
        ),
        end: SourceLocation(
          identifier: rangeRegexMatch.captures[0]!,
          line: Int(rangeRegexMatch.captures[3]!)!,
          column: Int(rangeRegexMatch.captures[4]!)!
        )
      )
    }
  }
}

extension ASTNode: Equatable {
  public static func == (lhs: ASTNode, rhs: ASTNode) -> Bool {
    return lhs.type == rhs.type && lhs.attributes == rhs.attributes && lhs.children == rhs.children
  }
}

/// Parse AST nodes from `swiftc ast-dump`s
extension ASTNode {
  public init(string: String) throws {
    let bracketStructure = try BracketStructure(string: string)
    self = try ASTNode(bracketStructure: bracketStructure)
  }
  public init(bracketStructure: BracketStructure) throws {
    // Make sure bracket structure is a container
    guard case BracketStructure.container(let structureChildren) = bracketStructure else {
      throw Error.parseFailure("Found a non-container AST node")
    }

    // Make sure the container is non-empty
    guard structureChildren.count > 0 else {
      throw Error.parseFailure("Found an empty container AST node")
    }

    // Make sure the bracket structure has a first text node
    guard case BracketStructure.text(let typeString) = structureChildren[0] else {
      throw Error.parseFailure("Unnamed AST node")
    }

    let nonTypeChildren = structureChildren.dropFirst()

    let attributes: [String] = nonTypeChildren.compactMap {
      if case BracketStructure.text(let attrString) = $0 {
        return attrString
      } else {
        return nil
      }
    }

    let children: [ASTNode] = try nonTypeChildren.compactMap {
      if case BracketStructure.container(_) = $0 {
        return try ASTNode(bracketStructure: $0)
      } else {
        return nil
      }
    }

    self.type = typeString
    self.attributes = attributes
    self.children = children
  }
}
