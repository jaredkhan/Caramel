import XCTest
import Source
@testable import CaramelFramework

class SlicingTests: XCTestCase {
  private func getSliceData(
    filePath: String,
    line: Int,
    column: Int,
    expectedRanges: [(start: (line: Int, col: Int), end: (line: Int, col: Int))]
  ) -> (
    recall: Double,
    precision: Double,
    timeTaken: Double,
    numNodes: Int
  ) {
    print("\(filePath), line: \(line), column: \(column)")
    let startTime = NSDate().timeIntervalSince1970
    let pdg = getPDG(filePath: filePath)
    let foundNodes = pdg.slice(line: line, column: column)!
    let endTime = NSDate().timeIntervalSince1970
    let timeTaken = endTime - startTime

    let expectedNodes: Set<Node> = Set(expectedRanges.map { range in 
      guard let node = pdg.nodes.first(where: { node in 
        (node.range.start.line, node.range.start.column) <=
        (range.start.line, range.start.col) &&
        (node.range.end.line, node.range.end.column) >=
        (range.end.line, range.end.col)
      }) else {
        fatalError("Couldn't find node in range: \(range) in file: \(filePath)")
      }
      return node
    })

    let truePositives = foundNodes.intersection(expectedNodes)
    let recall = Double(truePositives.count) / Double(expectedNodes.count)
    let precision = Double(truePositives.count) / Double(foundNodes.count)

    if recall != 1.0 {
      XCTFail("Slice did not include ranges: \(expectedNodes.subtracting(foundNodes))")
    }

    if precision != 1.0 {
      let falsePositives = foundNodes.subtracting(expectedNodes)
      print("Found false positives:")
      for fp in falsePositives {
        print(try! fp.range.content())
      }
    }

    return (
      recall: recall,
      precision: precision,
      timeTaken: timeTaken,
      numNodes: pdg.nodes.count
    )
  }

  private func getPDG(filePath: String) -> PDG {
    let cfg = PartialCFG(contentsOfFile: filePath)
    let completeCFG = try! CompleteCFG(cfg: cfg)
    let pdg = PDG(cfg: completeCFG)
    return pdg
  }

  func testMultiplyAndAdd() {
    let path = "Resources/SlicingTestFiles/multiplyAndAdd.swift"

    print(getSliceData(
      filePath: path,
      line: 13,
      column: 9,
      expectedRanges: [
        ((1, 1), (1, 26)),
        ((2, 1), (2, 12)),
        ((4, 1), (4, 10)),
        ((6, 7), (6, 12)),
        ((7, 3), (7, 16)),
        ((9, 3), (9, 12)),
        ((13, 1), (13, 11))
      ]
    ))

    print(getSliceData(
      filePath: path,
      line: 12,
      column: 9,
      expectedRanges: [
        ((1, 1), (1, 26)),
        ((3, 1), (3, 16)),
        ((4, 1), (4, 10)),
        ((6, 7), (6, 12)),
        ((8, 3), (8, 24)),
        ((9, 3), (9, 12)),
        ((12, 1), (12, 15))
      ]
    ))
  }

  func testFor() {
    let path = "Resources/SlicingTestFiles/suite/for.swift"
    
    print(getSliceData(
      filePath: path,
      line: 10,
      column: 5,
      expectedRanges: [
        ((1, 1), (1, 26)),
        ((3, 1), (3, 16)),
        ((5, 5), (5, 6)),
        ((5, 10), (5, 17)),
        ((7, 3), (7, 15)),
        ((10, 1), (10, 15))
      ]
    ))

    print(getSliceData(
      filePath: path,
      line: 11,
      column: 5,
      expectedRanges: [
        ((1, 1), (1, 26)),
        ((2, 1), (2, 12)),
        ((5, 5), (5, 6)),
        ((5, 10), (5, 17)),
        ((6, 3), (6, 11)),
        ((11, 1), (11, 11))
      ]
    ))
  }

  func testSwitch() {
    let path = "Resources/SlicingTestFiles/suite/switch.swift"
    
    print(getSliceData(filePath: path, line: 15, column: 5, expectedRanges: [
      ((1, 1), (1, 26)),
      ((2, 1), (2, 10)),
      ((3, 1), (3, 10)),
      ((5, 5), (5, 6)),
      ((5, 10), (5, 17)),
      ((6, 10), (6, 11)),
      ((7, 10), (7, 15)),
      ((7, 17), (7, 23)),
      ((8, 10), (8, 17)),
      ((8, 19), (8, 25)),
      ((9, 10), (9, 17)),
      ((10, 7), (10, 16)),
      ((11, 14), (11, 19)),
      ((15, 1), (15, 9))
    ]))
  }

  func testGuard() {
    let path = "Resources/SlicingTestFiles/suite/guard.swift"
        
    print(getSliceData(filePath: path, line: 13, column: 9, expectedRanges: [
      ((1, 11), (1, 26)),
      ((2, 1), (2, 12)),
      ((4, 1), (4, 10)),
      ((6, 7), (6, 12)),
      ((7, 3), (7, 16)),
      ((9, 3), (9, 12)),
      ((13, 1), (13, 11))
    ]))
    
    print(getSliceData(filePath: path, line: 12, column: 9, expectedRanges: [
      ((1, 11), (1, 26)),
      ((3, 1), (3, 16)),
      ((4, 1), (4, 10)),
      ((6, 7), (6, 12)),
      ((8, 3), (8, 24)),
      ((9, 3), (9, 12)),
      ((12, 1), (12, 15))
    ]))
  }

