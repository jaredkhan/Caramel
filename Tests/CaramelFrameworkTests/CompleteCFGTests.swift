import XCTest
import Source
@testable import CaramelFramework

class CompleteCFGTests: XCTestCase {
    func testSimpleGuard() {
      let startNode = BasicBlock(range: SourceRange.EMPTY, type: .start)

      let guardCond = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: "test", line: 1, column: 7),
          end: SourceLocation(identifier: "test", line: 1, column: 12)
        ),
        type: .condition
      )

      let fatalDead = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: "test", line: 1, column: 20),
          end: SourceLocation(identifier: "test", line: 1, column: 38)
        ),
        type: .expression
      )

      let endNode = BasicBlock(range: SourceRange.EMPTY, type: .end)

      let nodes = Set([
        startNode,
        guardCond,
        fatalDead,
        endNode
      ])

      let edges: [BasicBlock: Set<BasicBlock>] = [
        startNode: [guardCond],
        guardCond: [fatalDead, endNode],
        fatalDead: [endNode],
        endNode: []
      ]

      let reverseEdges: [BasicBlock: Set<BasicBlock>] = [
        startNode: [],
        guardCond: [startNode],
        fatalDead: [guardCond],
        endNode: [guardCond, fatalDead]
      ]

      let completeCFG = try! CompleteCFG(cfg: CFG(
        nodes: [guardCond, fatalDead],
        edges: [
          guardCond: [.basicBlock(fatalDead), .passiveNext],
          fatalDead: [],
        ],
        entryPoint: .basicBlock(guardCond)
      ))

      let expectedCompleteCFG = CompleteCFG(
        nodes: nodes,
        edges: edges,
        reverseEdges: reverseEdges,
        start: startNode,
        end: endNode
      )

      if completeCFG != expectedCompleteCFG {
        print("\n\nFOUND:\n")
        dump(completeCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCompleteCFG)
      } 

      XCTAssertEqual(completeCFG, expectedCompleteCFG)
    }

    static var allTests = [
        ("testSimpleGuard", testSimpleGuard)
    ]
}
