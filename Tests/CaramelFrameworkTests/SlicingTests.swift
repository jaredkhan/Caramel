import XCTest
import Source
@testable import CaramelFramework

class SlicingTests: XCTestCase {
  func testMultiplyAndAdd() {
    let multiplyAndAddPath = "Resources/SlicingTestFiles/multiplyAndAdd.swift"

    let line = 13
    let column = 9

    let cfg = PartialCFG(contentsOfFile: multiplyAndAddPath)
    let completeCFG = try! CompleteCFG(cfg: cfg)
    let pdg = PDG(cfg: completeCFG)

    let slice = pdg.slice(line: line, column: column)!

    let expectedRanges: [(start: (line: Int, col: Int), end: (line: Int, col: Int))] = [
      ((1, 1), (1, 26)),
      ((2, 1), (2, 12)),
      ((4, 1), (4, 10)),
      ((6, 7), (6, 12)),
      ((7, 3), (7, 16)),
      ((9, 3), (9, 12)),
      ((13, 1), (13, 11))
    ]

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
}