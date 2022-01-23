//
//  SpringAnimation.swift
//
//
//  Created by Adam Bell on 7/12/20.
//

import Combine
import QuartzCore
import simd

/**
 This class provides the ability to animate `Value` using a physically-modeled spring.

 `value` will be animated towards `toValue` (optionally seeded with `velocity`) and depending on how the spring is configured, may bounce around the endpoint.

 Springs can be configured as underdamped, overdamped, or critically-damped, depending on the constants supplied for `stiffness` and `damping`.

 They can also be configured by specifying the `response` time and `dampingRatio`. These are recommended and easier to work with than `stiffness` and `damping`.
 For more information on these, check out the WWDC talk on fluid animations: https://developer.apple.com/videos/play/wwdc2018/803/

 Stopping a spring via `stop` allows for redirecting the spring any way you'd like (perhaps in a different direction or velocity).

 ```
 let springAnimation = SpringAnimation<CGRect>(initialValue: .zero)
 springAnimation.toValue = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
 springAnimation.configure(response: 0.4, dampingRatio: 0.8)
 // Setting a velocity in the opposite direction can be nice for causing a "pop-up" effect.
 springAnimation.velocity = CGRect(x: 0.0, y: 0.0, width: -1000.0, height: -1000.0)
 springAnimation.onValueChanged { newValue in
    view.frame = newValue
 }
 springAnimation.start()

 - Note: This class is **not** thread-safe. It is meant to be run on the **main thread** only (much like any AppKit / UIKit operations should be main threaded).
 ```
 */
public final class SpringAnimation<Value: SIMDRepresentable>: ValueAnimation<Value> where Value.SIMDType.Scalar == Value.SIMDType.SIMDType.Scalar {

    /// The velocity of the animation. Setting this before calling `start` will cause the spring animation to be seeded with that velocity, and then the velocity will decay over time.
    public override var velocity: Value {
         get {
            // We override velocity to be negative, since that's typically easier to reason about (i.e. touch velocity).
             return Value(-_velocity)
         }
         set {
            // See getter.
             self._velocity = -newValue.simdRepresentation()
         }
     }

    internal var spring: SpringFunction<Value.SIMDType>

    /*
     You may be wondering why -stiffness and -damping, etc. are only getters and can only be set by -configure(...)

     The issue is damping and dampingRatio are extremely easy to mixup (eventhough they are the correct terms) and I'd like to
     keep parity with how `CASpringAnimation`'s API is.
     */

    /**
     The stiffness coefficient of the string.
     This is meant to be paired with the `damping`.

     - Description: This may be changed using `configure(stiffness:damping:)`.
     */
    public var stiffness: Value.SIMDType.Scalar {
        return spring.stiffness
    }

    /**
     The damping amount of the spring.
     This is meant to be paired with the `stiffness`.

     - Description: This is equivalent to the friction of the spring. This may be changed using `configure(stiffness:damping:)`.
     */
    public var damping: Value.SIMDType.Scalar {
        return spring.damping
    }

    /**
     The response time of the spring (in seconds). This is used to change how long (approximately) it will take for the spring to reach its destination.
     This is meant to be paired with the `dampingRatio`. Changing this will override the `stiffness` and `damping` values.

     - Description: This may be changed using `configure(response:dampingRatio:)`.
     */
    public var response: Value.SIMDType.Scalar {
        return spring.response
    }

    /**
     The damping ratio of the spring ranging from `0.0` to `1.0`. This describes how much the spring should oscillate around its destination point.

     The supported values are as follows:
        - `0.0`: An infinitely oscillating spring.
        - `1.0`: A critically damped spring.
        - `0.0 < value > 1.0`: An underdamped spring.

     This is meant to be paired with the `dampingRatio`. Changing this will override the `stiffness` and `damping` values.

     - Description: This may be changed using `configure(response:dampingRatio:)`.
     */
    public var dampingRatio: Value.SIMDType.Scalar {
        return spring.dampingRatio
    }

