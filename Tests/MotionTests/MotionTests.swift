import XCTest
@testable import Motion

final class MotionTests: XCTestCase {

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let spring = SpringAnimation(CGRect.zero)
        spring.value = .zero
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)
        spring.valueChanged(disableActions: true) { newValue in
            XCTAssert(CATransaction.disableActions())
        }

        let expectation = XCTestExpectation(description: "Spring animated from \(spring.value) to \(spring.toValue)")
        spring.completion = { (successful) in
            if successful {
                expectation.fulfill()
            }
        }
        spring.start()

        wait(for: [expectation], timeout: 15.0)
    }

    static var allTests = [
        ("testExample", testExample),
    ]

}
