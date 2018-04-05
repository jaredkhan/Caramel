import Source

// This file adds a GraphViz dot visualisation to a CompleteCFG

public extension CompleteCFG {
  func graphVizDotFormat() -> String {
    var result = "digraph G {"

    result += "node [shape=box]"

    for node in nodes {
      result += "\(node.graphVizIdentifier) [label=\"\(node.graphVizLabel)\"];"
    }

    for (node, nextNodes) in edges {
      for nextNode in nextNodes {
        result += "\(node.graphVizIdentifier) -> \(nextNode.graphVizIdentifier);"
      }
    }

    result += "}"

    return result
  }
}
