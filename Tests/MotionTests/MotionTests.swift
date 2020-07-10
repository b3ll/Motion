import XCTest
@testable import Motion

final class MotionTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Motion().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
