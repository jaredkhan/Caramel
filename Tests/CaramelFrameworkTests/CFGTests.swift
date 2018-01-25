import XCTest
@testable import CaramelFramework

class CFGTests: XCTestCase {
    func testSimpleIf() {
      // Get path
      let simpleIfPath = "Resources/simpleIf.swift"

      let foundCFG = CFG(contentsOfFile: simpleIfPath)

      // Get contents
      let string = try! String(contentsOfFile: simpleIfPath, encoding: .utf8)
      dump(string)

      let startNode = BasicBlock(offset: 0, length: 0, type: .start)
      let xAssignment = BasicBlock(offset: 0, length: 9, type: .expression)
      let ifCond = BasicBlock(offset: 14, length: 5, type: .ifCondition)
      let printHello = BasicBlock(offset: 25, length: 16, type: .expression)
      let printGoodbye = BasicBlock(offset: 53, length: 18, type: .expression)

      let nodes = [startNode, xAssignment, ifCond, printHello, printGoodbye]

      let edges: [BasicBlock: [NextBlock]] = [
        startNode: [.basicBlock(xAssignment)],
        xAssignment: [.basicBlock(ifCond)],
        ifCond: [.basicBlock(printHello), .basicBlock(printGoodbye)],
        printHello: [.passiveNext],
        printGoodbye: [.passiveNext]
      ]

      let expectedCFG = CFG(
        nodes: nodes,
        edges: edges,
        entryPoint: startNode
      )

      XCTAssertEqual(foundCFG, expectedCFG)
    }

    static var allTests = [
        ("testSimpleIf", testSimpleIf)
    ]
}
