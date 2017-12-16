import XCTest
@testable import CaramelTests

XCTMain([
    testCase(CaramelTests.allTests),
    testCase(BracketStructureParserTest.allTests)
])
