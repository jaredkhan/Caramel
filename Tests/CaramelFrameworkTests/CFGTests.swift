import XCTest
import Source
@testable import CaramelFramework

class CFGTests: XCTestCase {
    func testSimpleIf() {
      // Get path
      let simpleIfPath = "Resources/simpleIf.swift"

      let foundCFG = CFG(contentsOfFile: simpleIfPath)

      let identifier = FileManager.default.currentDirectoryPath + "/" + simpleIfPath

      print(identifier)

      // Get contents
      let string = try! String(contentsOfFile: simpleIfPath, encoding: .utf8)
      dump(string)

      let startNode = BasicBlock(range: SourceRange.EMPTY, type: .start)
      let xAssignment = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 1),
          end: SourceLocation(identifier: identifier, line: 1, column: 10)
        ),
        type: .expression
      )
      let ifCond = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 4),
          end: SourceLocation(identifier: identifier, line: 2, column: 11)
        ),
        type: .ifCondition
      )
      let printHello = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 3),
          end: SourceLocation(identifier: identifier, line: 3, column: 17)
        ), 
        type: .expression
      )
      let printGoodbye = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 5, column: 3),
          end: SourceLocation(identifier: identifier, line: 5, column: 19)
        ),
        type: .expression
      )

      let nodes = Set([startNode, xAssignment, ifCond, printHello, printGoodbye])

      let edges: [BasicBlock: Set<NextBlock>] = [
        startNode: [.basicBlock(xAssignment)],
        xAssignment: [.basicBlock(ifCond)],
        ifCond: [.basicBlock(printHello), .basicBlock(printGoodbye)],
        printHello: [.passiveNext],
        printGoodbye: [.passiveNext]
      ]

      let expectedCFG = CFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .basicBlock(startNode)
      )

      print("\n\nFOUND:\n")
      dump(foundCFG)
      print("\n\nEXPECTED:\n")
      dump(expectedCFG)

      XCTAssertEqual(foundCFG, expectedCFG)
    }

    static var allTests = [
        ("testSimpleIf", testSimpleIf)
    ]
}
