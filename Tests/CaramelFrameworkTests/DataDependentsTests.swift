import XCTest
import Source
@testable import CaramelFramework

class DataDependentsTests: XCTestCase {
    func testNoDependents() {
      let noDependentsPath = "Resources/DataDependentsTestFiles/noDependents.swift"

      let identifier = FileManager.default.currentDirectoryPath + "/" + noDependentsPath

      let xZero = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 1),
          end: SourceLocation(identifier: identifier, line: 1, column: 10)
        ),
        type: .expression
      )

      let xTwo = BasicBlock(
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

      let xThree = BasicBlock(
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

      let completeCFG = try! CompleteCFG(cfg: CFG(
        nodes: [xZero, xTwo, xThree],
        edges: [
          xZero: [.basicBlock(xTwo)],
          xTwo: [.basicBlock(xThree)]
        ],
        entryPoint: .basicBlock(xZero)
      ))

      XCTAssertEqual(findDataDependents(of: xZero, inCFG: completeCFG), [])
      XCTAssertEqual(findDataDependents(of: xTwo, inCFG: completeCFG), [])
      XCTAssertEqual(findDataDependents(of: xThree, inCFG: completeCFG), [])
    }

    func testOverwritingIf() {
      let overwritingIfPath = "Resources/DataDependentsTestFiles/overwritingIf.swift"

      let identifier = FileManager.default.currentDirectoryPath + "/" + overwritingIfPath

      let xEmptyString = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 1),
          end: SourceLocation(identifier: identifier, line: 1, column: 11)
        ),
        type: .expression
      )

      let ifCond = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 4),
          end: SourceLocation(identifier: identifier, line: 3, column: 9)
        ),
        type: .condition
      )

      let xHello = BasicBlock(
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

      let xBonjour = BasicBlock(
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

      let printX = BasicBlock(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 9, column: 1),
          end: SourceLocation(identifier: identifier, line: 9, column: 9)
        ),
        type: .expression
      )

      let completeCFG = try! CompleteCFG(cfg: CFG(
        nodes: [xEmptyString, ifCond, xHello, xBonjour, printX],
        edges: [
          xEmptyString: [.basicBlock(ifCond)],
          ifCond: [.basicBlock(xHello), .basicBlock(xBonjour)],
          xHello: [.basicBlock(printX)],
          xBonjour: [.basicBlock(printX)],
          printX: []
        ],
        entryPoint: .basicBlock(xEmptyString)
      ))

      XCTAssertEqual(findDataDependents(of: xEmptyString, inCFG: completeCFG), [])
      XCTAssertEqual(findDataDependents(of: ifCond, inCFG: completeCFG), [])
      XCTAssertEqual(findDataDependents(of: xHello, inCFG: completeCFG), [printX])
      XCTAssertEqual(findDataDependents(of: xBonjour, inCFG: completeCFG), [printX])
      XCTAssertEqual(findDataDependents(of: printX, inCFG: completeCFG), [])
    }

    static var allTests = [
        ("testNoDependents", testNoDependents)
    ]
}
