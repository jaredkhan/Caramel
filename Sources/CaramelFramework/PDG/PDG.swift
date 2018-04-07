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
