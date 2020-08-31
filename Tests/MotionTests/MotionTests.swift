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

        tickAnimationUntilResolved(spring)

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

        tickAnimationUntilResolved(decay)

        wait(for: [expectation], timeout: 15.0)
    }

    static var allTests = [
        ("testSpring", testSpring),
        ("testDecay", testDecay),
    ]

}

private func tickAnimationUntilResolved<Value: SIMDRepresentable>(_ animation: Animation<Value>, dt: CFTimeInterval = 0.016, maxDuration: CFTimeInterval = 10.0) {
    for _ in stride(from: 0.0, through: maxDuration, by: dt) {
        animation.tick(dt)
        if animation.hasResolved {
            break
        }
    }

}

#endif
