import Foundation

var refDefRetrievalTime: TimeInterval = 0

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

    let refDefStartTime = NSDate().timeIntervalSince1970
    for node in cfg.nodes {
      _ = node.definitions
      _ = node.references
    }
    refDefRetrievalTime = NSDate().timeIntervalSince1970 - refDefStartTime
    print("Ref def time: \(refDefRetrievalTime)")

    let ordering = flowOrdering(ofCFG: cfg, withPostdominatorTree: postdominatorTree)

    let rdStartTime = NSDate().timeIntervalSince1970
    let reachingDefinitions = findReachingDefinitions(inCFG: cfg, nodeOrdering: ordering)
    let rdDuration = NSDate().timeIntervalSince1970 - rdStartTime
    print("Found reaching defs in: \(rdDuration)")

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

      // let dataDependents = findDataDependents(of: node, inCFG: cfg)
      let dataDependencies = findDataDependencies(of: node, inCFG: cfg, withReachingDefinitions: reachingDefinitions)

      for dataDependency in dataDependencies {
        edges[dataDependency]!.insert(.data(node))
        reverseEdges[node]!.insert(.data(dataDependency))
      }

      // for dataDependent in dataDependents {
      //   edges[node]!.insert(.data(dataDependent))
      //   reverseEdges[dataDependent]!.insert(.data(node))
      // }

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

public enum PDGEdge: Equatable, Hashable {
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

private struct Definition: Hashable {
  let usr: USR
  let node: Node
}

/// Returns a node ordering that makes sure each node between a node A and it's immediate postdominator B is ordered between A and B
private func flowOrdering(ofCFG cfg: CompleteCFG, withPostdominatorTree postdominatorTree: [Node: Node]) -> NodeOrdering {
  var visitedNodes: Set<Node> = []
  func boundedWalk(from startNode: Node, upTo endNode: Node) -> [Node] {
    if startNode == endNode { return [] }
    // assert that endNode is reachable from start node
    visitedNodes.insert(startNode)
    let children = cfg.edges[startNode] ?? []
    let ipdom = postdominatorTree[startNode]!
    return [startNode] + children.filter { !visitedNodes.contains($0) }.map { boundedWalk(from: $0, upTo: ipdom) }.reduce([],+) + boundedWalk(from: ipdom, upTo: endNode)
  }
  return NodeOrdering(array: boundedWalk(from: cfg.start, upTo: cfg.end))
}

/// Worklist algorithm
private func findReachingDefinitions(inCFG cfg: CompleteCFG, nodeOrdering: NodeOrdering) -> [Node: Set<Definition>] {
  var changedNodes = Set(cfg.nodes)
  var gen: [Node: Set<Definition>] = [:]

  var reachOut: [Node: Set<Definition>] = [:]
  var reachIn: [Node: Set<Definition>] = [:]
  for node in cfg.nodes {
    gen[node] = Set(node.definitions.map { usr in
      Definition(usr: usr, node: node)
    })
    reachOut[node] = gen[node]!
    reachIn[node] = []
  }

  var findTime: TimeInterval = 0
  var findStartTime = NSDate().timeIntervalSince1970

  while let node = changedNodes.first(where: { changedNodes.contains($0) }) {
    findTime += NSDate().timeIntervalSince1970 - findStartTime
    changedNodes.remove(node)

    let predecessors = cfg.reverseEdges[node] ?? []
    let currentReachIn: Set<Definition> = predecessors.reduce([], { acc, predecessor in
      acc.union(reachOut[predecessor]!)
    })

    let oldOut = reachOut[node]!
    
    let killed = currentReachIn.filter { node.definitions.contains($0.usr) }
    reachOut[node] = currentReachIn.subtracting(killed).union(gen[node]!)

    if reachOut[node] != oldOut {
      changedNodes.formUnion(cfg.edges[node]!)
    }

    reachIn[node] = currentReachIn
    findStartTime = NSDate().timeIntervalSince1970
  }
  findTime += NSDate().timeIntervalSince1970 - findStartTime
  print("Found next nodes in: \(findTime)")

  return reachIn
}

private func findDataDependencies(of node: Node, inCFG cfg: CompleteCFG, withReachingDefinitions reachingDefinitions: [Node: Set<Definition>]) -> Set<Node> {
  return Set(reachingDefinitions[node]!.filter { definition in
    node.references.contains(definition.usr)
  }.map { definition in definition.node })
}

// /// Find the data dependents of a given node in a given CFG
// /// Performs a BFS for each definition in the given node
// /// Complexity: O(|E|d)
// /// where |E| is the number of edges in the CFG,
// /// d is the number of definitions in the given node
// public func findDataDependents(of startPoint: Node, inCFG cfg: CompleteCFG) -> Set<Node> {
//   var dependents = Set<Node>()
//   var enqueueCount = 0

//   let defTimeStart = NSDate().timeIntervalSince1970
//   let definitions = startPoint.definitions
//   refDefRetrievalTime += NSDate().timeIntervalSince1970 - defTimeStart

//   for definitionUSR in definitions {
//     let ddSearchStart = NSDate().timeIntervalSince1970
//     var expansionQueue = Queue<Node>()
//     var visitedNodes = Set<Node>()

//     for nextNode in cfg.edges[startPoint] ?? [] {
//       expansionQueue.enqueue(nextNode)
//     }

//     while let currentNode = expansionQueue.dequeue() {
//       visitedNodes.insert(currentNode)

//       let refTimeStart = NSDate().timeIntervalSince1970
//       let references = currentNode.references
//       refDefRetrievalTime += NSDate().timeIntervalSince1970 - refTimeStart

//       // If I reference the definition, add me to the dependents
//       if references.contains(definitionUSR) {
//         dependents.insert(currentNode)
//       }

//       let innerDefStartTime = NSDate().timeIntervalSince1970
//       let innerDefinitions = currentNode.definitions
//       refDefRetrievalTime += NSDate().timeIntervalSince1970 - innerDefStartTime

//       // If I redefine the definition, do not visit my children
//       guard !innerDefinitions.contains(definitionUSR) else { continue }

//       // Enqueue all my children that haven't been seen already
//       for nextNode in cfg.edges[currentNode] ?? [] {
//         if !visitedNodes.contains(nextNode) {
//           expansionQueue.enqueue(nextNode)
//           enqueueCount += 1
//         }
//       }
//     }
//     let ddSearchDuration = NSDate().timeIntervalSince1970 - ddSearchStart
//     print("DD search completed in: \(ddSearchDuration)")
//     print("DD search enqueued: \(enqueueCount)")
//   }

//   return dependents
// }

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
