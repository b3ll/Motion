import XCTest

@testable import Motion

final class BasicAnimationTests: XCTestCase {

    // MARK: - BasicAnimation Tests

    func testBasicAnimation() {
        let basicAnimation = BasicAnimation<CGFloat>()
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

        tickAnimationUntilResolved(basicAnimation)

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

        XCTAssertTrue(timeAccumulated.approximatelyEqual(to: timeAccumulatedDeterminedFromValue))

        let expectBasicAnimationCompletionCalled = XCTestExpectation(description: "Basic animation completed")
        basicAnimation.completion = {
            expectBasicAnimationCompletionCalled.fulfill()
        }

        tickAnimationForDuration(basicAnimation, maxDuration: 1.0)

        wait(for: [expectBasicAnimationCompletionCalled], timeout: 0.0)
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.animationObservers.count == 0)
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

}
