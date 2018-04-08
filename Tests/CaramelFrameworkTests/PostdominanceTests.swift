import XCTest
import Source
@testable import CaramelFramework

class PostdominanceTests: XCTestCase {
  func testLinearPostDominance() {
    let linearPostDominancePath = "Resources/FlowPostdominanceTests/linearPostdominance.swift"
    let identifier = FileManager.default.currentDirectoryPath + "/" + linearPostDominancePath

    let xZero = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 1, column: 1),
        end: SourceLocation(identifier: identifier, line: 1, column: 10)
      ),
      type: .expression
    )

    let xOne = Node(
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

    let printX = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 3, column: 1),
        end: SourceLocation(identifier: identifier, line: 3, column: 9)
      ),
      type: .expression
    )

    let completeCFG = try! CompleteCFG(cfg: PartialCFG(
      nodes: [xZero, xOne, printX],
      edges: [
        xZero: [.node(xOne)],
        xOne: [.node(printX)],
        printX: [.passiveNext]
      ],
      entryPoint: .node(xZero)
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

    let xZero = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 1, column: 1),
        end: SourceLocation(identifier: identifier, line: 1, column: 10)
      ),
      type: .expression
    )

    let ifCond = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 2, column: 4),
        end: SourceLocation(identifier: identifier, line: 2, column: 9)
      ),
      type: .condition
    )

    let printX = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 3, column: 3),
        end: SourceLocation(identifier: identifier, line: 3, column: 11)
      ),
      type: .expression
    )

    let printThing = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 4, column: 3),
        end: SourceLocation(identifier: identifier, line: 4, column: 17)
      ),
      type: .expression
    )

    let xThree = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 6, column: 3),
        end: SourceLocation(identifier: identifier, line: 6, column: 8)
      ),
      type: .expression
    )

    let printDone = Node(
      range: SourceRange(
        start: SourceLocation(identifier: identifier, line: 8, column: 1),
        end: SourceLocation(identifier: identifier, line: 8, column: 14)
      ),
      type: .expression
    )

    let completeCFG = try! CompleteCFG(cfg: PartialCFG(
      nodes: [xZero, ifCond, printX, printThing, xThree, printDone],
      edges: [
        xZero: [.node(ifCond)],
        ifCond: [.node(printX), .node(xThree)],
        printX: [.node(printThing)],
        printThing: [.node(printDone)],
        xThree: [.node(printDone)],
        printDone: [.passiveNext]
      ],
      entryPoint: .node(xZero)
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
