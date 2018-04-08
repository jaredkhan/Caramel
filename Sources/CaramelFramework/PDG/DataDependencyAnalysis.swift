import Foundation

/// Get only the data dependency edges for this CFG
func dataDependencyEdges(cfg: CompleteCFG) -> (forward: [Node: Set<PDGEdge>], reverse: [Node: Set<PDGEdge>]) {
  var edges: [Node: Set<PDGEdge>] = [:]
  var reverseEdges: [Node: Set<PDGEdge>] = [:]

  // Initialise edge and reverseEdge sets to be empty
  for node in cfg.nodes {
    guard node != cfg.end else { continue }
    edges[node] = []
    reverseEdges[node] = []
  }

  // Cache the references and definitions
  let refDefStartTime = NSDate().timeIntervalSince1970
  for node in cfg.nodes {
    _ = node.definitions
    _ = node.references
  }
  let refDefDuration = NSDate().timeIntervalSince1970 - refDefStartTime
  print("Ref def time: \(refDefDuration)")

  for node in cfg.nodes {
    let dataDependencies = findDataDependencies(of: node, inCFG: cfg)

    for dataDependency in dataDependencies {
      edges[dataDependency]!.insert(.data(node))
      reverseEdges[node]!.insert(.data(dataDependency))
    }
  }

  return (forward: edges, reverse: reverseEdges)
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
  var result = boundedWalk(from: cfg.start, upTo: cfg.end)
  result.append(cfg.end)
  return NodeOrdering(array: result)
}

/// Worklist algorithm
private func findReachingDefinitions(inCFG cfg: CompleteCFG, nodeOrdering: NodeOrdering) -> [Node: Set<Definition>] {
  let queueStartTime = NSDate().timeIntervalSince1970
  var changedNodes = nodeOrdering.priorityQueue
  let queueBuildTime = NSDate().timeIntervalSince1970 - queueStartTime
  print("Queue built in: \(queueBuildTime)")

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

  while let node = changedNodes.pop() {
    findTime += NSDate().timeIntervalSince1970 - findStartTime

    let predecessors = cfg.reverseEdges[node] ?? []
    let currentReachIn: Set<Definition> = predecessors.reduce([], { acc, predecessor in
      acc.union(reachOut[predecessor]!)
    })

    let oldOut = reachOut[node]!
    
    let killed = currentReachIn.filter { node.definitions.contains($0.usr) }
    reachOut[node] = currentReachIn.subtracting(killed).union(gen[node]!)

    findStartTime = NSDate().timeIntervalSince1970
    if reachOut[node] != oldOut {
      for child in cfg.edges[node]! {
        changedNodes.push(child)
      }
    }

    reachIn[node] = currentReachIn
  }
  findTime += NSDate().timeIntervalSince1970 - findStartTime
  print("Found next nodes in: \(findTime)")

  return reachIn
}

private func findDataDependencies(of node: Node, inCFG cfg: CompleteCFG) -> Set<Node> {
  let postdominatorTree = buildImmediatePostdominatorTree(cfg: cfg)
  let ordering = flowOrdering(ofCFG: cfg, withPostdominatorTree: postdominatorTree)
  let reachingDefinitions = findReachingDefinitions(inCFG: cfg, nodeOrdering: ordering)
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