// import XCTest
// import Source
// @testable import CaramelFramework

// class PDGTests: XCTestCase {
//     func testMultiplyAndAdd() {
//       // Get path
//       let multiplyAndAddPath = "Resources/SlicingTestFiles/multiplyAndAdd.swift"

//       let cfg = PartialCFG(contentsOfFile: multiplyAndAddPath)
//       let completeCFG = try! CompleteCFG(cfg: cfg)
//       let foundPDG = PDG(cfg: completeCFG)

//       let identifier = FileManager.default.currentDirectoryPath + "/" + multiplyAndAddPath
      
//       let startNode = Node(range: SourceRange.EMPTY, type: .start)

//       let nDecl = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 1, column: 1),
//           end: SourceLocation(identifier: identifier, line: 1, column: 26)
//         ),
//         type: .expression
//       )

//       let sumDecl = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 2, column: 1),
//           end: SourceLocation(identifier: identifier, line: 2, column: 12)
//         ),
//         type: .expression
//       )

//       let productDecl = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 3, column: 1),
//           end: SourceLocation(identifier: identifier, line: 3, column: 16)
//         ),
//         type: .expression
//       )

//       let iDecl = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 4, column: 1),
//           end: SourceLocation(identifier: identifier, line: 4, column: 10)
//         ),
//         type: .expression
//       )

//       let whileCond = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 6, column: 7),
//           end: SourceLocation(identifier: identifier, line: 6, column: 12)
//         ),
//         type: .condition
//       )

//       let sumAdd = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 7, column: 3),
//           end: SourceLocation(identifier: identifier, line: 7, column: 16)
//         ),
//         type: .expression,
//         defRange: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 7, column: 3),
//           end: SourceLocation(identifier: identifier, line: 7, column: 6)
//         )
//       )

//       let productMultiply = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 8, column: 3),
//           end: SourceLocation(identifier: identifier, line: 8, column: 24)
//         ),
//         type: .expression,
//         defRange: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 8, column: 3),
//           end: SourceLocation(identifier: identifier, line: 8, column: 10)
//         )
//       )

//       let iIncrement = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 9, column: 3),
//           end: SourceLocation(identifier: identifier, line: 9, column: 12)
//         ),
//         type: .expression,
//         defRange: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 9, column: 3),
//           end: SourceLocation(identifier: identifier, line: 9, column: 4)
//         )
//       )

//       let printProduct = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 12, column: 1),
//           end: SourceLocation(identifier: identifier, line: 12, column: 15)
//         ),
//         type: .expression
//       )

//       let printSum = Node(
//         range: SourceRange(
//           start: SourceLocation(identifier: identifier, line: 13, column: 1),
//           end: SourceLocation(identifier: identifier, line: 13, column: 11)
//         ),
//         type: .expression
//       )

//       let nodes = Set([
//         startNode,
//         nDecl,
//         sumDecl,
//         productDecl,
//         iDecl,
//         whileCond,
//         sumAdd,
//         productMultiply,
//         iIncrement,
//         printProduct,
//         printSum
//       ])

//       let edges: [Node: Set<PDGEdge>] = [
//         startNode: [],
//         nDecl: [.data(whileCond)],
//         sumDecl: [.data(sumAdd), .data(printSum)],
//         productDecl: [.data(productMultiply), .data(printProduct)],
//         iDecl: [.data(whileCond), .data(iIncrement), .data(sumAdd), .data(productMultiply)],
//         whileCond: [.control(sumAdd), .control(productMultiply), .control(iIncrement), .control(whileCond)],
//         sumAdd: [.data(sumAdd), .data(printSum)],
//         productMultiply: [.data(productMultiply), .data(printProduct)],
//         iIncrement: [.data(whileCond), .data(iIncrement), .data(sumAdd), .data(productMultiply)],
//         printProduct: [],
//         printSum: []
//       ]

//       let reverseEdges: [Node: Set<PDGEdge>] = [
//         startNode: [],
//         nDecl: [],
//         sumDecl: [],
//         productDecl: [],
//         iDecl: [],
//         whileCond: [.data(iIncrement), .data(iDecl), .data(nDecl), .control(whileCond)],
//         sumAdd: [.data(iIncrement), .data(sumAdd), .control(whileCond), .data(sumDecl), .data(iDecl)],
//         productMultiply: [.data(iIncrement), .data(productMultiply), .control(whileCond), .data(productDecl), .data(iDecl)],
//         iIncrement: [.data(iIncrement), .control(whileCond), .data(iDecl)],
//         printProduct: [.data(productDecl), .data(productMultiply)],
//         printSum: [.data(sumAdd), .data(sumDecl)]
//       ]

//       let expectedPDG = PDG(
//         nodes: nodes,
//         edges: edges,
//         reverseEdges: reverseEdges,
//         start: startNode
//       )

//       // if foundPDG != expectedPDG {
//       //   print("\n\nFOUND:\n")
//       //   dump(foundPDG)
//       //   print("\n\nEXPECTED:\n")
//       //   dump(expectedPDG)
//       // }

//       print(foundPDG.nodes.count)
//       print(foundPDG.edges.count)
//       print(expectedPDG.nodes.count)
//       print(expectedPDG.edges.count)

//       XCTAssertEqual(foundPDG, expectedPDG)
//     }

//     static var allTests = [
//         ("testMultiplyAndAdd", testMultiplyAndAdd)
//     ]
// }
