import Foundation

/// Program Dependence Graph
/// Edges are dependencies between nodes (either data or control dependencies)
public class PDG: Equatable {
  public let nodes: Set<Node>
  public let edges: [Node: Set<PDGEdge>]
  public let reverseEdges: [Node: Set<PDGEdge>]
  public let start: Node

  init(nodes: Set<Node>, edges: [Node: Set<PDGEdge>], reverseEdges: [Node: Set<PDGEdge>], start: Node) {
    self.nodes = nodes
    self.edges = edges
    self.reverseEdges = reverseEdges
    self.start = start
  }

  public init(cfg: CompleteCFG) {
    var nodes = Set<Node>()
    var edges = [Node: Set<PDGEdge>]()
    var reverseEdges = [Node: Set<PDGEdge>]()
    for node in cfg.nodes {
      guard node != cfg.end else { continue }
      edges[node] = []
      reverseEdges[node] = []
    }
    let pdStartTime = NSDate().timeIntervalSince1970
    let postdominatorTree = buildImmediatePostdominatorTree(cfg: cfg)
    let pdDuration = NSDate().timeIntervalSince1970 - pdStartTime
    print("Built postdominator tree in: \(pdDuration)")

    var controlDepTime: TimeInterval = 0
    var dataDepTime: TimeInterval = 0

    for node in cfg.nodes {
      // Nothing is control or data dependent on the end node,
      // Do not include it in the PDG
      guard node != cfg.end else { continue }
      nodes.insert(node)

      let cdStart = NSDate().timeIntervalSince1970

      let controlDependents = findControlDependents(
        of: node,
        inCFG: cfg,
        withPostdominatorTree: postdominatorTree
      )

      for controlDependent in controlDependents {
        edges[node]!.insert(.control(controlDependent))
        reverseEdges[controlDependent]!.insert(.control(node))
      }

      let ddStart = NSDate().timeIntervalSince1970

      let dataDependents = findDataDependents(of: node, inCFG: cfg)

      for dataDependent in dataDependents {
        edges[node]!.insert(.data(dataDependent))
        reverseEdges[dataDependent]!.insert(.data(node))
      }

      let ddEnd = NSDate().timeIntervalSince1970
      controlDepTime += ddStart - cdStart
      dataDepTime += ddEnd - ddStart
    }
    print("Control dep time: \(controlDepTime)")
    print("Data dep time: \(dataDepTime)")
    self.nodes = nodes
    self.edges = edges
    self.reverseEdges = reverseEdges
    self.start = cfg.start
  }

  public func slice(criterion: Node) -> Set<Node> {
    var remainingNodeStack = [criterion]
    var sliceNodes = Set<Node>()

    while let currentNode = remainingNodeStack.popLast() {
      guard !sliceNodes.contains(currentNode) else { continue }
      sliceNodes.insert(currentNode)
      for edge in reverseEdges[currentNode] ?? [] {
        switch edge {
          case .control(let nextNode):
            remainingNodeStack.append(nextNode)
          case .data(let nextNode):
            remainingNodeStack.append(nextNode)
        }
      }
    }

    return sliceNodes
  }

  public func slice(line: Int, column: Int) -> Set<Node>? {
    // Find a node whose range contains this point
    return nodes.first(where: {
      $0.range.start.line <= line &&
      $0.range.start.column <= column &&
      $0.range.end.line >= line &&
      $0.range.end.column >= column
    }).map { slice(criterion: $0) }
  }

  private static func edgesMatch(_ lhs: PDG, _ rhs: PDG) -> Bool {
    if lhs.edges.count != rhs.edges.count { return false }
    for key in lhs.edges.keys {
      if lhs.edges[key] != rhs.edges[key] { return false }
    }
    
    if lhs.reverseEdges.count != rhs.reverseEdges.count { return false }
    for key in lhs.reverseEdges.keys {
      if lhs.reverseEdges[key] != rhs.reverseEdges[key] { return false }
    }
    return true
  }

  public static func == (lhs: PDG, rhs: PDG) -> Bool {

    return lhs.nodes == rhs.nodes && edgesMatch(lhs, rhs) && lhs.start == rhs.start
  }
}

