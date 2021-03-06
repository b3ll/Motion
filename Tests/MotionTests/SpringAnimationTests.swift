import XCTest

@testable import Motion

final class SpringAnimationTests: XCTestCase {

    // MARK: - SpringAnimation Tests

    func testSpringStartStop() {
        let spring = SpringAnimation(initialValue: CGRect.zero)
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)
        spring.start()

        XCTAssertTrue(spring.enabled)

        spring.stop()

        XCTAssertFalse(spring.enabled)
    }

    func testSpring() {
        let spring = SpringAnimation(initialValue: CGRect.zero)
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)

        let expectCompletionCalled = XCTestExpectation(description: "Spring finished animating to \(spring.toValue)")
        let expectToValueReached = XCTestExpectation(description: "Spring animated from \(spring.value) to \(spring.toValue)")
        spring.completion = { [unowned spring] in
            expectCompletionCalled.fulfill()

            if spring.value == spring.toValue {
                expectToValueReached.fulfill()
            }
        }

        tickAnimationUntilResolved(spring)

        wait(for: [expectCompletionCalled, expectToValueReached], timeout: 0.0)
    }

    func testCriticallyDampedSpring() {
        let spring = SpringAnimation(initialValue: CGRect.zero)
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)
        spring.configure(response: 1.0, dampingRatio: 1.0)

        let expectCompletionCalled = XCTestExpectation(description: "Spring finished animating to \(spring.toValue)")
        let expectToValueReached = XCTestExpectation(description: "Spring animated from \(spring.value) to \(spring.toValue)")
        spring.completion = { [unowned spring] in
            expectCompletionCalled.fulfill()

            if spring.value == spring.toValue {
                expectToValueReached.fulfill()
            }
        }

        tickAnimationUntilResolved(spring)

        wait(for: [expectCompletionCalled, expectToValueReached], timeout: 0.0)
    }

    func testOverDampedSpring() {
        let spring = SpringAnimation(initialValue: CGRect.zero, stiffness: 2.0, damping: 10.0)
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)

        let expectCompletionCalled = XCTestExpectation(description: "Spring finished animating to \(spring.toValue)")
        let expectToValueReached = XCTestExpectation(description: "Spring animated from \(spring.value) to \(spring.toValue)")
        spring.completion = { [unowned spring] in
            expectCompletionCalled.fulfill()

            if spring.value == spring.toValue {
                expectToValueReached.fulfill()
            }
        }

        tickAnimationUntilResolved(spring, maxDuration: 120.0)

        wait(for: [expectCompletionCalled, expectToValueReached], timeout: 0.0)
    }

    func testSpringEvaluation() {
        let t = 0.50

        let underDampedSpring = SpringAnimation<CGFloat>(response: 1.0, dampingRatio: 0.80)
        underDampedSpring.toValue = 10.0
        underDampedSpring.tick(t)

        XCTAssert(underDampedSpring.value.approximatelyEqual(to: 9.223))

        let criticallyDampedSpring = SpringAnimation<CGFloat>(response: 1.0, dampingRatio: 1.0)
        criticallyDampedSpring.toValue = 10.0
        criticallyDampedSpring.tick(t)

        XCTAssert(criticallyDampedSpring.value.approximatelyEqual(to: 8.210))

        let overDampedSpring = SpringAnimation<CGFloat>(stiffness: 2.0, damping: 10.0)
        overDampedSpring.toValue = 10.0
        overDampedSpring.tick(t)
    }

    func testSpringVelocitySetting() {
        let spring = SpringAnimation(initialValue: 0.0)
        spring.velocity = 100.0

        // Spring velocity is inversed for internal calculations.
        XCTAssertEqual(Double(spring._velocity), -100.0)
    }

    func testSpringActionsDisabled() {
        let spring = SpringAnimation(initialValue: CGRect.zero)
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)

        spring.onValueChanged(disableActions: true) { newValue in
            XCTAssert(CATransaction.disableActions())
        }

        CADisableActions {
            XCTAssert(CATransaction.disableActions())
        }

        tickAnimationOnce(spring)
    }

    func testSpringValueClamping() {
        let spring = SpringAnimation(initialValue: 0.0)
        spring.toValue = 1.0

        let clampingRange = 0.0...1.0
        spring.clampingRange = clampingRange

        spring.onValueChanged { newValue in
            XCTAssert(clampingRange.contains(newValue))
        }

        tickAnimationUntilResolved(spring)
    }

    func testSpringResolveImmediately() {
        let spring = SpringAnimation(initialValue: 0.0)
        spring.toValue = 1.0

        let expectValueChangedCalled = XCTestExpectation(description: "Spring value changed to \(spring.toValue)")
        let expectCompletionCalled = XCTestExpectation(description: "Spring completed")

        spring.onValueChanged { newValue in
            if newValue == 1.0 {
                expectValueChangedCalled.fulfill()
            }
        }
        spring.completion = {
            expectCompletionCalled.fulfill()
        }

        tickAnimationForDuration(spring, maxDuration: 0.1)
        spring.stop(resolveImmediately: true, postValueChanged: true)

        wait(for: [expectValueChangedCalled, expectCompletionCalled], timeout: 0.0)
    }

    // MARK: - CAKeyframeAnimationEmittable Tests

    func testCreateCAKeyframeAnimationFromSpringAnimation() {
        let spring = SpringAnimation(initialValue: CGRect.zero)
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)
        spring.configure(response: 1.0, dampingRatio: 1.0)

        let keyframeAnimation = spring.keyframeAnimation()

        XCTAssertEqual(keyframeAnimation.calculationMode, .discrete)
        XCTAssertFalse(keyframeAnimation.values?.isEmpty ?? true)
        XCTAssertFalse(keyframeAnimation.keyTimes?.isEmpty ?? true)
        XCTAssertTrue(keyframeAnimation.duration.approximatelyEqual(to: 2.766))
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.animationObservers.count == 0)
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

}
