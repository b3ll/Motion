//
//  Animation.swift
//  
//
//  Created by Adam Bell on 8/19/20.
//

import Combine
import Foundation
import QuartzCore

/**
 This class acts as the base class for all animations within `Motion`. It doesn't do much, other than serve as a base class for all animations to inherit from and implement.

 An animation is something that can be ticked from `AnimationDriverObserver` and must resolve at some point.

 - Note: This class is **not** thread-safe. It is meant to be run on the **main thread** only (much like any AppKit / UIKit operations should be main threaded).
 - SeeAlso: `ValueAnimation`
 */
public class Animation: AnimationDriverObserver {

    /**
    Whether or not this animation is running.
    - Note: Calling `start` or `stop` enables (or disables) this value. Animations will only run when this is `true` and `hasResolved` is false.
    */
    @Published public var enabled: Bool = false

    /**
     A completion block to be called when the animation completes successfully.
     - Note: Be careful to not introduce any retain cycles by referencing self inside of here. `unowned` or `weak` instances of self are viable.
     */
    public var completion: (() -> Void)? = nil

    /// Default initializer. Animations must be strongly held to continue to animate.
    public init() {
        Animator.shared.observe(self)
    }

    deinit {
        Animator.shared.unobserve(self)
    }

    /// Starts the animation if `hasResolved` is false.
    public func start() {
        if hasResolved() {
            return
        }

        self.enabled = true
    }

    /**
     Stops the animation immediately.

     - Parameters:
     - resolveImmediately: Whether or not the animation should jump to its end state.
     - postValueChanged: Whether or not value changes will be posted.
     */
    public func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        self.enabled = false
    }

    /// Determines whether or not the animation should be considered resolved, or at rest.
    public func hasResolved() -> Bool {
        fatalError("Subclasses must override this")
    }

    // MARK: - AnimationDriverObserver

    /// Called by `AnimationDriverObserver` to advance the animation by the specified time interval `dt` (correlating with the framerate of the display).
    public func tick(frame: AnimationFrame) {
        fatalError("Subclasses must override this")
    }

}

/**
 This class provides the ability to animate changes to values (`Value`) over time.

 The interesting part of this is the ability to have animations on the value performed simultaneously using `simd` registers.

 i.e. a `CGRect` that's animating will have all of its values animated simultaneously (vs. each value being animated sequentially), which should be more performant.

 This is normally accomplished by setting an initial state for the animation (`value`) and then setting a target (`toValue`) to animate to.

 This class, when ticked, will change a value and emit changes to that value via `onValueChanged`.
 If you wish to update the value manually, you may also do so via `updateValue(to:postValueChanged:)`.

 When resolved, this class will optionally call the `completionBlock`.

 - Note: The base implementation of this class is not meant to be used on its own, rather subclasses provided are to be used.
 - Note: This class is **not** thread-safe. It is meant to be run on the **main thread** only (much like any AppKit / UIKit operations should be main threaded).
 - SeeAlso: `BasicAnimation`, `DecayAnimation`, `SpringAnimation`.
 */
public class ValueAnimation<Value: SIMDRepresentable>: Animation where Value.SIMDType.Scalar == Value.SIMDType.SIMDType.Scalar {

    /**
     A block to be called when `value` changes.

     - Parameters:
        - The new value of `value`.
     */
    public typealias ValueChangedCallback = ((Value) -> Void)

    internal(set) public var value: Value {
        get {
            return Value(_value)
        }
        set {
            self._value = newValue.simdRepresentation()
        }
    }
    internal var _value: Value.SIMDType = .zero

    /**
     Updates `value` to the supplied value and optionally invokes `onValueChanged`.

     - Parameters:
        - value: The new value to updated to.
        - postValueChanged: Whether or not `onValueChanged` should be called for this change.
     */
    public func updateValue(to value: Value, postValueChanged: Bool = false) {
        self.value = value
        if postValueChanged {
            _valueChanged?(value)
        }
    }

    /**
     The target value to animate towards.
     - Note: Not all animations use this as it doesn't always make sense. They will have this explicitly disabled.
     */
    public var toValue: Value {
        get {
            return Value(_toValue)
        }
        set {
            self._toValue = newValue.simdRepresentation()
        }
    }
    internal var _toValue: Value.SIMDType = .zero

