import XCTest
@testable import CaramelFramework

class SnippetGrabberTests: XCTestCase {
  func testValidGrab() {
    let shortFilePath = "Resources/SnippetGrabberTestFiles/short.txt"

    let snippet = try! SnippetGrabber.get(
      filePath: shortFilePath,
      startOffset: 0,
      endOffset: 17
    )

    XCTAssertEqual(snippet, "pretty short file")
  }

  func testInvalidGrab() {
    let shortFilePath = "Resources/SnippetGrabberTestFiles/short.txt"

    XCTAssertThrowsError(
      try SnippetGrabber.get(
        filePath: shortFilePath,
        startOffset: 0,
        endOffset: 18
      )
    )
  }

  static var allTests = [
    ("testValidGrab", testValidGrab),
    ("testInvalidGrab", testInvalidGrab)
  ]
}