public enum PDGEdge: Hashable {
  case data(Node)
  case control(Node)

  public static func ==(lhs: PDGEdge, rhs: PDGEdge) -> Bool {
    switch (lhs, rhs) {
      case (.data(let lBlock), .data(let rBlock)): return lBlock == rBlock
      case (.control(let lBlock), .control(let rBlock)): return lBlock == rBlock
      default: return false
    }
  }

  public var hashValue: Int {
    switch self {
      case .data(let node): return node.hashValue << 1
      case .control(let node): return (node.hashValue << 1) + 1
    }
  }
}

/// Find the data dependents of a given node in a given CFG
/// Performs a BFS for each definition in the given node
/// Complexity: O(|E|d)
/// where |E| is the number of edges in the CFG,
/// d is the number of definitions in the given node
public func findDataDependents(of startPoint: Node, inCFG cfg: CompleteCFG) -> Set<Node> {
  var dependents = Set<Node>()

  for definitionUSR in startPoint.definitions {
    let ddSearchStart = NSDate().timeIntervalSince1970
    var expansionQueue = Queue<Node>()
    var visitedNodes = Set<Node>()

    for nextNode in cfg.edges[startPoint] ?? [] {
      expansionQueue.enqueue(nextNode)
    }

    while let currentNode = expansionQueue.dequeue() {
      visitedNodes.insert(currentNode)

      // If I reference the definition, add me to the dependents
      if currentNode.references.contains(definitionUSR) {
        dependents.insert(currentNode)
      }

      // If I redefine the definition, do not visit my children
      guard !currentNode.definitions.contains(definitionUSR) else { continue }

      // Enqueue all my children that haven't been seen already
      for nextNode in cfg.edges[currentNode] ?? [] {
        if !visitedNodes.contains(nextNode) {
          expansionQueue.enqueue(nextNode)
        }
      }
    }
    let ddSearchDuration = NSDate().timeIntervalSince1970 - ddSearchStart
    print("DD search completed in: \(ddSearchDuration)")
  }

  return dependents
}

public func backwardPostOrderNumbering(cfg: CompleteCFG) -> (forward: [Int: Node], inverse: [Node: Int]) {
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

  var forwardMapping: [Int: Node] = [:]
  var inverseMapping: [Node: Int] = [:]
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
public func buildImmediatePostdominatorTree(cfg: CompleteCFG) -> [Node: Node] {
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
      let successorsWithPostdominators = cfg.edges[node]!.compactMap { successor -> Int? in
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

  var resultTree: [Node: Node] = [:]
  for (nodeIndex, immediatePostdominatorIndex) in postdominator {
    resultTree[numbering[nodeIndex]!] = numbering[immediatePostdominatorIndex]! 
  }
  return resultTree
}

/// Returns the set of nodes including the source and sink along the path from source to sink
/// If the given sink is not in the path from source to the end node, then return the path to the end node
/// Since this is a tree, this path is unique
private func path(from source: Node, to sink: Node, inPostDominatorTree postdominatorTree: [Node: Node]) -> Set<Node> {
  var includedNodes: Set<Node> = [source]
  var prevNode = source
  while let nextNode = postdominatorTree[prevNode], nextNode != prevNode, prevNode != sink {
    includedNodes.insert(nextNode)
    prevNode = nextNode
  }
  return includedNodes
}

public func findControlDependents(of startPoint: Node, inCFG cfg: CompleteCFG, withPostdominatorTree postdominatorTree: [Node: Node]) -> Set<Node> {
  let immediatePostdominator = postdominatorTree[startPoint]!
  let childPostdominators = cfg.edges[startPoint]!.map { child in
    path(from: child, to: immediatePostdominator, inPostDominatorTree: postdominatorTree)
  }
  let allPostdominators: Set<Node> = childPostdominators.reduce([], { $0.union($1) })
  let commonPostdominators: Set<Node> = childPostdominators.reduce(childPostdominators.first ?? [], { $0.intersection($1) })

  return allPostdominators.subtracting(commonPostdominators)
}