    /**
     The velocity of the animation. Setting this before calling `start` will cause the animation to be seeded with that velocity, and then the velocity may change over time.

     - Note: Not all animations consider velocity. In those cases, subclasses should mark this as unavailable and `supportsVelocity` should be overriden to return `false`.
     */
    public var velocity: Value {
        get {
            return Value(_velocity)
        }
        set {
            self._velocity = newValue.simdRepresentation()
        }
    }
    internal var _velocity: Value.SIMDType = .zero

    /// Returns whether or not this class supports velocity.
    public class var supportsVelocity: Bool {
        return true
    }

    /// The default tolerance level for an animation to be considered finished.
    public var resolvingEpsilon: Value.SIMDType.EpsilonType = 0.01

    /**
     This is meant to be set only by the -onValueChanged: function vs. being set directly. It should be used inside of -tick: only.
     Unfortunately Swift doesn't really have the ability to define a property as only visible to subclasses but nowhere else.
     */
    internal var _valueChanged: ValueChangedCallback? = nil

    /**
     Call this to register a `ValueChangedCallback` block that will be called anytime `value` changes from `tick` or if explicitly specified via `postValueChanged`.
     When called, it will give the new value that `value` has animated to (since the last invocation).
     If you're animating `CALayer` objects from the block, you may supply `true` for `disableActions` to automatically have this wrapped in a `CATransaction` that disables implicit animations for the layer.

     ```
     let animation = ...
     animation.onValueChanged(disableActions: true) { newValue in
        // do something with new value
        // i.e.
        layer.position = newValue
     }
     ```

     - Note: Be careful of to not introducee retain cycles on this animation when capturing it or `self` inside the block.
     i.e. a common thing might be to check state related to `animation.toValue` and if you do this without capturing the animation as `weak` or `unowned`, you'll introduce a retain cycle.
     This method is guaranteed to be called on the main thread, and will be called until the animation has resolved or is deallocated.
     */
    public func onValueChanged(disableActions: Bool = false, _ valueChangedCallback: ValueChangedCallback?) {
        guard let valueChangedCallback = valueChangedCallback else { self._valueChanged = nil; return }

        if disableActions {
            self._valueChanged = { (value) in
                CADisableActions {
                    valueChangedCallback(value)
                }
            }
        } else {
            self._valueChanged = valueChangedCallback
        }
    }

    /**
     Stops the animation immediately and preserves the last set `value`. This is unlike CoreAnimation where the model and presentation layers get get mismatched.

     Animations can be resumed via `start` and when started will start from where they left off.

     If you wish, you may also have the animation resolve immediately to its `toValue` or end state and also post `onValueChanged` if desired for this change.
     If resolving immediately, `completion` will be called if available.
     */
    public override func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        self.enabled = false

        if resolveImmediately {
            self._value = _toValue

            if postValueChanged {
                _valueChanged?(value)
            }
            completion?()
        }
    }

}

extension ValueAnimation: Hashable, Equatable {

    public static func == (lhs: ValueAnimation, rhs: ValueAnimation) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(self).hashValue)
    }

}

/// Timestamps for the current animation frame.
public struct AnimationFrame : Equatable {
    
    /// The timestamp that the frame started.
    public let timestamp: CFTimeInterval
    
    /// The timestamp that represents when the next frame displays.
    public var targetTimestamp: CFTimeInterval
    
    /// The current duration between last frame and target frame.
    public var duration: CFTimeInterval {
#if targetEnvironment(simulator)
        return (targetTimestamp - timestamp) / Double(SimulatorSlowAnimationsCoefficient())
#else
        return targetTimestamp - timestamp
#endif
    }

    public init(_ dt: CFTimeInterval) {
        self.timestamp = 0
        self.targetTimestamp = dt
    }
    
    public init(timestamp: CFTimeInterval = CACurrentMediaTime(), targetTimestamp: CFTimeInterval? = nil) {
        self.timestamp = timestamp
        self.targetTimestamp = targetTimestamp ?? timestamp + (1 / 60)
    }
    
}
