import XCTest

@testable import Motion

final class DecayAnimationTests: XCTestCase {

    // MARK: - DecayAnimation Tests

    func testDecayStartStop() {
        let decay = DecayAnimation<CGFloat>()
        decay.updateValue(to: .zero)
        decay.velocity = 2000.0

        decay.start()

        XCTAssertTrue(decay.enabled)

        decay.stop()

        XCTAssertFalse(decay.enabled)
    }

    func testDecayAnimation() {
        let decay = DecayAnimation<CGFloat>()

        let expectCompletionCalled = XCTestExpectation(description: "Decay animated from \(decay.value) to ")
        let expectDecayVelocityZero = XCTestExpectation(description: "Decay animated from \(decay.value) to ")
        decay.completion = { [unowned decay] in
            expectCompletionCalled.fulfill()

            if decay.velocity <= 0.5 {
                expectDecayVelocityZero.fulfill()
            }
        }
        decay.velocity = 2000.0

        tickAnimationUntilResolved(decay)

        wait(for: [expectCompletionCalled, expectDecayVelocityZero], timeout: 0.0)
    }

    // MARK: - CAKeyframeAnimationEmittable Tests

    func testCreateCAKeyframeAnimationFromDecayAnimation() {
        let decay = DecayAnimation<CGFloat>()
        decay.velocity = 2000.0

        let keyframeAnimation = decay.keyframeAnimation()

        XCTAssertEqual(keyframeAnimation.calculationMode, .discrete)
        XCTAssertFalse(keyframeAnimation.values?.isEmpty ?? true)
        XCTAssertFalse(keyframeAnimation.keyTimes?.isEmpty ?? true)
        XCTAssertTrue(keyframeAnimation.duration.approximatelyEqual(to: 4.133))
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.animationObservers.count == 0)
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

}
