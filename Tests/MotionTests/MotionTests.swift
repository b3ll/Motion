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

    // MARK: - AnyAnimation Tests

    func testAnyAnimationEquality() {
        let spring = SpringAnimation(0.0)
        let spring2 = SpringAnimation(0.0)

        XCTAssertEqual(AnyAnimation(spring), AnyAnimation(spring))
        XCTAssertNotEqual(AnyAnimation(spring), AnyAnimation(spring2))
    }

    func testAnyAnimationTick() {
        let spring = SpringAnimation(0.0)
        spring.toValue = 10.0

        let expectCompletionCalled = XCTestExpectation(description: "Spring finished animating to \(spring.toValue)")
        spring.completion = {
            expectCompletionCalled.fulfill()
        }

        tickAnyAnimationForDuration(AnyAnimation(spring))

        wait(for: [expectCompletionCalled], timeout: 0.0)
    }

    // MARK: - Animation Tests

    func testSpring() {
        let spring = SpringAnimation(CGRect.zero)
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
        let spring = SpringAnimation(CGRect.zero)
        spring.value = .zero
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)
        spring.configure(response: 1.0, damping: 1.0)

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

    func testSpringVelocitySetting() {
        let spring = SpringAnimation(0.0)
        spring.velocity = 100.0

        // Spring velocity is inversed for internal calculations.
        XCTAssertEqual(Double(spring._velocity), -100.0)
    }

    func testSpringActionsDisabled() {
        let spring = SpringAnimation(CGRect.zero)
        spring.value = .zero
        spring.toValue = CGRect(x: 0, y: 0, width: 320, height: 320)

        spring.valueChanged(disableActions: true) { newValue in
            XCTAssert(CATransaction.disableActions())
        }

        tickAnimationOnce(spring)
    }

    func testSpringValueClamping() {
        let spring = SpringAnimation(0.0)
        spring.toValue = 1.0

        let clampingRange = 0.0...1.0
        spring.clampingRange = clampingRange

        spring.valueChanged { newValue in
            XCTAssert(clampingRange.contains(newValue))
        }

        tickAnimationUntilResolved(spring)
    }

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

    // MARK: - Animator Tests

    func testAnimatorAddRemoveAnimation() {
        let observedAnimationCount = Animator.shared.animationObservers.count

        var spring: SpringAnimation<CGFloat>? = SpringAnimation(0.0)
        XCTAssert(Animator.shared.animationObservers.count == observedAnimationCount + 1)

        spring = nil
        XCTAssert(Animator.shared.animationObservers.count == observedAnimationCount)

        // Suppresses "Variable 'spring' was written to, but never read"
        _ = spring
    }

    func testPushback() {
        let spring = SpringAnimation<CGFloat>(0.97)
        spring.configure(response: 0.30, damping: 0.99)
        spring.toValue = 1.0

        for _ in stride(from: 0, to: 3, by: 1.0 / 60.0) {
            spring.tick(1.0 / 60.0)
        }
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.animationObservers.count == 0)
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

    static var allTests = [
        ("testApproximatelyEqual", testApproximatelyEqual),
        ("testAnyAnimationEquality", testAnyAnimationEquality),
        ("testAnyAnimationTick", testAnyAnimationTick),
//        ("testAnimationDtFailure", testAnimationDtFailure),
        ("testSpring", testSpring),
        ("testSpringVelocitySetting", testSpringVelocitySetting),
        ("testSpring", testSpringActionsDisabled),
        ("testDecay", testDecay),
        ("testAnimatorAddRemoveAnimation", testAnimatorAddRemoveAnimation),
    ]

}

private func tickAnimationOnce<Value: SIMDRepresentable>(_ animation: Animation<Value>, dt: CFTimeInterval = 0.016) {
    animation.tick(dt)
}

private func tickAnimationUntilResolved<Value: SIMDRepresentable>(_ animation: Animation<Value>, dt: CFTimeInterval = 0.016, maxDuration: CFTimeInterval = 10.0) {
    for _ in stride(from: 0.0, through: maxDuration, by: dt) {
        animation.tick(dt)
        if animation.hasResolved() {
            break
        }
    }
}

private func tickAnyAnimationForDuration(_ animation: AnyAnimation, dt: CFTimeInterval = 0.016, maxDuration: CFTimeInterval = 10.0) {
    for _ in stride(from: 0.0, through: maxDuration, by: dt) {
        animation.tick(dt)
    }
}
