public extension PDG {
  func graphVizDotFormat() -> String {
    var result = "digraph G {"

    result += "node [shape=box]"

    for node in nodes {
      result += "\(node.graphVizIdentifier) [label=\"\(node.graphVizLabel)\"];"
    }

    for (node, outgoingEdges) in edges {
      for outgoingEdge in outgoingEdges {
        switch outgoingEdge {
          case .data(let nextBlock):
            result += "\(node.graphVizIdentifier) -> \(nextBlock.graphVizIdentifier) [style=dashed];"
          case .control(let nextBlock):
            result += "\(node.graphVizIdentifier) -> \(nextBlock.graphVizIdentifier) [style=solid];"
        }
      }
    }

    result += "}"

    return result
  }
}