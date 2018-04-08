/// Cooper, Harvey & Kennedy: A simple, fast dominance algorithm
/// (http://www.hipersoft.rice.edu/grads/publications/dom14.pdf)
public func buildImmediatePostdominatorTree(cfg: CompleteCFG) -> [Node: Node] {
  let ordering = backwardPostOrderNumbering(cfg: cfg)

  var postdominator: [Int: Int] = [:]

  // Nodes with higher numberings already have postdominator estimations
  // left and right should already have postdominator estimations
  // postDominators of x (and estimations) will always be greater than x in the numbering
  func commonPostdominator(left: Int, right: Int) -> Int {
    var pointer1 = left
    var pointer2 = right
    while pointer1 != pointer2 {
      if pointer1 < pointer2 {
        pointer1 = postdominator[pointer1]!
      } else {
        pointer2 = postdominator[pointer2]!
      }
    }
    return pointer1
  }
  // Initialise the postdominator of the end node to be the end node itself
  postdominator[ordering.index(for: cfg.end)] = ordering.index(for: cfg.end)

  var changed = true
  while changed {
    changed = false
    for (index, node) in ordering.nodes.enumerated().reversed() {
      guard node != cfg.end else { continue }

      // Intersect all the successors that have postdominators
      let successorsWithPostdominators = cfg.edges[node]!.compactMap { successor -> Int? in
        let successorIndex = ordering.index(for: successor)
        guard postdominator[successorIndex] != nil else { return nil }
        return successorIndex
      }

      assert(successorsWithPostdominators.count >= 1)
      let newEstimate = successorsWithPostdominators.reduce(successorsWithPostdominators.first!, commonPostdominator)
      if newEstimate != postdominator[index] {
        changed = true
        postdominator[index] = newEstimate
      }
    }
  }

  var resultTree: [Node: Node] = [:]
  for (nodeIndex, immediatePostdominatorIndex) in postdominator {
    resultTree[ordering.node(for: nodeIndex)] = ordering.node(for: immediatePostdominatorIndex)
  }
  return resultTree
}

/// A backward post order numbering of the nodes
/// Found by building a depth first search tree T rooted at END and working backward
/// Numbering by postorder traversal of T
/// END node should be last
private func backwardPostOrderNumbering(cfg: CompleteCFG) -> NodeOrdering {
  var remainingNodeStack = [cfg.end]
  var resultStack: [Node] = []
  var visitedNodes = Set<Node>()

  while let topNode = remainingNodeStack.popLast() {
    guard !visitedNodes.contains(topNode) else { continue }
    visitedNodes.insert(topNode)
    resultStack.append(topNode)
    for nextNode in cfg.reverseEdges[topNode] ?? [] {
      remainingNodeStack.append(nextNode)
    }
  }

  return NodeOrdering(array: resultStack.reversed())
}