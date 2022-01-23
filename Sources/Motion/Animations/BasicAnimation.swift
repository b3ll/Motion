//
//  BasicAnimation.swift
//  
//
//  Created by Adam Bell on 8/27/20.
//

import Foundation
import simd

/**
 This class provides the ability to animate types that conform to `Value` based on basic curves (i.e. `EasingFunction.easeIn`, `EasingFunction.easeInOut`, etc.).

 It animates values by interpolating from the `fromValue` to the `toValue` over the supplied `duration` using the supplied `easingFunction`.

 ```
 let animation = BasicAnimation<CGFloat>(easingFunction: .easeInOut)
 animation.fromValue = 0.0
 animation.toValue = 100.0
 animation.duration = 0.33
 animation.onValueChanged { newValue in
    // view.frame.origin.x = newValue
 }
 animation.start()
 ```
 
 - Note: This class is **not** thread-safe. It is meant to be run on the **main thread** only (much like any AppKit / UIKit operations should be main threaded).
 */
public final class BasicAnimation<Value: SIMDRepresentable>: ValueAnimation<Value> where Value.SIMDType.Scalar == Value.SIMDType.SIMDType.Scalar {

    /// The starting point of the animation. Defaults to `.zero`.
    public var fromValue: Value {
        get {
            return Value(_fromValue)
        }
        set {
            self._fromValue = newValue.simdRepresentation()
            updateRange()
        }
    }
    internal var _fromValue: Value.SIMDType = .zero {
        didSet {
            updateRange()
        }
    }

    internal override var _toValue: Value.SIMDType {
        didSet {
            updateRange()
        }
    }

    internal var _range: ClosedRange<Value.SIMDType> = Value.SIMDType.zero...Value.SIMDType.zero

    /**
     How long, in seconds, the animation should take.

     - Note: Supplying negative values here
     */
    public var duration: CFTimeInterval = 0.3

    /// The easing function the animation should use. For example: `.easeIn` starts out slow, and then speeds up, whereas `.linear` is constant speed.
    public var easingFunction: EasingFunction<Value.SIMDType> = .linear

    internal var accumulatedTime: CFTimeInterval = 0.0

    /**
     Initializes a `BasicAnimation` with an `EasingFunction`.

     - Parameters:
        - easingFunction: The easing function the animation should use.
     */
    public init(easingFunction: EasingFunction<Value.SIMDType> = .linear) {
        self.easingFunction = easingFunction
        super.init()
    }

    override public func start() {
        attemptToUpdateAccumulatedTimeToMatchValue()

        super.start()
    }

    #if DEBUG
    internal func solveAccumulatedTime<SIMDType: SupportedSIMD>(easingFunction: inout EasingFunction<SIMDType>, range: inout ClosedRange<SIMDType>, value: inout SIMDType) -> CFTimeInterval? {
        /* Must Be Mirrored Below */
        
        if !range.contains(value) {
            return nil
        }

        return easingFunction.solveAccumulatedTime(range, value: value)
    }
    #else
    @_specialize(kind: partial, where SIMDType == SIMD2<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD2<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD3<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD3<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD4<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD4<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD8<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD8<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD16<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD16<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD32<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD32<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD64<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD64<Double>)
    internal func solveAccumulatedTime<SIMDType: SupportedSIMD>(easingFunction: inout EasingFunction<SIMDType>, range: inout ClosedRange<SIMDType>, value: inout SIMDType) -> CFTimeInterval? {
        /* Must Be Mirrored Above */

        if !range.contains(value) {
            return nil
        }

        return easingFunction.solveAccumulatedTime(range, value: value)
    }
    #endif

    /**
     If the value isn't the fromValue, or the toValue, it might've been changed via `-updateValue(to:postValueChanged:)`.
     Since starting the animation from that point doesn't make much sense (i.e. if animating from 1 to 3, and you set the value to 2.5 and the duration is 3s, it'll animate from 2.5 to 3 in 3s, which isn't expected).
     If this is the case, we can determine whereabouts we are in the animation and continue logically from that time (i.e. 2.5 to 3, would probably only take 0.5s).

     If the value is outside the range, or we can't determine what it should be, we'll just start from the beginning, since that's already an unexpected state.
     */
    internal func attemptToUpdateAccumulatedTimeToMatchValue() {
        if !_value.approximatelyEqual(to: _fromValue, epsilon: resolvingEpsilon) && !_value.approximatelyEqual(to: _toValue, epsilon: resolvingEpsilon) {
            // Try to find out where we are in the animation.
            if let accumulatedTime = solveAccumulatedTime(easingFunction: &easingFunction, range: &_range, value: &_value) {
                self.accumulatedTime = accumulatedTime * duration
            } else {
                // Unexpected state, reset to beginning of animation.
                reset(postValueChanged: false)
            }
        } else {
            // We're starting this animation fresh, so ensure all state is correct.
            reset(postValueChanged: false)
        }
    }

