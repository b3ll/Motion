#if arch(x86_64)

import XCTest
@testable import Motion

final class MotionTests: XCTestCase {

    func testSpring() {
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

    func testDecay() {
        let decay = DecayAnimation<CGFloat>()
        decay.value = .zero
        decay.valueChanged(disableActions: true) { newValue in
            XCTAssert(CATransaction.disableActions())
        }

        let expectation = XCTestExpectation(description: "Decay animated from \(decay.value) to ")
        decay.completion = { (successful) in
            if successful {
                expectation.fulfill()
            }
        }
        decay.velocity = 2000.0
        decay.start()

        wait(for: [expectation], timeout: 15.0)
    }

    static var allTests = [
        ("testSpring", testSpring),
        ("testDecay", testDecay),
    ]

}

#endif
