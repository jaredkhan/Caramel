import XCTest
@testable import CaramelFramework

class QueueTests: XCTestCase {
    func testQueue() {

      var myQueue = Queue<Int>()

      // Should dequeue nil if nothing is in the queue
      XCTAssertNil(myQueue.dequeue())
      XCTAssert(myQueue.isEmpty)

      // Should be first in first out
      myQueue.enqueue(1)
      myQueue.enqueue(2)
      myQueue.enqueue(3)
      myQueue.enqueue(4)
      XCTAssertEqual(myQueue.dequeue(), 1)
      XCTAssertEqual(myQueue.dequeue(), 2)
      XCTAssertEqual(myQueue.dequeue(), 3)
      XCTAssertEqual(myQueue.dequeue(), 4)

      // Should dequeue nil if nothing is in the queue
      XCTAssertNil(myQueue.dequeue())
      XCTAssert(myQueue.isEmpty)
    }
    static var allTests = [
        ("testQueue", testQueue)
    ]
}
