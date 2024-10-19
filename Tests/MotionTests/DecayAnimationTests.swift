import XCTest

@testable import Motion

@MainActor
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

    func testDecayAnimationWithNegativeVelocity() {
        let decay = DecayAnimation<CGFloat>()

        let expectCompletionCalled = XCTestExpectation(description: "Decay animated from \(decay.value) to ")
        let expectDecayVelocityZero = XCTestExpectation(description: "Decay animated from \(decay.value) to ")
        decay.completion = { [unowned decay] in
            expectCompletionCalled.fulfill()

            if abs(decay.velocity) <= 0.5 {
                expectDecayVelocityZero.fulfill()
            }
        }
        decay.velocity = -2000.0

        tickAnimationUntilResolved(decay)

        wait(for: [expectCompletionCalled, expectDecayVelocityZero], timeout: 0.0)
    }

    func testDecayResolveImmediately() {
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

        tickAnimationForDuration(decay, maxDuration: 0.1)
        decay.stop(resolveImmediately: true, postValueChanged: true)

        wait(for: [expectCompletionCalled, expectDecayVelocityZero], timeout: 0.0)
    }

    func testDecayToValueCalculation() {
        let decay = DecayAnimation<CGFloat>()
        decay.velocity = 2000.0

        XCTAssertTrue(decay.toValue.isApproximatelyEqual(to: 998.999))
        XCTAssertTrue(decay._toValue.isApproximatelyEqual(to: SIMD2<Double>(998.999, 0.0)))

        let decay2 = DecayAnimation<CGPoint>()
        decay2.velocity = CGPoint(x: 1000.0, y: 2000.0)

        XCTAssertTrue(decay2.toValue.x.isApproximatelyEqual(to: 499.499) && decay2.toValue.y.isApproximatelyEqual(to: 998.999))
        XCTAssertTrue(decay2._toValue.isApproximatelyEqual(to: SIMD2<Double>(499.499, 998.999)))
    }

    func testDecayVelocityCalculation() {
        let decay = DecayAnimation<CGFloat>()
        decay.toValue = 998.999

        XCTAssertTrue(decay.velocity.isApproximatelyEqual(to: 2000.0, epsilon: 0.01))
        XCTAssertTrue(decay._velocity.isApproximatelyEqual(to: SIMD2<Double>(2000.0, 0.0), epsilon: 0.01))

        let decay2 = DecayAnimation<CGPoint>()
        decay2.toValue = CGPoint(x: 499.499, y: 998.999)

        XCTAssertTrue(decay2.velocity.x.isApproximatelyEqual(to: 1000.0, epsilon: 0.01) && decay2.velocity.y.isApproximatelyEqual(to: 2000.0, epsilon: 0.01))
        XCTAssertTrue(decay2._velocity.isApproximatelyEqual(to: SIMD2<Double>(1000.0, 2000.0), epsilon: 0.01))
    }

    func testDecayRoundingFactorApplication() {
        let decay = DecayAnimation<CGFloat>()
        decay.roundingFactor = 1.0
        decay.velocity = 200.0

        XCTAssertTrue(decay.velocity.isApproximatelyEqual(to: 200.2, epsilon: 0.001))
        XCTAssertTrue(decay.toValue.isApproximatelyEqual(to: 100.0, epsilon: 0.001))

        let decay2 = DecayAnimation<CGFloat>()
        decay2.roundingFactor = 1.0 / 3.0 // i.e. 3x device
        decay2.velocity = 200.90

        XCTAssertTrue(decay2.velocity.isApproximatelyEqual(to: 200.867, epsilon: 0.001))
        XCTAssertTrue(decay2.toValue.isApproximatelyEqual(to: 100.333, epsilon: 0.001))
    }

    // MARK: - CAKeyframeAnimationEmittable Tests

    func testCreateCAKeyframeAnimationFromDecayAnimation() {
        let decay = DecayAnimation<CGFloat>()
        decay.velocity = 2000.0

        let keyframeAnimation = decay.keyframeAnimation(forFramerate: 60)

        XCTAssertEqual(keyframeAnimation.calculationMode, .discrete)
        XCTAssertFalse(keyframeAnimation.values?.isEmpty ?? true)
        XCTAssertFalse(keyframeAnimation.keyTimes?.isEmpty ?? true)
        XCTAssertTrue(keyframeAnimation.duration.isApproximatelyEqual(to: 4.166))
    }

    override class func tearDown() {
        Task { @MainActor in
            // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
            XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
        }
    }

}
