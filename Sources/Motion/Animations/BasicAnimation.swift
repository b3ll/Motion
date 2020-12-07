//
//  BasicAnimation.swift
//  
//
//  Created by Adam Bell on 8/27/20.
//

import Foundation
import simd

/**
 This class provides the ability to animate values based on basic curves (i.e. `EasingFunction.easeIn`, `EasingFunction.easeInOut`, etc.).

 It animates values by interpolating from the `fromValue` to the `toValue` over the supplied `duration` using the supplied `easingFunction`.
 */
public final class BasicAnimation<Value: SIMDRepresentable>: ValueAnimation<Value> {

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

    private var accumulatedTime: CFTimeInterval = 0.0

    /**
     Stops the animation and optionally resolves it immediately (jumping to the `toValue`).

     - Parameters:
        - resolveImmediately: Whether or not the animations should jump to the `toValue` without animation. Defaults to `false`.
        - postValueChanged: If `true` is supplied for `resolveImmediately`, this controls whether not `valueChanged` upon changing `value` to toValue`.
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
        return hasResolved(value: &_value)
    }

    internal func hasResolved(value: inout Value.SIMDType) -> Bool {
        return value.approximatelyEqual(to: _toValue)
    }

    fileprivate func updateRange() {
        _range = _fromValue..._toValue
    }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {
        if duration.approximatelyEqual(to: 0.0) {
            stop(resolveImmediately: true, postValueChanged: true)
            return
        }

        let fraction = accumulatedTime / duration

        tickOptimized(easingFunction: &easingFunction, range: &_range, fraction: Value.SIMDType.SIMDType.Scalar(fraction), value: &_value)

        _valueChanged?(value)

        accumulatedTime += dt

        if hasResolved() {
            stop()

            completion?()
        }
    }

    // See docs in SpringAnimation.swift for why this `@_specialize` stuff exists.
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
    internal func tickOptimized<SIMDType: SupportedSIMD>(easingFunction: inout EasingFunction<SIMDType>, range: inout ClosedRange<SIMDType>, fraction: SIMDType.SIMDType.Scalar, value: inout SIMDType) {
        value = easingFunction.solve(range, fraction: fraction)
    }
    
}
