/// Get only the control dependency edges for this CFG
func controlDependencyEdges(cfg: CompleteCFG) -> (forward: [Node: Set<PDGEdge>], reverse: [Node: Set<PDGEdge>]) {
  let postdominatorTree = buildImmediatePostdominatorTree(cfg: cfg)

  var edges: [Node: Set<PDGEdge>] = [:]
  var reverseEdges: [Node: Set<PDGEdge>] = [:]

  // Initialise edge and reverseEdge sets to be empty
  for node in cfg.nodes {
    guard node != cfg.end else { continue }
    edges[node] = []
    reverseEdges[node] = []
  }

  for node in cfg.nodes {
    let controlDependents = findControlDependents(
      of: node,
      inCFG: cfg,
      withPostdominatorTree: postdominatorTree
    )

    for controlDependent in controlDependents {
      edges[node]!.insert(.control(controlDependent))
      reverseEdges[controlDependent]!.insert(.control(node))
    }
  }

  return (forward: edges, reverse: reverseEdges)
}

/// Returns the set of nodes including the head of all edges along the path from source to sink
/// If the given sink is not in the path from source to the end node, then return the path to the end node
/// Since this is a tree, this path is unique
private func path(from source: Node, to sink: Node, inPostDominatorTree postdominatorTree: [Node: Node]) -> Set<Node> {
  guard source != sink else { return [] }
  var includedNodes: Set<Node> = [source]
  var prevNode = source
  while let node = postdominatorTree[prevNode] {
    guard node != sink else { break }
    guard node != prevNode else { break } // We're not at the END node
    includedNodes.insert(node)
    prevNode = node
  }
  return includedNodes
}

public func findControlDependents(of startPoint: Node, inCFG cfg: CompleteCFG, withPostdominatorTree postdominatorTree: [Node: Node]) -> Set<Node> {
  let immediatePostdominator = postdominatorTree[startPoint]!
  let childPostdominators = cfg.edges[startPoint]!.map { child in
    path(from: child, to: immediatePostdominator, inPostDominatorTree: postdominatorTree)
  }
  let allPostdominators: Set<Node> = childPostdominators.reduce([], { $0.union($1) })
  return allPostdominators
}