  func testRepeatWhile() {
    let path = "Resources/SlicingTestFiles/suite/repeatWhile.swift"
    
    print(getSliceData(filePath: path, line: 13, column: 9, expectedRanges: [
      ((1, 11), (1, 26)),
      ((2, 1), (2, 12)),
      ((4, 1), (4, 10)),
      ((7, 3), (7, 16)),
      ((9, 3), (9, 12)),
      ((10, 9), (10, 14)),
      ((13, 1), (13, 11))
    ]))
    
    print(getSliceData(filePath: path, line: 12, column: 9, expectedRanges: [
      ((1, 11), (1, 26)),
      ((3, 1), (3, 16)),
      ((4, 1), (4, 10)),
      ((8, 3), (8, 24)),
      ((9, 3), (9, 12)),
      ((10, 9), (10, 14)),
      ((12, 1), (12, 15))
    ]))
  }

  func testD() {
    let path = "Resources/SlicingTestFiles/github/d.swift"
    
    print(getSliceData(filePath: path, line: 81, column: 17, expectedRanges: [
      ((33, 8), (33, 52)),
      ((36, 8), (36, 20)),
      ((41, 8), (41, 36)),
      ((48, 5), (48, 22)),
      ((49, 9), (49, 38)),
      ((51, 9), (51, 34)),
      ((52, 9), (52, 30)),
      ((54, 9), (54, 37)),
      ((57, 9), (57, 30)),
      ((60, 12), (60, 33)),
      ((62, 7), (62, 29)),
      ((65, 14), (65, 30)),
      ((65, 9), (65, 10)),
      ((68, 14), (73, 10)),
      ((75, 9), (75, 33)),
      ((76, 12), (76, 28)),
      ((81, 11), (81, 26)),
      ((93, 12), (93, 26)),
      ((110, 7), (110, 42))
    ]))
    
    print(getSliceData(filePath: path, line: 98, column: 17, expectedRanges: [
      ((33, 8), (33, 53)),
      ((36, 8), (36, 20)),
      ((41, 8), (41, 36)),
      ((48, 5), (48, 22)),
      ((49, 9), (49, 38)),
      ((51, 9), (51, 34)),
      ((52, 9), (52, 30)),
      ((54, 9), (54, 37)),
      ((55, 9), (55, 22)),
      ((56, 9), (56, 26)),
      ((57, 9), (57, 30)),
      ((60, 12), (60, 33)),
      ((61, 7), (61, 34)),
      ((62, 7), (62, 29)),
      ((65, 14), (65, 30)),
      ((65, 9), (65, 10)),
      ((68, 14), (73, 10)),
      ((75, 9), (75, 33)),
      ((93, 12), (93, 26)),
      ((98, 11), (98, 33)),
      ((110, 7), (110, 42))
    ]))
  }

  func testJ() {
    let path = "Resources/SlicingTestFiles/github/j.swift"
    guard FileManager.default.fileExists(atPath: path) else {
      print("Omitting slicing test for path since the file does not exist: \(path)")
      return
    }
    
    print(getSliceData(filePath: path, line: 16, column: 20, expectedRanges: [
      ((4, 6), (4, 29)),
      ((5, 9), (5, 29)),
      ((8, 11), (8, 26)),
      ((12, 9), (12, 10)),
      ((12, 14), (12, 32)),
      ((13, 12), (13, 44)),
      ((16, 17), (16, 37))
    ]))
  }

  func testP() {
    let path = "Resources/SlicingTestFiles/github/p.swift"
    guard FileManager.default.fileExists(atPath: path) else {
      print("Omitting slicing test for path since the file does not exist: \(path)")
      return
    }
    
    print(getSliceData(filePath: path, line: 18, column: 19, expectedRanges: [
      ((4, 6), (4, 43)),
      ((7, 11), (7, 25)),
      ((17, 28), (17, 32)),
      ((17, 28), (17, 32)),
      ((17, 9), (17, 24)),
      ((18, 13), (18, 47))
    ]))
  }

  func testS() {
    let path = "Resources/SlicingTestFiles/github/s.swift"
    guard FileManager.default.fileExists(atPath: path) else {
      print("Omitting slicing test for path since the file does not exist: \(path)")
      return
    }
    
    print(getSliceData(filePath: path, line: 17, column: 19, expectedRanges: [
      ((5, 6), (5, 30)),
      ((6, 9), (6, 17)),
      ((7, 9), (7, 33)),
      ((10, 10), (10, 24)),
      ((11, 13), (11, 57)),
      ((17, 12), (17, 39)),
      ((18, 13), (18, 22)),
      ((20, 13), (20, 23))
    ]))
  }

  func testT() {
    let path = "Resources/SlicingTestFiles/github/t.swift"
    
    print(getSliceData(filePath: path, line: 38, column: 15, expectedRanges: [
      ((32, 13), (32, 48)),
      ((33, 9), (33, 83)),
      ((34, 9), (34, 50)),
      ((37, 9), (37, 10)),
      ((37, 14), (37, 21)),
      ((38, 13), (38, 46))
    ]))
  }
}
