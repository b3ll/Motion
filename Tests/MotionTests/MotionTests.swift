import XCTest

@testable import Motion

final class MotionTests: XCTestCase {

    // MARK: - EquatableEnough Tests

    func testApproximatelyEqual() {
        // Exactly Equal (or at least, should be).
        let equalValue1 = 0.001
        let equalValue2 = 0.001

        XCTAssert(equalValue1.approximatelyEqual(to: equalValue2) && (equalValue1 == equalValue2))

        // Mostly Equal
        let equalishValue3 = 0.0011

        XCTAssert(equalValue1.approximatelyEqual(to: equalishValue3))

        // Gotta love copy paste.
        // Would be neat to iterate over all the types, but I'm unsure how to do that.
        XCTAssert(SIMD2(repeating: equalValue1).approximatelyEqual(to: SIMD2(repeating: equalishValue3)))
        XCTAssert(SIMD3(repeating: equalValue1).approximatelyEqual(to: SIMD3(repeating: equalishValue3)))
        XCTAssert(SIMD4(repeating: equalValue1).approximatelyEqual(to: SIMD4(repeating: equalishValue3)))
        XCTAssert(SIMD8(repeating: equalValue1).approximatelyEqual(to: SIMD8(repeating: equalishValue3)))
        XCTAssert(SIMD16(repeating: equalValue1).approximatelyEqual(to: SIMD16(repeating: equalishValue3)))
        XCTAssert(SIMD32(repeating: equalValue1).approximatelyEqual(to: SIMD32(repeating: equalishValue3)))
        XCTAssert(SIMD64(repeating: equalValue1).approximatelyEqual(to: SIMD64(repeating: equalishValue3)))

        // Not Equal
        let nonEqualValue1 = 0.001
        let nonEqualValue2 = 0.002

        XCTAssertFalse(nonEqualValue1.approximatelyEqual(to: nonEqualValue2))

        XCTAssertFalse(SIMD2(repeating: nonEqualValue1).approximatelyEqual(to: SIMD2(repeating: nonEqualValue2)))
        XCTAssertFalse(SIMD3(repeating: nonEqualValue1).approximatelyEqual(to: SIMD3(repeating: nonEqualValue2)))
        XCTAssertFalse(SIMD4(repeating: nonEqualValue1).approximatelyEqual(to: SIMD4(repeating: nonEqualValue2)))
        XCTAssertFalse(SIMD8(repeating: nonEqualValue1).approximatelyEqual(to: SIMD8(repeating: nonEqualValue2)))
        XCTAssertFalse(SIMD16(repeating: nonEqualValue1).approximatelyEqual(to: SIMD16(repeating: nonEqualValue2)))
        XCTAssertFalse(SIMD32(repeating: nonEqualValue1).approximatelyEqual(to: SIMD32(repeating: nonEqualValue2)))
        XCTAssertFalse(SIMD64(repeating: nonEqualValue1).approximatelyEqual(to: SIMD64(repeating: nonEqualValue2)))

        // Less than
        XCTAssert(SIMD2(repeating: nonEqualValue1) < SIMD2(repeating: nonEqualValue2))
        XCTAssert(SIMD3(repeating: nonEqualValue1) < SIMD3(repeating: nonEqualValue2))
        XCTAssert(SIMD4(repeating: nonEqualValue1) < SIMD4(repeating: nonEqualValue2))
        XCTAssert(SIMD8(repeating: nonEqualValue1) < SIMD8(repeating: nonEqualValue2))
        XCTAssert(SIMD16(repeating: nonEqualValue1) < SIMD16(repeating: nonEqualValue2))
        XCTAssert(SIMD32(repeating: nonEqualValue1) < SIMD32(repeating: nonEqualValue2))
        XCTAssert(SIMD64(repeating: nonEqualValue1) < SIMD64(repeating: nonEqualValue2))
    }

    // MARK: - ValueAnimation Tests

    /// TODO

    // MARK: - SpringAnimation Tests

    func testSpring() {
        let spring = SpringAnimation(initialValue: CGRect.zero)
        spring.value = .zero
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
        spring.value = .zero
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
        spring.value = .zero
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
        spring.value = .zero
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)

        spring.onValueChanged(disableActions: true) { newValue in
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

        tickAnimationUntilResolved(spring)

        wait(for: [expectValueChangedCalled, expectCompletionCalled], timeout: 0.0)
    }

    // MARK: - DecayAnimation Tests

    func testDecay() {
        let decay = DecayAnimation<CGFloat>()
        decay.value = .zero
   
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

        tickAnimationUntilResolved(basicAnimation)

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

    // MARK: - AnimationGroup Tests

    func testAnimationGroup() {
        let expectBasicAnimationValueChangedCalled = XCTestExpectation(description: "Basic animation value changed")
        let expectBasicAnimationCompletionCalled = XCTestExpectation(description: "Basic animation completed")

        let basicAnimation = BasicAnimation<CGFloat>()
        basicAnimation.fromValue = 0.0
        basicAnimation.toValue = 10.0
        basicAnimation.duration = 1.0
        basicAnimation.onValueChanged { newValue in
            expectBasicAnimationValueChangedCalled.fulfill()
        }
        basicAnimation.completion = {
            expectBasicAnimationCompletionCalled.fulfill()
        }

        let expectSpringAnimationValueChangedCalled = XCTestExpectation(description: "Spring animation value changed")
        let expectSpringAnimationCompletionCalled = XCTestExpectation(description: "Spring animation completed")

        let spring = SpringAnimation(initialValue: CGFloat(0.0))
        spring.value = .zero
        spring.toValue = 320.0
        spring.onValueChanged { newValue in
            expectSpringAnimationValueChangedCalled.fulfill()
        }
        spring.completion = {
            expectSpringAnimationCompletionCalled.fulfill()
        }

        let expectAnimationGroupCompletionCalled = XCTestExpectation(description: "AnimationGroup completed")

        let animationGroup = AnimationGroup(basicAnimation, spring)
        animationGroup.completion = {
            expectAnimationGroupCompletionCalled.fulfill()
        }

        tickAnimationUntilResolved(animationGroup)

        wait(for: [expectBasicAnimationValueChangedCalled, expectBasicAnimationCompletionCalled, expectSpringAnimationValueChangedCalled, expectSpringAnimationCompletionCalled, expectAnimationGroupCompletionCalled], timeout: 0.0)
    }

    // MARK: - Animator Tests

    func testAnimatorAddRemoveAnimation() {
        let observedAnimationCount = Animator.shared.animationObservers.count

        var spring: SpringAnimation<CGFloat>? = SpringAnimation(initialValue: 0.0)
        XCTAssert(Animator.shared.animationObservers.count == observedAnimationCount + 1)

        spring = nil
        XCTAssert(Animator.shared.animationObservers.count == observedAnimationCount)

        // Suppresses "Variable 'spring' was written to, but never read"
        _ = spring
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.animationObservers.count == 0)
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

}

private func tickAnimationOnce(_ animation: Animation, dt: CFTimeInterval = 0.016) {
    animation.tick(dt)
}

private func tickAnimationUntilResolved(_ animation: Animation, dt: CFTimeInterval = 0.016, maxDuration: CFTimeInterval = 10.0) {
    for _ in stride(from: 0.0, through: maxDuration, by: dt) {
        animation.tick(dt)
        if animation.hasResolved() {
            break
        }
    }
}

private func tickAnimationForDuration(_ animation: Animation, dt: CFTimeInterval = 0.016, maxDuration: CFTimeInterval = 10.0) {
    for _ in stride(from: 0.0, through: maxDuration, by: dt) {
        animation.tick(dt)
    }
}
