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

        // Equal within Custom Epsilon
        let nonEqualValue3 = 0.001
        let nonEqualValue4 = 0.002
        let epsilon = 0.01

        XCTAssertTrue(nonEqualValue3.approximatelyEqual(to: nonEqualValue4, epsilon: epsilon))

        XCTAssertTrue(SIMD2(repeating: nonEqualValue3).approximatelyEqual(to: SIMD2(repeating: nonEqualValue4), epsilon: epsilon))
        XCTAssertTrue(SIMD3(repeating: nonEqualValue3).approximatelyEqual(to: SIMD3(repeating: nonEqualValue4), epsilon: epsilon))
        XCTAssertTrue(SIMD4(repeating: nonEqualValue3).approximatelyEqual(to: SIMD4(repeating: nonEqualValue4), epsilon: epsilon))
        XCTAssertTrue(SIMD8(repeating: nonEqualValue3).approximatelyEqual(to: SIMD8(repeating: nonEqualValue4), epsilon: epsilon))
        XCTAssertTrue(SIMD16(repeating: nonEqualValue3).approximatelyEqual(to: SIMD16(repeating: nonEqualValue4), epsilon: epsilon))
        XCTAssertTrue(SIMD32(repeating: nonEqualValue3).approximatelyEqual(to: SIMD32(repeating: nonEqualValue4), epsilon: epsilon))
        XCTAssertTrue(SIMD64(repeating: nonEqualValue3).approximatelyEqual(to: SIMD64(repeating: nonEqualValue4), epsilon: epsilon))
    }

    // MARK: - SIMDRepresentable Tests

    func testSIMDRepresentableScalarTypes() {
        let a: Float = 10.0
        let simdA = a.simdRepresentation()
        XCTAssertTrue(a.approximatelyEqual(to: simdA[0]))
        XCTAssertTrue(simdA[1].approximatelyEqual(to: 0.0))

        let b: Double = 20.0
        let simdB = b.simdRepresentation()
        XCTAssertTrue(b.approximatelyEqual(to: simdB[0]))
        XCTAssertTrue(simdB[1].approximatelyEqual(to: 0.0))

        let c: CGFloat = 30.0
        let simdC = c.simdRepresentation()
        XCTAssertTrue(c.approximatelyEqual(to: CGFloat(simdC[0])))
        XCTAssertTrue(simdC[1].approximatelyEqual(to: 0.0))
    }

    func testSIMDRepresentableCoreGraphicsTypes() {
        let point = CGPoint(x: 10.0, y: 20.0)
        let simdPoint = point.simdRepresentation()

        XCTAssertTrue(point.x.approximatelyEqual(to: CGFloat(simdPoint[0])))
        XCTAssertTrue(point.y.approximatelyEqual(to: CGFloat(simdPoint[1])))
        XCTAssertEqual(point, CGPoint(simdPoint))

        let size = CGSize(width: 30.0, height: 40.0)
        let simdSize = size.simdRepresentation()

        XCTAssertTrue(size.width.approximatelyEqual(to: CGFloat(simdSize[0])))
        XCTAssertTrue(size.height.approximatelyEqual(to: CGFloat(simdSize[1])))
        XCTAssertEqual(size, CGSize(simdSize))

        let rect = CGRect(origin: point, size: size)
        let simdRect = rect.simdRepresentation()

        XCTAssertTrue(rect.origin.x.approximatelyEqual(to: CGFloat(simdRect[0])))
        XCTAssertTrue(rect.origin.y.approximatelyEqual(to: CGFloat(simdRect[1])))
        XCTAssertTrue(rect.size.width.approximatelyEqual(to: CGFloat(simdRect[2])))
        XCTAssertTrue(rect.size.height.approximatelyEqual(to: CGFloat(simdRect[3])))
        XCTAssertEqual(rect, CGRect(simdRect))
    }

    // MARK: - ValueAnimation Tests

    /// TODO

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

    // MARK: - RubberBanding Tests

    func testRubberBandingScalar() {
        let insideValue: CGFloat = 50.0
        let outsideValueNegative: CGFloat = -10.0
        let outsideValuePositive: CGFloat = 110.0
        let boundsSize: CGFloat = 100.0
        let contentSize: CGFloat = 200.0

        let nonRubberbandedValue = rubberband(insideValue, boundsSize: boundsSize, contentSize: contentSize)

        // Is the value within the clamped range.
        XCTAssertTrue(nonRubberbandedValue.approximatelyEqual(to: insideValue))

        // Does it handle values less than the range.
        let rubberbandedValueNegative = rubberband(outsideValueNegative, boundsSize: boundsSize, contentSize: contentSize)
        XCTAssertTrue(rubberbandedValueNegative.approximatelyEqual(to: -5.213))

        // Does it handle values more than the range.
        let rubberbandedValuePositive = rubberband(outsideValuePositive, boundsSize: boundsSize, contentSize: contentSize)
        XCTAssertTrue(rubberbandedValuePositive.approximatelyEqual(to: 105.213 /* value + boundsSize ~= 205.213 */))

        // Does it handle both positive and negative values correctly?
        let deltaNegative = abs(rubberbandedValueNegative)
        let deltaPositive = abs(rubberbandedValuePositive - boundsSize)
        XCTAssertTrue(deltaNegative.approximatelyEqual(to: deltaPositive))
    }

    override class func tearDown() {
        // All the animations should be deallocated by now. Hopefully NSMapTable plays nice.
        XCTAssert(Animator.shared.animationObservers.count == 0)
        XCTAssert(Animator.shared.runningAnimations.allObjects.count == 0)
    }

}

internal func tickAnimationOnce(_ animation: Animation, dt: CFTimeInterval = 0.016) {
    animation.tick(frame: .init(timestamp: 0, targetTimestamp: dt))
}

internal func tickAnimationUntilResolved(_ animation: Animation, dt: CFTimeInterval = 0.016, maxDuration: CFTimeInterval = 10.0) {
    for _ in stride(from: 0.0, through: maxDuration, by: dt) {
        animation.tick(frame: .init(timestamp: 0, targetTimestamp: dt))
        if animation.hasResolved() {
            break
        }
    }
}

internal func tickAnimationForDuration(_ animation: Animation, dt: CFTimeInterval = 0.016, maxDuration: CFTimeInterval = 10.0) {
    for _ in stride(from: 0.0, through: maxDuration, by: dt) {
        animation.tick(frame: .init(timestamp: 0, targetTimestamp: dt))
    }
}
