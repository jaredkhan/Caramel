extension BasicBlock {
  var graphVizIdentifier: String {
    return "\(type)_\(range.start.line)_\(range.start.column)_\(range.end.line)_\(range.end.column)"
  }
}

public extension CFG {
  func graphVizDotFormat() -> String {
    var result = "digraph G {"

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