import XCTest
import Source
@testable import CaramelFramework

class FlowPostdominanceTests: XCTestCase {
  func testLinearPostDominance() {
    let linearPostDominancePath = "Resources/FlowPostdominanceTests/linearPostdominance.swift"
    let identifier = FileManager.default.currentDirectoryPath + "/" + linearPostDominancePath

    let xZero = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 1, column: 1),
        end: SourceLocation(identifier: identifier, line: 1, column: 10)
      ),
      type: .expression
    )

    let xOne = BasicBlock(
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

    let printX = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 3, column: 1),
        end: SourceLocation(identifier: identifier, line: 3, column: 9)
      ),
      type: .expression
    )

    let completeCFG = try! CompleteCFG(cfg: CFG(
      nodes: [xZero, xOne, printX],
      edges: [
        xZero: [.basicBlock(xOne)],
        xOne: [.basicBlock(printX)],
        printX: [.passiveNext]
      ],
      entryPoint: .basicBlock(xZero)
    ))

    let postDominatorTree = buildImmediatePostdominatorTree(cfg: completeCFG)
    XCTAssertEqual(postDominatorTree[completeCFG.start], xZero)
    XCTAssertEqual(postDominatorTree[xZero], xOne)
    XCTAssertEqual(postDominatorTree[xOne], printX)
    XCTAssertEqual(postDominatorTree[printX], completeCFG.end)
  }

  func testIfPostDominance() {
    let ifPostDominancePath = "Resources/FlowPostdominanceTests/linearPostdominance.swift"
    let identifier = FileManager.default.currentDirectoryPath + "/" + ifPostDominancePath

    let xZero = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 1, column: 1),
        end: SourceLocation(identifier: identifier, line: 1, column: 10)
      ),
      type: .expression
    )

    let ifCond = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 2, column: 4),
        end: SourceLocation(identifier: identifier, line: 2, column: 9)
      ),
      type: .condition
    )

    let printX = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 3, column: 3),
        end: SourceLocation(identifier: identifier, line: 3, column: 11)
      ),
      type: .expression
    )

    let printThing = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 4, column: 3),
        end: SourceLocation(identifier: identifier, line: 4, column: 17)
      ),
      type: .expression
    )

    let xThree = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 6, column: 3),
        end: SourceLocation(identifier: identifier, line: 6, column: 8)
      ),
      type: .expression
    )

    let printDone = BasicBlock(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 8, column: 1),
        end: SourceLocation(identifier: identifier, line: 8, column: 14)
      ),
      type: .expression
    )

    let completeCFG = try! CompleteCFG(cfg: CFG(
      nodes: [xZero, ifCond, printX, printThing, xThree, printDone],
      edges: [
        xZero: [.basicBlock(ifCond)],
        ifCond: [.basicBlock(printX), .basicBlock(xThree)],
        printX: [.basicBlock(printThing)],
        printThing: [.basicBlock(printDone)],
        xThree: [.basicBlock(printDone)],
        printDone: [.passiveNext]
      ],
      entryPoint: .basicBlock(xZero)
    ))

    let postdominatorTree = buildImmediatePostdominatorTree(cfg: completeCFG)
    XCTAssertEqual(postdominatorTree[completeCFG.start], xZero)
    XCTAssertEqual(postdominatorTree[xZero], ifCond)
    XCTAssertEqual(postdominatorTree[ifCond], printDone)
    XCTAssertEqual(postdominatorTree[printX], printThing)
    XCTAssertEqual(postdominatorTree[printThing], printDone)
    XCTAssertEqual(postdominatorTree[xThree], printDone)
    XCTAssertEqual(postdominatorTree[printDone], completeCFG.end)

    // MARK: Test control dependence
    XCTAssertEqual(findControlDependents(of: completeCFG.start, inCFG: completeCFG, withPostdominatorTree: postdominatorTree), [])
    XCTAssertEqual(findControlDependents(of: xZero, inCFG: completeCFG, withPostdominatorTree: postdominatorTree), [])
    XCTAssertEqual(findControlDependents(of: ifCond, inCFG: completeCFG, withPostdominatorTree: postdominatorTree), [printX, printThing, xThree])
    XCTAssertEqual(findControlDependents(of: printX, inCFG: completeCFG, withPostdominatorTree: postdominatorTree), [])
    XCTAssertEqual(findControlDependents(of: printThing, inCFG: completeCFG, withPostdominatorTree: postdominatorTree), [])
    XCTAssertEqual(findControlDependents(of: xThree, inCFG: completeCFG, withPostdominatorTree: postdominatorTree), [])
    XCTAssertEqual(findControlDependents(of: printDone, inCFG: completeCFG, withPostdominatorTree: postdominatorTree), [])
  }
}