    /**
     Stops the animation and optionally resolves it immediately (jumping to the `toValue`).

     - Parameters:
        - resolveImmediately: Whether or not the animation should jump to the `toValue` without animation and invoke the completion. Defaults to `false`.
        - postValueChanged: If `true` is supplied for `resolveImmediately`, this controls whether not `valueChanged` is called upon changing `value` to `toValue`.
     */
    public override func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        super.stop(resolveImmediately: resolveImmediately, postValueChanged: postValueChanged)
    }

    /// Stops and resets the animation back to its `fromValue` position and resets the elapsed time to zero.
    public func reset(postValueChanged: Bool = false) {
        stop()
        self.accumulatedTime = 0.0
        self._value = _fromValue
        if postValueChanged {
            _valueChanged?(value)
        }
    }

    /// Returns whether or not this animation has resolved.
    public override func hasResolved() -> Bool {
        return hasResolved(value: &_value, epsilon: &resolvingEpsilon, toValue: &_toValue)
    }

    #if DEBUG
    internal func hasResolved<SIMDType: SupportedSIMD>(value: inout SIMDType, epsilon: inout SIMDType.EpsilonType, toValue: inout SIMDType) -> Bool {
        /* Must Be Mirrored Below */

        return value.approximatelyEqual(to: toValue, epsilon: epsilon)
    }
    #else
    @_specialize(kind: partial, where SIMDType == SIMD2<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD2<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD3<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD3<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD4<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD4<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD8<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD8<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD16<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD16<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD32<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD32<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD64<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD64<Double>)
    internal func hasResolved<SIMDType: SupportedSIMD>(value: inout SIMDType, epsilon: inout SIMDType.EpsilonType, toValue: inout SIMDType) -> Bool {
        /* Must Be Mirrored Above */

        return value.approximatelyEqual(to: toValue, epsilon: epsilon)
    }
    #endif

    fileprivate func updateRange() {
        _range = _fromValue..._toValue
    }

    // MARK: - Disabled API

    @available(*, unavailable, message: "Not Supported in BasicAnimation.")
    public override var velocity: Value {
        get { return .zero }
        set { }
    }

    // MARK: - AnimationDriverObserver

    public override func tick(frame: AnimationFrame) {
        if duration.approximatelyEqual(to: 0.0) {
            stop(resolveImmediately: true, postValueChanged: true)
            return
        }

        accumulatedTime += frame.duration

        let fraction = min(max(0.0, accumulatedTime / duration), 1.0)

        tickOptimized(easingFunction: &easingFunction, range: &_range, fraction: Value.SIMDType.Scalar(fraction), value: &_value)

        _valueChanged?(value)

        if hasResolved(value: &_value, epsilon: &resolvingEpsilon, toValue: &_toValue) {
            stop()

            completion?()
        }
    }

    // See docs in SpringAnimation.swift for why this `@_specialize` stuff exists.
    #if DEBUG
    internal func tickOptimized<SIMDType: SupportedSIMD>(easingFunction: inout EasingFunction<SIMDType>, range: inout ClosedRange<SIMDType>, fraction: SIMDType.Scalar, value: inout SIMDType) where SIMDType.Scalar == SIMDType.SIMDType.Scalar {
        /* Must Be Mirrored Below */

        value = easingFunction.solveInterpolatedValue(range, fraction: fraction)
    }
    #else
    @_specialize(kind: partial, where SIMDType == SIMD2<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD2<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD3<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD3<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD4<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD4<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD8<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD8<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD16<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD16<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD32<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD32<Double>)
    @_specialize(kind: partial, where SIMDType == SIMD64<Float>)
    @_specialize(kind: partial, where SIMDType == SIMD64<Double>)
    internal func tickOptimized<SIMDType: SupportedSIMD>(easingFunction: inout EasingFunction<SIMDType>, range: inout ClosedRange<SIMDType>, fraction: SIMDType.Scalar, value: inout SIMDType) where SIMDType.Scalar == SIMDType.SIMDType.Scalar {
        /* Must Be Mirrored Above */

        value = easingFunction.solveInterpolatedValue(range, fraction: fraction)
    }
    #endif
    
}
