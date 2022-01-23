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

    func testSpringWithCustomEpsilon() {
        let spring1 = SpringAnimation(initialValue: CGRect.zero)
        spring1.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)

        var spring1FrameCount = 0
        spring1.onValueChanged { _ in
            spring1FrameCount += 1
        }

        let expectCompletionCalled1 = XCTestExpectation(description: "Spring finished animating to \(spring1.toValue)")
        let expectToValueReached1 = XCTestExpectation(description: "Spring animated from \(spring1.value) to \(spring1.toValue)")
        spring1.completion = { [unowned spring1] in
            expectCompletionCalled1.fulfill()

            if spring1.value == spring1.toValue {
                expectToValueReached1.fulfill()
            }
        }

        tickAnimationUntilResolved(spring1)

        wait(for: [expectCompletionCalled1, expectToValueReached1], timeout: 0.0)

        let spring2 = SpringAnimation(initialValue: CGRect.zero)
        spring2.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)
        spring2.resolvingEpsilon = 0.1

        var spring2FrameCount = 0
        spring2.onValueChanged { _ in
            spring2FrameCount += 1
        }

        let expectCompletionCalled2 = XCTestExpectation(description: "Spring finished animating to \(spring2.toValue)")
        let expectToValueReached2 = XCTestExpectation(description: "Spring animated from \(spring2.value) to \(spring2.toValue)")
        spring2.completion = { [unowned spring1] in
            expectCompletionCalled2.fulfill()

            if spring1.value == spring1.toValue {
                expectToValueReached2.fulfill()
            }
        }

        tickAnimationUntilResolved(spring2)

        wait(for: [expectCompletionCalled2, expectToValueReached2], timeout: 0.0)

        XCTAssertTrue(spring2FrameCount < spring1FrameCount)
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
        let f = AnimationFrame(timestamp: 0, targetTimestamp: 0.5)

        let underDampedSpring = SpringAnimation<CGFloat>(response: 1.0, dampingRatio: 0.80)
        underDampedSpring.toValue = 10.0
        underDampedSpring.tick(frame: f)

        XCTAssert(underDampedSpring.value.approximatelyEqual(to: 9.223))

        let criticallyDampedSpring = SpringAnimation<CGFloat>(response: 1.0, dampingRatio: 1.0)
        criticallyDampedSpring.toValue = 10.0
        criticallyDampedSpring.tick(frame: f)

        XCTAssert(criticallyDampedSpring.value.approximatelyEqual(to: 8.210))

        let overDampedSpring = SpringAnimation<CGFloat>(stiffness: 2.0, damping: 10.0)
        overDampedSpring.toValue = 10.0
        overDampedSpring.tick(frame: f)
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
        XCTAssertTrue(keyframeAnimation.duration.approximatelyEqual(to: 2.383))
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.animationObservers.count == 0)
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

}
