import XCTest
@testable import CaramelFramework

class MultiRangeTests: XCTestCase {
    func testMultiRange() {

      var myMultiRange = MultiRange<Int>(range: 1...20)
      XCTAssert(myMultiRange.contains(1))
      XCTAssert(myMultiRange.contains(20))
      XCTAssert(myMultiRange.contains(5))

      myMultiRange.subtract(3...5)
      XCTAssert(myMultiRange.contains(2))
      XCTAssert(myMultiRange.contains(6))
      XCTAssertFalse(myMultiRange.contains(3))
      XCTAssertFalse(myMultiRange.contains(5))
      XCTAssertFalse(myMultiRange.contains(4))

      myMultiRange.formUnion(23...26)
      XCTAssert(myMultiRange.contains(20))
      XCTAssert(myMultiRange.contains(23))
      XCTAssert(myMultiRange.contains(26))
      XCTAssert(myMultiRange.contains(25))

      myMultiRange.formUnion(4...7)
      XCTAssert(myMultiRange.contains(4))
      XCTAssert(myMultiRange.contains(5))
    }
    static var allTests = [
        ("testMultiRange", testMultiRange)
    ]
}
