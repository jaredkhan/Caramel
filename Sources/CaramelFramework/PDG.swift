/// Program Dependence Graph
/// Nodes are Basic Blocks
/// Edges are dependencies between blocks (either data or control dependencies)
public class PDG {
  public let nodes: Set<BasicBlock>
  public let edges: [BasicBlock: Set<PDGEdge>]
  public let start: BasicBlock

  public init(cfg: CompleteCFG) {
    var nodes = Set<BasicBlock>()
    var edges = [BasicBlock: Set<PDGEdge>]()
    for node in cfg.nodes {
      edges[node] = []
    }
    let postdominatorTree = buildImmediatePostdominatorTree(cfg: cfg)
    for node in cfg.nodes {
      // Nothing is control or data dependent on the end node,
      // Do not include it in the PDG
      guard node != cfg.end else { continue }
      nodes.insert(node)

      let controlDependents = findControlDependents(
        of: node,
        inCFG: cfg,
        withPostdominatorTree: postdominatorTree
      )

      for controlDependent in controlDependents {
        edges[node]!.formUnion([.control(controlDependent)])
      }

      let dataDependents = findDataDependents(of: node, inCFG: cfg)

      for dataDependent in dataDependents {
        edges[node]!.formUnion([.data(dataDependent)])
      }
    }
    self.nodes = nodes
    self.edges = edges
    self.start = cfg.start
  }
}

public enum PDGEdge: Hashable {
  case data(BasicBlock)
  case control(BasicBlock)

  public static func ==(lhs: PDGEdge, rhs: PDGEdge) -> Bool {
    switch (lhs, rhs) {
      case (.data(let lBlock), .data(let rBlock)): return lBlock == rBlock
      case (.control(let lBlock), .control(let rBlock)): return lBlock == rBlock
      default: return false
    }
  }

  public var hashValue: Int {
    switch self {
      case .data(let block): return block.hashValue << 1
      case .control(let block): return (block.hashValue << 1) + 1
    }
  }
}

/// Find the data dependents of a given node in a given CFG
/// Performs a BFS for each definition in the given node
/// Complexity: O(|E|d)
/// where |E| is the number of edges in the CFG,
/// d is the number of definitions in the given node
public func findDataDependents(of startPoint: BasicBlock, inCFG cfg: CompleteCFG) -> Set<BasicBlock> {
  var dependents = Set<BasicBlock>()

  for definitionUSR in startPoint.definitions() {
    var expansionQueue = Queue<BasicBlock>()
    var visitedNodes = Set<BasicBlock>()

    for nextNode in cfg.edges[startPoint] ?? [] {
      expansionQueue.enqueue(nextNode)
    }

    while let currentNode = expansionQueue.dequeue() {
      visitedNodes.insert(currentNode)

      // If I reference the definition, add me to the dependents
      if currentNode.references().contains(definitionUSR) {
        dependents.insert(currentNode)
      }

      // If I redefine the definition, do not visit my children
      guard !currentNode.definitions().contains(definitionUSR) else { continue }

      // Enqueue all my children that haven't been seen already
      for nextNode in cfg.edges[currentNode] ?? [] {
        if !visitedNodes.contains(nextNode) {
          expansionQueue.enqueue(nextNode)
        }
      }
    }
  }

  return dependents
}

public func backwardPostOrderNumbering(cfg: CompleteCFG) -> (forward: [Int: BasicBlock], inverse: [BasicBlock: Int]) {
  var remainingNodeStack = [cfg.end]
  var resultStack: [BasicBlock] = []
  var visitedNodes = Set<BasicBlock>()

  while let topNode = remainingNodeStack.popLast() {
    guard !visitedNodes.contains(topNode) else { continue }
    visitedNodes.insert(topNode)
    resultStack.append(topNode)
    for nextNode in cfg.reverseEdges[topNode] ?? [] {
      remainingNodeStack.append(nextNode)
    }
  }

  var forwardMapping: [Int: BasicBlock] = [:]
  var inverseMapping: [BasicBlock: Int] = [:]
  var index = 0
  while let node = resultStack.popLast() {
    forwardMapping[index] = node
    inverseMapping[node] = index
    index += 1
  }
  return (forward: forwardMapping, inverse: inverseMapping)
}

/// Cooper, Harvey & Kennedy: A simple, fast dominance algorithm
/// (http://www.hipersoft.rice.edu/grads/publications/dom14.pdf)
public func buildImmediatePostdominatorTree(cfg: CompleteCFG) -> [BasicBlock: BasicBlock] {
  let (numbering, inverseNumbering) = backwardPostOrderNumbering(cfg: cfg)
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
  postdominator[inverseNumbering[cfg.end]!] = inverseNumbering[cfg.end]!

  var changed = true
  while changed {
    changed = false
    for index in (0 ..< numbering.count).reversed() {
      let node = numbering[index]!
      guard node != cfg.end else { continue }

      // Intersect all the successors that have postdominators
      let successorsWithPostdominators = cfg.edges[node]!.flatMap { successor -> Int? in
        let successorIndex = inverseNumbering[successor]!
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

  var resultTree: [BasicBlock: BasicBlock] = [:]
  for (nodeIndex, immediatePostdominatorIndex) in postdominator {
    resultTree[numbering[nodeIndex]!] = numbering[immediatePostdominatorIndex]! 
  }
  return resultTree
}

/// Returns the set of nodes including the source and sink along the path from source to sink
/// Sink is the end node since this is a postdominator tree
private func pathToSink(inPostDominatorTree postdominatorTree: [BasicBlock: BasicBlock], from source: BasicBlock) -> Set<BasicBlock> {
  var includedNodes: Set<BasicBlock> = [source]
  var lastNode = source
  while let nextNode = postdominatorTree[lastNode], nextNode != lastNode {
    includedNodes.insert(nextNode)
    lastNode = nextNode
  }
  return includedNodes
}

public func findControlDependents(of startPoint: BasicBlock, inCFG cfg: CompleteCFG, withPostdominatorTree postdominatorTree: [BasicBlock: BasicBlock]) -> Set<BasicBlock> {
  // TODO: Factor this out
  let childPostdominators = cfg.edges[startPoint]!.map { child in
    pathToSink(inPostDominatorTree: postdominatorTree, from: child)
  }
  let allPostdominators: Set<BasicBlock> = childPostdominators.reduce([], { $0.union($1) })
  let commonPostdominators: Set<BasicBlock> = childPostdominators.reduce(childPostdominators.first ?? [], { $0.intersection($1) })

  return allPostdominators.subtracting(commonPostdominators)
}