    /**
     An optional range to clamp `value` to be within the specified upper and lower bound.

     If `value` ever exceeds the lower or upper bound, it will be capped to those values.

     - Description: This is useful for animations where you don't want the value to overshoot (i.e. changing the alpha on a view).
     Setting this to `0.0...1.0` will force the animation to never set `value` lower than `0.0` or higher than `1.0`.
     */
    public var clampingRange: ClosedRange<Value>? {
        get {
            if let clampingRange = _clampingRange {
                return Value(clampingRange.lowerBound)...Value(clampingRange.upperBound)
            } else {
                return nil
            }
        }
        set {
            if let newValue = newValue {
                self._clampingRange = newValue.lowerBound.simdRepresentation()...newValue.upperBound.simdRepresentation()
            } else {
                self._clampingRange = nil
            }
        }
    }
    internal var _clampingRange: ClosedRange<Value.SIMDType>? = nil

    /**
     When true, the animation will complete once `value` reaches `toValue` (regardless of velocity, overshoot, or rebounding). Defaults to `false`.

     - Note: This is particularly useful for dismissal animations (i.e. when you're throwing something offscreen, and want the completion to happen faster than waiting for the value to finish bouncing offscreen)
     */
    public var resolvesUponReachingToValue: Bool = false

    /**
     Initializes a `SpringAnimation` with an optional initial value.

     - Parameters:
        - initialValue: The value to start animating from.
     */
    public init(initialValue: Value = .zero) {
        self.spring = SpringFunction()
        super.init()
        self.value = initialValue
    }

    /**
     A convenience initializer to create a `SpringAnimation` with `stiffness` and `damping` constants.

     - Parameters:
        - stiffness: How stiff the spring should be.
        - damping: How much friction should be exerted on the spring.
     */
    public convenience init(initialValue: Value = .zero, stiffness: Value.SIMDType.Scalar, damping: Value.SIMDType.Scalar) {
        self.init(initialValue: initialValue)
        configure(stiffness: stiffness, damping: damping)
    }

    /**
     A convenience initializer to create a `SpringAnimation` with a given `response` and `dampingRatio`.

     - Parameters:
        - response: How long (approximately) it should take the spring to reach its destination (in seconds).
        - dampingRatio: How much the spring should bounce around its destination specified as a ratio from 0.0 (bounce forever) to 1.0 (don't bounce at all).
        The supported values are as follows:
          - `0.0`: An infinitely oscillating spring.
          - `1.0`: A critically damped spring.
          - `0.0 < value > 1.0`: An underdamped spring.

     - Note: For more information on how these values work, check out the WWDC talk on fluid animations: https://developer.apple.com/videos/play/wwdc2018/803/.
     */
    public convenience init(initialValue: Value = .zero, response: Value.SIMDType.Scalar, dampingRatio: Value.SIMDType.Scalar) {
        self.init(initialValue: initialValue)
        configure(response: response, dampingRatio: dampingRatio)
    }

    /**
     Convenience function to configure the `stiffness` and `damping` all at once.

     - Parameters:
        - stiffness: The stiffness coefficient of the string.
        - damping: The damping amount of the spring (friction).
     */
    public func configure(stiffness: Value.SIMDType.Scalar, damping: Value.SIMDType.Scalar) {
        spring.configure(stiffness: stiffness, damping: damping)
    }

    /**
     Convenience function to configure the `stiffness` and `damping` based on easier to work with constants.

     - Parameters:
        - response: How long (approximately) it should take the spring to reach its destination (in seconds).
        - dampingRatio: How much the spring should bounce around its destination specified as a ratio from 0.0 (bounce forever) to 1.0 (don't bounce at all).
        The supported values are as follows:
          - `0.0`: An infinitely oscillating spring.
          - `1.0`: A critically damped spring.
          - `0.0 <-> 1.0`: An underdamped spring.

     - Note: Configuring this spring via this method will override the values for `stiffness` and `damping`.
     - Description: For more info check out the WWDC talk on this: https://developer.apple.com/videos/play/wwdc2018/803/
     */
    public func configure(response: Value.SIMDType.Scalar, dampingRatio: Value.SIMDType.Scalar) {
        spring.configure(response: response, dampingRatio: dampingRatio)
    }

    /// Returns whether or not the spring animation has resolved. It is considered resolved when the `toValue` is reached, and `velocity` is zero.
    public override func hasResolved() -> Bool {
        let resolvedState = hasResolved(value: &_value, epsilon: &resolvingEpsilon, toValue: &_toValue, velocity: &_velocity)
        return resolvedState.valueResolved && resolvedState.velocityResolved
    }

