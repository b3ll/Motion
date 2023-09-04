import XCTest

@testable import Motion

final class BasicAnimationTests: XCTestCase {

    // MARK: - BasicAnimation Tests

    func testEasingFunctions() {
        let easeIn = EasingFunction<CGFloat>.easeIn

        let range: ClosedRange<CGFloat> = 0.0...10.0

        let startValue = easeIn.solveInterpolatedValue(range, fraction: 0.0)
        XCTAssert(startValue.isApproximatelyEqual(to: range.lowerBound))

        let endValue = easeIn.solveInterpolatedValue(range, fraction: 1.0)
        XCTAssert(endValue.isApproximatelyEqual(to: range.upperBound))
    }

    func testBasicAnimationStartStop() {
        let basicAnimation = BasicAnimation<CGFloat>(easingFunction: .easeIn)
        basicAnimation.fromValue = 0.0
        basicAnimation.toValue = 10.0
        basicAnimation.duration = 1.0

        basicAnimation.start()

        XCTAssertTrue(basicAnimation.enabled)

        basicAnimation.stop()

        XCTAssertFalse(basicAnimation.enabled)
    }

    func testBasicAnimation() {
        let basicAnimation = BasicAnimation<CGFloat>(easingFunction: .easeOut)
        basicAnimation.fromValue = 0.0
        basicAnimation.toValue = 10.0
        basicAnimation.duration = 1.0

        let expectValueChangedCalled = XCTestExpectation(description: "Basic animation value changed to \(basicAnimation.toValue)")
        let expectCompletionCalled = XCTestExpectation(description: "Basic animation completed")

        basicAnimation.onValueChanged { newValue in
            if newValue == 10.0 {
                expectValueChangedCalled.fulfill()
            }
        }
        basicAnimation.completion = { [unowned basicAnimation] in
            if basicAnimation.value == basicAnimation.toValue {
                expectCompletionCalled.fulfill()
            }
        }

        tickAnimationForDuration(basicAnimation, maxDuration: 1.0)

        wait(for: [expectValueChangedCalled, expectCompletionCalled], timeout: 0.0)
    }

    func testBasicAnimationResolveImmediately() {
        let basicAnimation = BasicAnimation<CGFloat>()
        basicAnimation.fromValue = 0.0
        basicAnimation.toValue = 1.0
        basicAnimation.duration = 1.0

        let expectValueChangedCalled = XCTestExpectation(description: "Basic animation value changed to \(basicAnimation.toValue)")
        let expectCompletionCalled = XCTestExpectation(description: "Basic animation completed")

        basicAnimation.onValueChanged { newValue in
            if newValue == 1.0 {
                expectValueChangedCalled.fulfill()
            }
        }
        basicAnimation.completion = {
            expectCompletionCalled.fulfill()
        }

        tickAnimationForDuration(basicAnimation, maxDuration: 0.1)
        basicAnimation.stop(resolveImmediately: true, postValueChanged: true)

        wait(for: [expectValueChangedCalled, expectCompletionCalled], timeout: 0.0)
    }

    func testBasicAnimationResumeAfterValueChange() {
        let basicAnimation = BasicAnimation<CGFloat>(easingFunction: .easeIn)
        basicAnimation.fromValue = 0.0
        basicAnimation.toValue = 10.0
        basicAnimation.duration = 2.0
        
        tickAnimationForDuration(basicAnimation, maxDuration: 1.0)

        let timeAccumulated = basicAnimation.accumulatedTime

        basicAnimation.attemptToUpdateAccumulatedTimeToMatchValue()

        let timeAccumulatedDeterminedFromValue = basicAnimation.accumulatedTime

        XCTAssertTrue(timeAccumulated.isApproximatelyEqual(to: timeAccumulatedDeterminedFromValue))

        let expectBasicAnimationCompletionCalled = XCTestExpectation(description: "Basic animation completed")
        basicAnimation.completion = {
            expectBasicAnimationCompletionCalled.fulfill()
        }

        tickAnimationForDuration(basicAnimation, maxDuration: 1.0)

        wait(for: [expectBasicAnimationCompletionCalled], timeout: 0.0)
    }

    // MARK: - CAKeyframeAnimationEmittable Tests

    func testCreateCAKeyframeAnimationFromBasicAnimation() {
        let basicAnimation = BasicAnimation<CGFloat>(easingFunction: .easeOut)
        basicAnimation.fromValue = 0.0
        basicAnimation.toValue = 10.0
        basicAnimation.duration = 1.0

        let keyframeAnimation = basicAnimation.keyframeAnimation(forFramerate: 60)

        XCTAssertEqual(keyframeAnimation.calculationMode, .discrete)
        XCTAssertFalse(keyframeAnimation.values?.isEmpty ?? true)
        XCTAssertFalse(keyframeAnimation.keyTimes?.isEmpty ?? true)
        XCTAssertTrue(keyframeAnimation.duration.isApproximatelyEqual(to: 1.0))
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

}

#if os(macOS)
extension Animator {
    static let shared: Animator = {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            fatalError("Motion's tests can't run because this Mac doesn't have any screens!")
        }
        return screen.animator
    }()
}
#endif
