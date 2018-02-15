import Source

extension BasicBlock {
  var graphVizIdentifier: String {
    return "\(type)_\(range.start.line)_\(range.start.column)_\(range.end.line)_\(range.end.column)"
  }

  var graphVizLabel: String {
    switch type {
      case .start:
        return "START"
      // case .throw, .continue, .break: return "\(type)"
      default:
        var contents = String( (try? range.content()) ?? "<couldn't get content>")
        // need to escape any quotes in the string
        contents = contents.replacingOccurrences(of: "\"", with: "\\\"")
        var label = "\(type)"
        label += " \(range.start.line):\(range.start.column)-\(range.end.line):\(range.end.column)"
        label += "\\n"
        label += contents 

        let references = self.references()
        if !references.isEmpty {
          label += "\\nRefs:"
          for reference in references {
            label += "\\n"
            label += reference
          }
        }

        let definitions = self.definitions()
        if !definitions.isEmpty {
          label += "\\nDefs:"
          for definition in definitions {
            label += "\\n"
            label += definition
          }
        }
        
        return label
    }
  }
}

public extension CFG {
  func graphVizDotFormat() -> String {
    var result = "digraph G {"

    result += "node [shape=box]"

    for node in nodes {
      result += "\(node.graphVizIdentifier) [label=\"\(node.graphVizLabel)\"];"
    }

    for (node, outgoingEdges) in edges {
      for outgoingEdge in outgoingEdges {
        switch outgoingEdge {
          case .basicBlock(let nextBlock): 
            result += "\(node.graphVizIdentifier) -> \(nextBlock.graphVizIdentifier);"
          case .passiveNext:
            result += "\(node.graphVizIdentifier) -> END;"
          default: 
            result += "\(node.graphVizIdentifier) -> UNKNOWN;"
        }
      }
    }

    result += "}"

    return result
  }
}