    #if DEBUG
    internal func hasResolved<SIMDType: SupportedSIMD>(value: inout SIMDType, epsilon: inout SIMDType.EpsilonType, toValue: inout SIMDType, velocity: inout SIMDType) -> (valueResolved: Bool, velocityResolved: Bool) {
        /* Must Be Mirrored Below */

        let valueResolved = value.approximatelyEqual(to: toValue, epsilon: epsilon)
        if !valueResolved {
            return (false, false)
        }

        if resolvesUponReachingToValue {
            return (valueResolved, true)
        }

        let velocityResolved = velocity.approximatelyEqual(to: .zero, epsilon: epsilon)
        return (valueResolved, velocityResolved)
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
    internal func hasResolved<SIMDType: SupportedSIMD>(value: inout SIMDType, epsilon: inout SIMDType.EpsilonType, toValue: inout SIMDType, velocity: inout SIMDType) -> (valueResolved: Bool, velocityResolved: Bool) {
        /* Must Be Mirrored Above */
        
        let valueResolved = value.approximatelyEqual(to: toValue, epsilon: epsilon)
        if !valueResolved {
            return (false, false)
        }

        if resolvesUponReachingToValue {
            return (valueResolved, true)
        }

        let velocityResolved = velocity.approximatelyEqual(to: .zero, epsilon: epsilon)
        return (valueResolved, velocityResolved)
    }
    #endif

    /**
     Stops the animation and optionally resolves it immediately (jumping to the `toValue`).

     - Parameters:
        - resolveImmediately: Whether or not the animation should jump to the `toValue` without animation and invoke the completion. Defaults to `false`.
        - postValueChanged: If `true` is supplied for `resolveImmediately`, this controls whether not `valueChanged` is called upon changing `value` to `toValue`.
     */
    public override func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        super.stop(resolveImmediately: resolveImmediately, postValueChanged: postValueChanged)
        self.velocity = .zero
    }

    // MARK: - AnimationDriverObserver

    public override func tick(frame: AnimationFrame) {
        tickOptimized(Value.SIMDType.Scalar(frame.duration), spring: &spring, value: &_value, toValue: &_toValue, velocity: &_velocity, clampingRange: &_clampingRange)

        _valueChanged?(value)

        let resolvedState = hasResolved(value: &_value, epsilon: &resolvingEpsilon, toValue: &_toValue, velocity: &_velocity)

        if resolvedState.valueResolved && resolvedState.velocityResolved {
            stop()

            self.value = toValue
            _valueChanged?(value)

            completion?()
        }
    }

    /*
     This looks hideous, yes, but it forces the compiler to generate specialized versions (where the type is hardcoded) of the spring evaluation function.
     Normally this would be specialized, but because of the dynamic dispatch of -tick:, it fails to specialize. There may be a workaround for this, but as of right now I haven't found a solution.
     By specializing manually, we forcefully generate implementations of this method hardcoded for each SIMD type specified.
     Whilst this does incur a codesize penalty, this results in a performance boost of more than **+100%**.
     Note that this optimization only happens on Release builds as building constantly for Debug is fairly slow.
     */
    #if DEBUG
    internal func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType.Scalar, spring: inout SpringFunction<SIMDType>, value: inout SIMDType, toValue: inout SIMDType, velocity: inout SIMDType, clampingRange: inout ClosedRange<SIMDType>?) where SIMDType.Scalar == SIMDType.SIMDType.Scalar {
        /* Must Be Mirrored Below */

        let x0 = toValue - value

        let x = spring.solve(dt: dt, x0: x0, velocity: &velocity)

        value = toValue - x

        if let clampingRange = clampingRange {
            value.clamp(lowerBound: clampingRange.lowerBound, upperBound: clampingRange.upperBound)
        }
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
    internal func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType.Scalar, spring: inout SpringFunction<SIMDType>, value: inout SIMDType, toValue: inout SIMDType, velocity: inout SIMDType, clampingRange: inout ClosedRange<SIMDType>?) where SIMDType.Scalar == SIMDType.SIMDType.Scalar {
        /* Must Be Mirrored Above */

        let x0 = toValue - value

        let x = spring.solve(dt: dt, x0: x0, velocity: &velocity)

        value = toValue - x

        if let clampingRange = clampingRange {
            value.clamp(lowerBound: clampingRange.lowerBound, upperBound: clampingRange.upperBound)
        }
    }

    #endif

}
