import XCTest
import Source
@testable import CaramelFramework

class PartialCFGTests: XCTestCase {
    func testSimpleIf() {
      // Get path
      let simpleIfPath = "Resources/CFGTestFiles/simpleIf.swift"

      let foundCFG = PartialCFG(contentsOfFile: simpleIfPath)

      let identifier = FileManager.default.currentDirectoryPath + "/" + simpleIfPath

      let xAssignment = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 1),
          end: SourceLocation(identifier: identifier, line: 1, column: 10)
        ),
        type: .expression
      )
      let ifCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 4),
          end: SourceLocation(identifier: identifier, line: 2, column: 11)
        ),
        type: .condition
      )
      let printHello = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 3),
          end: SourceLocation(identifier: identifier, line: 3, column: 17)
        ), 
        type: .expression
      )
      let printGoodbye = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 5, column: 3),
          end: SourceLocation(identifier: identifier, line: 5, column: 19)
        ),
        type: .expression
      )

      let nodes = Set([xAssignment, ifCond, printHello, printGoodbye])

      let edges: [Node: Set<NextNode>] = [
        xAssignment: [.node(ifCond)],
        ifCond: [.node(printHello), .node(printGoodbye)],
        printHello: [.passiveNext],
        printGoodbye: [.passiveNext]
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(xAssignment)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      }

      XCTAssertEqual(foundCFG, expectedCFG)

      XCTAssertEqual(xAssignment.definitions, ["s:8simpleIf1xSiv"])
      XCTAssertEqual(ifCond.definitions, [])
      XCTAssertEqual(printHello.definitions, [])
      XCTAssertEqual(printGoodbye.definitions, [])

      XCTAssertEqual(xAssignment.references, [])
      XCTAssertEqual(ifCond.references, ["s:8simpleIf1xSiv"])
      XCTAssertEqual(printHello.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
      XCTAssertEqual(printGoodbye.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
    }

    func testBreakFor() {
      let filePath = "Resources/CFGTestFiles/breakFor.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let threeArray = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 10),
          end: SourceLocation(identifier: identifier, line: 1, column: 19)
        ),
        type: .expression
      )

      let forX1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 5),
          end: SourceLocation(identifier: identifier, line: 1, column: 6)
        ),
        type: .pattern
      )

      let printX = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 3),
          end: SourceLocation(identifier: identifier, line: 2, column: 11)
        ),
        type: .expression
      )

      let break1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 3),
          end: SourceLocation(identifier: identifier, line: 3, column: 8)
        ),
        type: .breakStatement
      )

      let nodes = Set([
        threeArray,
        forX1,
        printX,
        break1
      ])

      let edges: [Node: Set<NextNode>] = [
        threeArray: [.node(forX1)],
        forX1: [.node(printX), .passiveNext],
        printX: [.node(break1)],
        break1: [.passiveNext]
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(threeArray)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)

      XCTAssertEqual(threeArray.definitions, []) 
      XCTAssertEqual(forX1.definitions, ["s:8breakFor1xL_Siv"]) 
      XCTAssertEqual(printX.definitions, []) 
      XCTAssertEqual(break1.definitions, []) 

      XCTAssertEqual(threeArray.references, [])
      XCTAssertEqual(forX1.references, [])
      XCTAssertEqual(printX.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF", "s:8breakFor1xL_Siv"])
      XCTAssertEqual(break1.references, [])
    }

    func testBreakWhile() {
      let filePath = "Resources/CFGTestFiles/breakWhile.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let falseWhileCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 7),
          end: SourceLocation(identifier: identifier, line: 1, column: 12)
        ),
        type: .condition
      )

      let break2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 3),
          end: SourceLocation(identifier: identifier, line: 2, column: 8)
        ),
        type: .breakStatement
      )

      let nodes = Set([
        falseWhileCond,
        break2
      ])

      let edges: [Node: Set<NextNode>] = [
        falseWhileCond: [.node(break2), .passiveNext],
        break2: [.passiveNext]
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(falseWhileCond)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)

      XCTAssertEqual(falseWhileCond.definitions, [])
      XCTAssertEqual(break2.definitions, [])

      XCTAssertEqual(falseWhileCond.references, [])
      XCTAssertEqual(break2.references, [])
    }

    func testContinueFor() {
      let filePath = "Resources/CFGTestFiles/continueFor.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let threeRange = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 10),
          end: SourceLocation(identifier: identifier, line: 1, column: 17)
        ),
        type: .expression
      )

      let forX2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 5),
          end: SourceLocation(identifier: identifier, line: 1, column: 6)
        ),
        type: .pattern
      )

      let continue1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 3),
          end: SourceLocation(identifier: identifier, line: 2, column: 11)
        ),
        type: .continueStatement
      )

      let nodes = Set([
        threeRange,
        forX2,
        continue1
      ])

      let edges: [Node: Set<NextNode>] = [
        threeRange: [.node(forX2)],
        forX2: [.node(continue1), .passiveNext],
        continue1: [.node(forX2)],
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(threeRange)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)

      XCTAssertEqual(threeRange.definitions, []) 
      XCTAssertEqual(forX2.definitions, ["s:11continueFor1xL_Siv"]) 
      XCTAssertEqual(continue1.definitions, []) 

      XCTAssertEqual(threeRange.references, []) 
      XCTAssertEqual(forX2.references, []) 
      XCTAssertEqual(continue1.references, []) 
    }

    func testContinueWhile() {
      let filePath = "Resources/CFGTestFiles/continueWhile.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let oneGreaterThanTwo = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 7),
          end: SourceLocation(identifier: identifier, line: 1, column: 12)
        ),
        type: .condition
      )

      let continue2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 3),
          end: SourceLocation(identifier: identifier, line: 2, column: 11)
        ),
        type: .continueStatement
      )

      let nodes = Set([
        oneGreaterThanTwo,
        continue2,
      ])

      let edges: [Node: Set<NextNode>] = [
        oneGreaterThanTwo: [.node(continue2), .passiveNext],
        continue2: [.node(oneGreaterThanTwo)]
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(oneGreaterThanTwo)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)

      XCTAssertEqual(oneGreaterThanTwo.definitions, [])
      XCTAssertEqual(continue2.definitions, [])

      XCTAssertEqual(oneGreaterThanTwo.references, [])
      XCTAssertEqual(continue2.references, [])
    }

    func testSimpleGuard() {
      let filePath = "Resources/CFGTestFiles/simpleGuard.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let guardCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 7),
          end: SourceLocation(identifier: identifier, line: 1, column: 12)
        ),
        type: .condition
      )

      let fatalDead = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 20),
          end: SourceLocation(identifier: identifier, line: 1, column: 38)
        ),
        type: .expression
      )

      let nodes = Set([
        guardCond,
        fatalDead,
      ])

      let edges: [Node: Set<NextNode>] = [
        guardCond: [.passiveNext, .node(fatalDead)],
        fatalDead: [],
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(guardCond)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)

      XCTAssertEqual(guardCond.definitions, [])
      XCTAssertEqual(fatalDead.definitions, [])

      XCTAssertEqual(guardCond.references, [])
      XCTAssertEqual(fatalDead.references, ["s:s10fatalErrors5NeverOSSyXK_s12StaticStringV4fileSu4linetF"])
    }

    func testSimpleSwitch() {
      let filePath = "Resources/CFGTestFiles/simpleSwitch.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let switchSubject = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 8),
          end: SourceLocation(identifier: identifier, line: 1, column: 9)
        ),
        type: .expression
      )

      let case1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 8),
          end: SourceLocation(identifier: identifier, line: 2, column: 9)
        ),
        type: .pattern
      )

      let case2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 11),
          end: SourceLocation(identifier: identifier, line: 2, column: 12)
        ),
        type: .pattern
      )

      let printOne = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 5),
          end: SourceLocation(identifier: identifier, line: 3, column: 18)
        ),
        type: .expression
      )

      let fallthroughStmt = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 4, column: 5),
          end: SourceLocation(identifier: identifier, line: 4, column: 16)
        ),
        type: .fallthroughStatement
      )

      let case3 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 5, column: 8),
          end: SourceLocation(identifier: identifier, line: 5, column: 9)
        ),
        type: .pattern
      )

      let break4 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 6, column: 5),
          end: SourceLocation(identifier: identifier, line: 6, column: 10)
        ),
        type: .breakStatement
      )

      let printNope = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 7, column: 12),
          end: SourceLocation(identifier: identifier, line: 7, column: 25)
        ),
        type: .expression
      )

      let nodes = Set([
        switchSubject,
        case1,
        case2,
        printOne,
        fallthroughStmt,
        case3,
        break4,
        printNope
      ])

      let edges: [Node: Set<NextNode>] = [
        switchSubject: [.node(case1)],
        case1: [.node(printOne), .node(case2)],
        case2: [.node(printOne), .node(case3)],
        printOne: [.node(fallthroughStmt)],
        fallthroughStmt: [.node(break4)],
        case3: [.node(break4), .node(printNope)],
        break4: [.passiveNext],
        printNope: [.passiveNext]
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(switchSubject)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)
    }

    func testRepeatWhileNest() {
      let filePath = "Resources/CFGTestFiles/repeatWhileNest.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let printHi = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 2, column: 3),
          end: SourceLocation(identifier: identifier, line: 2, column: 14)
        ),
        type: .expression
      )

      let trueIfCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 6),
          end: SourceLocation(identifier: identifier, line: 3, column: 10)
        ),
        type: .condition
      )

      let break3 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 13),
          end: SourceLocation(identifier: identifier, line: 3, column: 18)
        ),
        type: .breakStatement
      )

      let repeatWhileCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 4, column: 9),
          end: SourceLocation(identifier: identifier, line: 4, column: 14)
        ),
        type: .condition
      )

      let nodes = Set([
        printHi,
        trueIfCond,
        break3,
        repeatWhileCond
      ])

      let edges: [Node: Set<NextNode>] = [
        printHi: [.node(trueIfCond)],
        trueIfCond: [.node(break3), .node(repeatWhileCond)],
        break3: [.node(repeatWhileCond)],
        repeatWhileCond: [.passiveNext, .node(printHi)],
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(printHi)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)
    }

    func testAllStructures() {
      let filePath = "Resources/CFGTestFiles/allStructures.swift"
      let foundCFG = PartialCFG(contentsOfFile: filePath)
      let identifier = FileManager.default.currentDirectoryPath + "/" + filePath

      let myVarDeclaration = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 1, column: 1),
          end: SourceLocation(identifier: identifier, line: 1, column: 14)
        ),
        type: .expression
      )

      let patternConstDeclaration = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 3, column: 1),
          end: SourceLocation(identifier: identifier, line: 3, column: 34)
        ),
        type: .expression
      )

      let myVarInc = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 5, column: 1),
          end: SourceLocation(identifier: identifier, line: 5, column: 18)
        ),
        type: .expression,
        defRange: SourceRange(
          start: SourceLocation(identifier: identifier, line: 5, column: 1),
          end: SourceLocation(identifier: identifier, line: 5, column: 6)
        )
      )

      let ifCond1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 7, column: 4),
          end: SourceLocation(identifier: identifier, line: 7, column: 8)
        ),
        type: .condition
      )

      let printHello = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 8, column: 3),
          end: SourceLocation(identifier: identifier, line: 8, column: 17)
        ),
        type: .expression
      )

      let setMyVar = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 9, column: 3),
          end: SourceLocation(identifier: identifier, line: 9, column: 12)
        ),
        type: .expression,
        defRange: SourceRange(
          start: SourceLocation(identifier: identifier, line: 9, column: 3),
          end: SourceLocation(identifier: identifier, line: 9, column: 8)
        )
      )

      let xDecl = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 10, column: 3),
          end: SourceLocation(identifier: identifier, line: 10, column: 12)
        ),
        type: .expression
      )

      let ifCond2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 11, column: 11),
          end: SourceLocation(identifier: identifier, line: 11, column: 15)
        ),
        type: .condition
      )

      let printGoodbye = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 12, column: 3),
          end: SourceLocation(identifier: identifier, line: 12, column: 19)
        ),
        type: .expression
      )

      let ifCond3 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 13, column: 11),
          end: SourceLocation(identifier: identifier, line: 13, column: 15)
        ),
        type: .condition
      )

      let ifCond4 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 13, column: 17),
          end: SourceLocation(identifier: identifier, line: 13, column: 21)
        ),
        type: .condition
      )

      let ifCond5 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 13, column: 23),
          end: SourceLocation(identifier: identifier, line: 13, column: 27)
        ),
        type: .condition
      )

      let printWoah = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 14, column: 3),
          end: SourceLocation(identifier: identifier, line: 14, column: 17)
        ),
        type: .expression
      )

      let threeArray = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 17, column: 10),
          end: SourceLocation(identifier: identifier, line: 17, column: 19)
        ),
        type: .expression
      )

      let forX1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 17, column: 5),
          end: SourceLocation(identifier: identifier, line: 17, column: 6)
        ),
        type: .pattern
      )

      let printX = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 18, column: 3),
          end: SourceLocation(identifier: identifier, line: 18, column: 11)
        ),
        type: .expression
      )

      let break1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 19, column: 3),
          end: SourceLocation(identifier: identifier, line: 19, column: 8)
        ),
        type: .breakStatement
      )

      let threeRange = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 22, column: 10),
          end: SourceLocation(identifier: identifier, line: 22, column: 17)
        ),
        type: .expression
      )

      let forX2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 22, column: 5),
          end: SourceLocation(identifier: identifier, line: 22, column: 6)
        ),
        type: .pattern
      )

      let continue1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 23, column: 3),
          end: SourceLocation(identifier: identifier, line: 23, column: 11)
        ),
        type: .continueStatement
      )

      let oneGreaterThanTwo = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 26, column: 7),
          end: SourceLocation(identifier: identifier, line: 26, column: 12)
        ),
        type: .condition
      )

      let continue2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 27, column: 3),
          end: SourceLocation(identifier: identifier, line: 27, column: 11)
        ),
        type: .continueStatement
      )

      let falseWhileCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 30, column: 7),
          end: SourceLocation(identifier: identifier, line: 30, column: 12)
        ),
        type: .condition
      )

      let break2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 31, column: 3),
          end: SourceLocation(identifier: identifier, line: 31, column: 8)
        ),
        type: .breakStatement
      )

      let printHi = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 35, column: 3),
          end: SourceLocation(identifier: identifier, line: 35, column: 14)
        ),
        type: .expression
      )

      let trueIfCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 36, column: 6),
          end: SourceLocation(identifier: identifier, line: 36, column: 10)
        ),
        type: .condition
      )

      let break3 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 36, column: 13),
          end: SourceLocation(identifier: identifier, line: 36, column: 18)
        ),
        type: .breakStatement
      )

      let repeatWhileCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 37, column: 9),
          end: SourceLocation(identifier: identifier, line: 37, column: 14)
        ),
        type: .condition
      )

      let guardCond = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 39, column: 7),
          end: SourceLocation(identifier: identifier, line: 39, column: 12)
        ),
        type: .condition
      )

      let fatalDead = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 39, column: 20),
          end: SourceLocation(identifier: identifier, line: 39, column: 38)
        ),
        type: .expression
      )

      let switchSubject = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 41, column: 8),
          end: SourceLocation(identifier: identifier, line: 41, column: 9)
        ),
        type: .expression
      )

      let case1 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 42, column: 8),
          end: SourceLocation(identifier: identifier, line: 42, column: 9)
        ),
        type: .pattern
      )

      let case2 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 42, column: 11),
          end: SourceLocation(identifier: identifier, line: 42, column: 12)
        ),
        type: .pattern
      )

      let printOne = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 43, column: 5),
          end: SourceLocation(identifier: identifier, line: 43, column: 18)
        ),
        type: .expression
      )

      let fallthroughStmt = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 44, column: 5),
          end: SourceLocation(identifier: identifier, line: 44, column: 16)
        ),
        type: .fallthroughStatement
      )

      let case3 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 45, column: 8),
          end: SourceLocation(identifier: identifier, line: 45, column: 9)
        ),
        type: .pattern
      )

      let break4 = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 46, column: 5),
          end: SourceLocation(identifier: identifier, line: 46, column: 10)
        ),
        type: .breakStatement
      )

      let printNope = Node(
        range: SourceRange(
          start: SourceLocation(identifier: identifier, line: 47, column: 12),
          end: SourceLocation(identifier: identifier, line: 47, column: 25)
        ),
        type: .expression
      )

      let nodes = Set([
        myVarDeclaration,
        patternConstDeclaration,
        myVarInc,
        ifCond1,
        printHello,
        setMyVar,
        xDecl,
        ifCond2,
        printGoodbye,
        ifCond3,
        ifCond4,
        ifCond5,
        printWoah,
        threeArray,
        forX1,
        printX,
        break1,
        threeRange,
        forX2,
        continue1,
        oneGreaterThanTwo,
        continue2,
        falseWhileCond,
        break2,
        printHi,
        trueIfCond,
        break3,
        repeatWhileCond,
        guardCond,
        fatalDead,
        switchSubject,
        case1,
        case2,
        printOne,
        fallthroughStmt,
        case3,
        break4,
        printNope
      ])

      let edges: [Node: Set<NextNode>] = [
        myVarDeclaration: [.node(patternConstDeclaration)],
        patternConstDeclaration: [.node(myVarInc)],
        myVarInc: [.node(ifCond1)],
        ifCond1: [.node(printHello), .node(ifCond2)],
        printHello: [.node(setMyVar)],
        setMyVar: [.node(xDecl)],
        xDecl: [.node(threeArray)],
        ifCond2: [.node(printGoodbye), .node(ifCond3)],
        printGoodbye: [.node(threeArray)],
        ifCond3: [.node(ifCond4), .node(threeArray)],
        ifCond4: [.node(ifCond5), .node(threeArray)],
        ifCond5: [.node(printWoah), .node(threeArray)],
        printWoah: [.node(threeArray)],
        threeArray: [.node(forX1)],
        forX1: [.node(printX), .node(threeRange)],
        printX: [.node(break1)],
        break1: [.node(threeRange)],
        threeRange: [.node(forX2)],
        forX2: [.node(continue1), .node(oneGreaterThanTwo)],
        continue1: [.node(forX2)],
        oneGreaterThanTwo: [.node(continue2), .node(falseWhileCond)],
        continue2: [.node(oneGreaterThanTwo)],
        falseWhileCond: [.node(break2), .node(printHi)],
        break2: [.node(printHi)],
        printHi: [.node(trueIfCond)],
        trueIfCond: [.node(break3), .node(repeatWhileCond)],
        break3: [.node(repeatWhileCond)],
        repeatWhileCond: [.node(guardCond), .node(printHi)],
        guardCond: [.node(switchSubject), .node(fatalDead)],
        fatalDead: [],
        switchSubject: [.node(case1)],
        case1: [.node(printOne), .node(case2)],
        case2: [.node(printOne), .node(case3)],
        printOne: [.node(fallthroughStmt)],
        fallthroughStmt: [.node(break4)],
        case3: [.node(break4), .node(printNope)],
        break4: [.passiveNext],
        printNope: [.passiveNext]
      ]

      let expectedCFG = PartialCFG(
        nodes: nodes,
        edges: edges,
        entryPoint: .node(myVarDeclaration)
      )

      if foundCFG != expectedCFG {
        print("\n\nFOUND:\n")
        dump(foundCFG)
        print("\n\nEXPECTED:\n")
        dump(expectedCFG)
      } 

      XCTAssertEqual(foundCFG, expectedCFG)

      XCTAssertEqual(myVarDeclaration.definitions, ["s:13allStructures5myVarSiv"])
      XCTAssertEqual(patternConstDeclaration.definitions, ["s:13allStructures8patternlSiv", "s:13allStructures8patternrSiv"])
      XCTAssertEqual(myVarInc.definitions, ["s:13allStructures5myVarSiv"])
      XCTAssertEqual(ifCond1.definitions, [])
      XCTAssertEqual(printHello.definitions, [])
      XCTAssertEqual(setMyVar.definitions, ["s:13allStructures5myVarSiv"])
      XCTAssertEqual(xDecl.definitions, ["s:13allStructures1xL_Siv"])
      XCTAssertEqual(ifCond2.definitions, [])
      XCTAssertEqual(printGoodbye.definitions, [])
      XCTAssertEqual(ifCond3.definitions, [])
      XCTAssertEqual(ifCond4.definitions, [])
      XCTAssertEqual(ifCond5.definitions, [])
      XCTAssertEqual(printWoah.definitions, [])
      XCTAssertEqual(threeArray.definitions, [])
      XCTAssertEqual(forX1.definitions, ["s:13allStructures1xL_Siv"])
      XCTAssertEqual(printX.definitions, [])
      XCTAssertEqual(break1.definitions, [])
      XCTAssertEqual(threeRange.definitions, [])
      XCTAssertEqual(forX2.definitions, ["s:13allStructures1xL_Siv"])
      XCTAssertEqual(continue1.definitions, [])
      XCTAssertEqual(oneGreaterThanTwo.definitions, [])
      XCTAssertEqual(continue2.definitions, [])
      XCTAssertEqual(falseWhileCond.definitions, [])
      XCTAssertEqual(break2.definitions, [])
      XCTAssertEqual(printHi.definitions, [])
      XCTAssertEqual(trueIfCond.definitions, [])
      XCTAssertEqual(break3.definitions, [])
      XCTAssertEqual(repeatWhileCond.definitions, [])
      XCTAssertEqual(guardCond.definitions, [])
      XCTAssertEqual(fatalDead.definitions, [])
      XCTAssertEqual(switchSubject.definitions, [])
      XCTAssertEqual(case1.definitions, [])
      XCTAssertEqual(case2.definitions, [])
      XCTAssertEqual(printOne.definitions, [])
      XCTAssertEqual(fallthroughStmt.definitions, [])
      XCTAssertEqual(case3.definitions, [])
      XCTAssertEqual(break4.definitions, [])
      XCTAssertEqual(printNope.definitions, [])

      XCTAssertEqual(myVarDeclaration.references, [])
      XCTAssertEqual(patternConstDeclaration.references, [])
      XCTAssertEqual(myVarInc.references, ["s:13allStructures5myVarSiv"])
      XCTAssertEqual(ifCond1.references, [])
      XCTAssertEqual(printHello.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
      XCTAssertEqual(setMyVar.references, [])
      XCTAssertEqual(xDecl.references, [])
      XCTAssertEqual(ifCond2.references, [])
      XCTAssertEqual(printGoodbye.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
      XCTAssertEqual(ifCond3.references, [])
      XCTAssertEqual(ifCond4.references, [])
      XCTAssertEqual(ifCond5.references, [])
      XCTAssertEqual(printWoah.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
      XCTAssertEqual(threeArray.references, [])
      XCTAssertEqual(forX1.references, [])
      XCTAssertEqual(printX.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF", "s:13allStructures1xL_Siv"])
      XCTAssertEqual(break1.references, [])
      XCTAssertEqual(threeRange.references, [])
      XCTAssertEqual(forX2.references, [])
      XCTAssertEqual(continue1.references, [])
      XCTAssertEqual(oneGreaterThanTwo.references, [])
      XCTAssertEqual(continue2.references, [])
      XCTAssertEqual(falseWhileCond.references, [])
      XCTAssertEqual(break2.references, [])
      XCTAssertEqual(printHi.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
      XCTAssertEqual(trueIfCond.references, [])
      XCTAssertEqual(break3.references, [])
      XCTAssertEqual(repeatWhileCond.references, [])
      XCTAssertEqual(guardCond.references, [])
      XCTAssertEqual(fatalDead.references, ["s:s10fatalErrors5NeverOSSyXK_s12StaticStringV4fileSu4linetF"])
      XCTAssertEqual(switchSubject.references, [])
      XCTAssertEqual(case1.references, [])
      XCTAssertEqual(case2.references, [])
      XCTAssertEqual(printOne.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
      XCTAssertEqual(fallthroughStmt.references, [])
      XCTAssertEqual(case3.references, [])
      XCTAssertEqual(break4.references, [])
      XCTAssertEqual(printNope.references, ["s:s5printySayypGd_SS9separatorSS10terminatortF"])
    }

    static var allTests = [
        ("testSimpleIf", testSimpleIf)
    ]
}
