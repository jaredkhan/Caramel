import XCTest
import Source
@testable import CaramelFramework

class SlicingTests: XCTestCase {
  private func check(slice: Set<Node>, containsRanges expectedRanges: [(start: (line: Int, col: Int), end: (line: Int, col: Int))]) {
    // Check that each range is represented in the slice.
    for range in expectedRanges {
      guard let _ = slice.first(where: { node in
        // Check node contains the range
        node.range.start.line <= range.start.line &&
        node.range.start.column <= range.start.col &&
        node.range.end.line >= range.end.line &&
        node.range.end.column >= range.end.col
      }) else {
        XCTFail("Slice did not include range: \(range)")
        return
      }
    }
  }

  func getPDG(filePath: String) -> PDG {
    let cfg = PartialCFG(contentsOfFile: filePath)
    let completeCFG = try! CompleteCFG(cfg: cfg)
    let pdg = PDG(cfg: completeCFG)
    return pdg
  }

  func testMultiplyAndAdd() {
    let pdg = getPDG(filePath: "Resources/SlicingTestFiles/multiplyAndAdd.swift")
    
    check(slice: pdg.slice(line: 13, column: 9)!, containsRanges: [
      ((1, 1), (1, 26)),
      ((2, 1), (2, 12)),
      ((4, 1), (4, 10)),
      ((6, 7), (6, 12)),
      ((7, 3), (7, 16)),
      ((9, 3), (9, 12)),
      ((13, 1), (13, 11))
    ])

    check(slice: pdg.slice(line: 12, column: 9)!, containsRanges: [
      ((1, 1), (1, 26)),
      ((3, 1), (3, 16)),
      ((4, 1), (4, 10)),
      ((6, 7), (6, 12)),
      ((8, 3), (8, 24)),
      ((9, 3), (9, 12)),
      ((12, 1), (12, 15))
    ])
  }

  func testFor() {
    let pdg = getPDG(filePath: "Resources/SlicingTestFiles/suite/for.swift")
    
    check(slice: pdg.slice(line: 10, column: 5)!, containsRanges: [
      ((1, 1), (1, 26)),
      ((3, 1), (3, 16)),
      ((5, 5), (5, 6)),
      ((5, 10), (5, 17)),
      ((7, 3), (7, 15)),
      ((10, 1), (10, 15))
    ])

    check(slice: pdg.slice(line: 11, column: 5)!, containsRanges: [
      ((1, 1), (1, 26)),
      ((2, 1), (2, 12)),
      ((5, 5), (5, 6)),
      ((5, 10), (5, 17)),
      ((6, 3), (6, 11)),
      ((11, 1), (11, 11))
    ])
  }

}
