import XCTest
@testable import CaramelFramework

class LineColumnResolverTests: XCTestCase {
  func testLineColIndex() {
    // Empty file
    let emptyFilePath = "Resources/LineColumnResolverTestFiles/empty.txt"
    let emptyFileLines = try! LineColumnResolver(filePath: emptyFilePath).lines
    XCTAssertEqual(
      emptyFileLines,
      [1: LineColumnResolver.Line(offset: 0, length: 0)]
    )

    // Many lined file
    let manyLinesPath = "Resources/LineColumnResolverTestFiles/manyLines.txt"
    let manyLinesLines = try! LineColumnResolver(filePath: manyLinesPath).lines
    XCTAssertEqual(
      manyLinesLines,
      [
        1: LineColumnResolver.Line(offset: 0, length: 14),
        2: LineColumnResolver.Line(offset: 14, length: 1),
        3: LineColumnResolver.Line(offset: 15, length: 34),
        4: LineColumnResolver.Line(offset: 49, length: 1),
        5: LineColumnResolver.Line(offset: 50, length: 18),
        6: LineColumnResolver.Line(offset: 68, length: 1),
        7: LineColumnResolver.Line(offset: 69, length: 10),
        8: LineColumnResolver.Line(offset: 79, length: 17),
        9: LineColumnResolver.Line(offset: 96, length: 12),
        10: LineColumnResolver.Line(offset: 108, length: 12),
        11: LineColumnResolver.Line(offset: 120, length: 17),
        12: LineColumnResolver.Line(offset: 137, length: 19),
        13: LineColumnResolver.Line(offset: 156, length: 29),
        14: LineColumnResolver.Line(offset: 185, length: 17),
        15: LineColumnResolver.Line(offset: 202, length: 2),
        16: LineColumnResolver.Line(offset: 204, length: 1),
        17: LineColumnResolver.Line(offset: 205, length: 8),
        18: LineColumnResolver.Line(offset: 213, length: 0),
      ]
    )

    // Single new line file
    let newLinePath = "Resources/LineColumnResolverTestFiles/newLine.txt"
    let newLineLines = try! LineColumnResolver(filePath: newLinePath).lines
    XCTAssertEqual(
      newLineLines,
      [
        1: LineColumnResolver.Line(offset: 0, length: 41),
        2: LineColumnResolver.Line(offset: 41, length: 0)
      ]
    )

    // No new line file
    let noNewLinePath = "Resources/LineColumnResolverTestFiles/noNewLine.txt"
    let noNewLineLines = try! LineColumnResolver(filePath: noNewLinePath).lines
    XCTAssertEqual(
      noNewLineLines,
      [1: LineColumnResolver.Line(offset: 0, length: 32)]
    )
  }

  func testLineColResolution() {
    // Many lined file
    let manyLinesPath = "Resources/LineColumnResolverTestFiles/manyLines.txt"
    let manyLinesResolver = try! LineColumnResolver(filePath: manyLinesPath)

    XCTAssertEqual(
      try! manyLinesResolver.resolve(line: 1, column: 1),
      0
    )

    XCTAssertEqual(
      try! manyLinesResolver.resolve(line: 4, column: 1),
      49
    )

    XCTAssertEqual(
      try! manyLinesResolver.resolve(line: 12, column: 8),
      144
    )
    
    XCTAssertThrowsError(try manyLinesResolver.resolve(line: 10, column: 13))
  }

  func testStaticApi() {
    let manyLinesPath = "Resources/LineColumnResolverTestFiles/manyLines.txt"
    XCTAssertEqual(
      try! LineColumnResolver.resolve(
        line: 4,
        column: 1,
        filePath: manyLinesPath
      ),
      49
    )
  }

  static var allTests = [
    ("testLineColIndex", testLineColIndex),
    ("testLineColResolution", testLineColResolution),
    ("testStaticApi", testStaticApi)
  ]
}
