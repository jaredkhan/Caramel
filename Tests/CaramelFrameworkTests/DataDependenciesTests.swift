import XCTest
import Source
@testable import CaramelFramework

class DataDependenciesTests: XCTestCase {
    func testNoDependencies() {
      let noDependentsPath = "Resources/DataDependentsTestFiles/noDependents.swift"

      let identifier = FileManager.default.currentDirectoryPath + "/" + noDependentsPath

      let xZero = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 1),
          end: SourceLocation(identifier: identifier, line: 1, column: 10)
        ),
        type: .expression
      )

      let xTwo = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 1),
          end: SourceLocation(identifier: identifier, line: 2, column: 6)
        ),
        type: .expression,
        defRange: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 1),
          end: SourceLocation(identifier: identifier, line: 2, column: 2)
        )
      )

      let xThree = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 1),
          end: SourceLocation(identifier: identifier, line: 3, column: 6)
        ),
        type: .expression,
        defRange: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 1),
          end: SourceLocation(identifier: identifier, line: 3, column: 2)
        )
      )

      let completeCFG = try! CompleteCFG(cfg: PartialCFG(
        nodes: [xZero, xTwo, xThree],
        edges: [
          xZero: [.node(xTwo)],
          xTwo: [.node(xThree)]
        ],
        entryPoint: .node(xZero)
      ))

      let dataDepEdges = dataDependencyEdges(cfg: completeCFG)

      XCTAssertEqual(dataDepEdges.reverse[xZero], [])
      XCTAssertEqual(dataDepEdges.reverse[xTwo], [])
      XCTAssertEqual(dataDepEdges.reverse[xThree], [])
    }

    func testOverwritingIf() {
      let overwritingIfPath = "Resources/DataDependentsTestFiles/overwritingIf.swift"

      let identifier = FileManager.default.currentDirectoryPath + "/" + overwritingIfPath

      let xEmptyString = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 1),
          end: SourceLocation(identifier: identifier, line: 1, column: 11)
        ),
        type: .expression
      )

      let ifCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 4),
          end: SourceLocation(identifier: identifier, line: 3, column: 9)
        ),
        type: .condition
      )

      let xHello = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 4, column: 3),
          end: SourceLocation(identifier: identifier, line: 4, column: 14)
        ),
        type: .expression,
        defRange: SourceRange(
          start: SourceLocation(identifier: identifier, line: 4, column: 3),
          end: SourceLocation(identifier: identifier, line: 4, column: 4)
        )
      )

      let xBonjour = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 6, column: 3),
          end: SourceLocation(identifier: identifier, line: 6, column: 16)
        ),
        type: .expression,
        defRange: SourceRange(
          start: SourceLocation(identifier: identifier, line: 6, column: 3),
          end: SourceLocation(identifier: identifier, line: 6, column: 4)
        )
      )

      let printX = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 9, column: 1),
          end: SourceLocation(identifier: identifier, line: 9, column: 9)
        ),
        type: .expression
      )

      let completeCFG = try! CompleteCFG(cfg: PartialCFG(
        nodes: [xEmptyString, ifCond, xHello, xBonjour, printX],
        edges: [
          xEmptyString: [.node(ifCond)],
          ifCond: [.node(xHello), .node(xBonjour)],
          xHello: [.node(printX)],
          xBonjour: [.node(printX)],
          printX: []
        ],
        entryPoint: .node(xEmptyString)
      ))

      let dataDepEdges = dataDependencyEdges(cfg: completeCFG)

      XCTAssertEqual(dataDepEdges.forward[xEmptyString], [])
      XCTAssertEqual(dataDepEdges.forward[ifCond], [])
      XCTAssertEqual(dataDepEdges.forward[xHello], [.data(printX)])
      XCTAssertEqual(dataDepEdges.forward[xBonjour], [.data(printX)])
      XCTAssertEqual(dataDepEdges.forward[printX], [])
    }

    static var allTests = [
        ("testNoDependencies", testNoDependencies)
    ]
}
