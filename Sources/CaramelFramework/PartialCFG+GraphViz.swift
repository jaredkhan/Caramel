import Source

// This file adds a GraphViz dot visualisation to a PartialCFG

public extension PartialCFG {
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
