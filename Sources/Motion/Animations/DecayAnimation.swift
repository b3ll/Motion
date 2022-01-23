//
//  DecayAnimation.swift
//  
//
//  Created by Adam Bell on 8/20/20.
//

import Foundation
import simd

/**
 This class provides the ability to animate types that conform to `Value` based on decay functions.

 The starting from `value`, the value will increase or decrease (depending on the `velocity` supplied) and will slow to a stop.
 This essentially provides the same "decaying" that `UIScrollView` does when you drag and let go. The animation is seeded with velocity, and that velocity decays over time.

 ```
 let decayAnimation = DecayAnimation<CGPoint>()
 decayAnimation.velocity = CGPoint(x: 2000.0, y: -2000.0)
 decayAnimation.onValueChanged { newValue in
    // Simulates scrolling a view.
    someView.bounds.origin = newValue
 }
 decayAnimation.start()
 ```

 - Note: This class is **not** thread-safe. It is meant to be run on the **main thread** only (much like any AppKit / UIKit operations should be main threaded).
*/
public final class DecayAnimation<Value: SIMDRepresentable>: ValueAnimation<Value> where Value.SIMDType.Scalar == Value.SIMDType.SIMDType.Scalar {

    /// The decay constant. This defaults to `UIScrollViewDecayConstant`.
    public var decayConstant: Value.SIMDType.Scalar {
        set {
            decay.decayConstant = newValue
        }
        get {
            return decay.decayConstant
        }
    }

    internal var decay: DecayFunction<Value.SIMDType>

    /// Returns whether or not the animation has resolved. It is considered resolved when its velocity reaches zero.
    public override func hasResolved() -> Bool {
        return hasResolved(velocity: &_velocity)
    }

    #if DEBUG
    internal func hasResolved<SIMDType: SupportedSIMD>(velocity: inout SIMDType) -> Bool {
        /* Must Be Mirrored Below */

        // The original implementation of this had mabs(velocity) .< Value.SIMDType(repeating: 0.5)
        // However we really only need to check the min and max and it's significantly faster.
        return abs(velocity.max()) < 0.5 && abs(velocity.min()) < 0.5
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
    internal func hasResolved<SIMDType: SupportedSIMD>(velocity: inout SIMDType) -> Bool {
        /* Must Be Mirrored Above */

        // The original implementation of this had mabs(velocity) .< Value.SIMDType(repeating: 0.5)
        // However we really only need to check the min and max and it's significantly faster.
        return abs(velocity.max()) < 0.5 && abs(velocity.min()) < 0.5
    }
    #endif

    /**
     Initializes a `DecayAnimation` with an initial value and decay constant.

     - Parameters:
        - initialValue: The initial value to be set for `value`.
        - decayConstnat: The decay constant. Defaults to `UIScrollViewDecayConstant`.
     */
    public init(initialValue: Value = .zero, decayConstant: Value.SIMDType.Scalar = Value.SIMDType.Scalar(UIScrollViewDecayConstant)) {
        self.decay = DecayFunction(decayConstant: decayConstant)
        super.init()
        self.value = initialValue
    }

    /**
     Stops the animation and optionally resolves it immediately.

     - Parameters:
        - resolveImmediately: Whether or not the animation should jump to zero `velocity` and invoke the completion. Defaults to `false`.
        - postValueChanged: If `true` is supplied for `resolveImmediately`, this controls whether not `valueChanged` is called upon changing `value` to the end value.

     - Note: `resolveImmediately` and `postValueChanged` currently are ignored.
     They will be implemented at a later date when the logic for projecting decaying functions is worked out.
     */
    public override func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        // We don't call super here, as jumping to the end requires knowing the end point, and we don't know that (yet).
        self.enabled = false
        self.velocity = .zero

        if resolveImmediately {
            completion?()
        }
    }

    // MARK: - Disabled API

    @available(*, unavailable, message: "Not supported in DecayAnimation.")
    public override var toValue: Value {
        get { return .zero }
        set { }
    }

    // MARK: - AnimationDriverObserver

    public override func tick(frame: AnimationFrame) {
        tickOptimized(Value.SIMDType.Scalar(frame.duration), decay: &decay, value: &_value, velocity: &_velocity)

        _valueChanged?(value)

        if hasResolved(velocity: &_velocity) {
            stop()

            completion?()
        }
    }

    // See docs in SpringAnimation.swift for why this exists.
    #if DEBUG
    internal func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType.SIMDType.Scalar, decay: inout DecayFunction<SIMDType>, value: inout SIMDType, velocity: inout SIMDType) {
        /* Must Be Mirrored Below */
        
        value = decay.solve(dt: dt, x0: value, velocity: &velocity)
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
    internal func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType.SIMDType.Scalar, decay: inout DecayFunction<SIMDType>, value: inout SIMDType, velocity: inout SIMDType) {
        /* Must Be Mirrored Above */

        value = decay.solve(dt: dt, x0: value, velocity: &velocity)
    }
    #endif

}
