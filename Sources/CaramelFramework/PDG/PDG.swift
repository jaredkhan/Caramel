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
    let nodes = cfg.nodes.filter {
      // Nothing is control or data dependent on the END node, do not include it
      $0 != cfg.end
    }

    let controlDeps = controlDependencyEdges(cfg: cfg)
    let dataDeps = dataDependencyEdges(cfg: cfg)
    let edges = controlDeps.forward.merging(dataDeps.forward) { $0.union($1) }
    let reverseEdges = controlDeps.reverse.merging(dataDeps.reverse) { $0.union($1) }
    
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
