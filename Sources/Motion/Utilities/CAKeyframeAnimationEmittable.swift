//
//  CAKeyframeAnimationEmittable.swift
//  
//
//  Created by Adam Bell on 12/3/20.
//

import Foundation
import QuartzCore
#if canImport(UIKit)
import UIKit
#endif

// MARK: - CAKeyframeAnimationEmittable

/// A protocol that defines the ability to generate a `CAKeyframeAnimation` from an `Animation`.
public protocol CAKeyframeAnimationEmittable where Self: Animation {

    /**
     Generates and returns a `CAKeyframeAnimation` based on the animation's current state targeting the animation's resolved state..

     - Parameters:
        - framerate: The framerate the `CAKeyframeAnimation` should be targeting. If nil, the device's default framerate will be used.

     - Returns: A fully configured `CAKeyframeAnimation` which represents the animation from the current animation's state to its resolved state.

     - Note: You will be required to change the `keyPath` of the `CAKeyFrameAnimation` in order for it to be useful.

     ```
     let animation = SpringAnimation<CGFloat>()
     animation.updateValue(to: 0.0)
     animation.toValue = 100.0

     let keyframeAnimation = animation.keyframeAnimation()
     keyFrameAnimation.keyPath = "position.y"
     layer.add(keyFrameAnimation, forKey: "animation")
     ```
     */
    func keyframeAnimation(forFramerate framerate: Int?) -> CAKeyframeAnimation

    /**
     Generates and returns the values and keyTimes for a `CAKeyframeAnimation`. This is called by default from `keyframeAnimation(forFramerate:)`.

     - Parameters:
        - dt: The target delta time. Typically you'd want 1.0 / targetFramerate`
        - values: A preinitialized array that should be populated with the values to align with the given keyTimes.
        - keyTimes: A preinitialized array that should be populated with the keyTimes to align with the given values.

     - Returns: The total duration of the `CAKeyframeAnimation`.

     - Note: Returning values and keyTimes with different lengths will result in undefined behaviour.
     */
    func populateKeyframeAnimationData(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval

}

extension CAKeyframeAnimationEmittable {

    public func keyframeAnimation(forFramerate framerate: Int? = nil) -> CAKeyframeAnimation {
        let dt: TimeInterval
        if let framerate = framerate {
            dt = 1.0 / TimeInterval(framerate)
        } else {
            dt = 1.0 / TimeInterval(Animator.shared.preferredFramesPerSecond)
        }

        var values = [AnyObject]()
        var keyTimes = [NSNumber]()

        let duration = populateKeyframeAnimationData(dt: dt, values: &values, keyTimes: &keyTimes)

        let keyframeAnimation = CAKeyframeAnimation()
        keyframeAnimation.calculationMode = .discrete
        keyframeAnimation.values = values
        keyframeAnimation.keyTimes = keyTimes
        keyframeAnimation.duration = duration
        return keyframeAnimation
    }

}

// MARK: SpringAnimation

extension SpringAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    /// Generates and populates the `values` and `keyTimes` for a given `SpringAnimation` animating from its `value` to its `toValue` by ticking it by `dt` until it resolves.
    public func populateKeyframeAnimationData(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval {
        var velocity = _velocity
        var value = _value

        var t = 0.0
        var hasResolved = false
        while !hasResolved {
            tickOptimized(Value.SIMDType.Scalar(dt), spring: &spring, value: &value, toValue: &_toValue, velocity: &velocity, clampingRange: &_clampingRange)
            let resolvedState = self.hasResolved(value: &value, epsilon: &resolvingEpsilon, toValue: &_toValue, velocity: &velocity)

            if resolvesUponReachingToValue {
                hasResolved = resolvedState.valueResolved
            } else {
                hasResolved = resolvedState.valueResolved && resolvedState.velocityResolved
            }

            let nsValue = Value(value).toKeyframeValue()
            values.append(nsValue)
            keyTimes.append(t as NSNumber)

            t += dt
        }

        values.append(toValue.toKeyframeValue())
        keyTimes.append(t as NSNumber)

        return t
    }

}

// MARK: DecayAnimation

extension DecayAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    /// Generates and populates the `values` and `keyTimes` for a given `DecayAnimation` animating from its `value` and ticking by `dt` until it resolves.
    public func populateKeyframeAnimationData(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval {
        var velocity = _velocity
        var value = _value

        var t = 0.0
        var hasResolved = false
        while !hasResolved {
            tickOptimized(Value.SIMDType.Scalar(dt), decay: &decay, value: &value, velocity: &velocity)
            hasResolved = self.hasResolved(velocity: &velocity)

            let nsValue = Value(value).toKeyframeValue()
            values.append(nsValue)
            keyTimes.append(t as NSNumber)

            t += dt
        }

        t -= dt

        return t
    }

}


// MARK: BasicAnimation

extension BasicAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    /// Generates and populates the `values` and `keyTimes` for a given `BasicAnimation` animating from its `value` to its `toValue` by ticking it by `dt` until it resolves.
    public func populateKeyframeAnimationData(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval {
        var value = _value

        var t = 0.0
        var hasResolved = false
        while !hasResolved {
            tickOptimized(easingFunction: &easingFunction, range: &_range, fraction: Value.SIMDType.Scalar(t / duration), value: &value)
            hasResolved = self.hasResolved(value: &value, epsilon: &resolvingEpsilon, toValue: &_toValue)

            let nsValue = Value(value).toKeyframeValue()
            values.append(nsValue)
            keyTimes.append(t as NSNumber)

            t += dt
        }

        values.append(toValue.toKeyframeValue())
        keyTimes.append(t as NSNumber)

        return t
    }

}

// MARK: - CAKeyframeAnimationValueConvertible

/**
 A protocol for types to supply the ability to convert themselves into `NSValue` or `NSNumber` for use with `CAKeyframeAnimation`. This is required for `CAKeyframeAnimationEmittable`.

 - Note: This is required for using `CAKeyframeAnimationEmittable`.
 */
public protocol CAKeyframeAnimationValueConvertible {

    func toKeyframeValue() -> AnyObject

}

extension Float: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        return self as NSNumber
    }

}

extension Double: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        return self as NSNumber
    }

}

// MARK: CoreGraphics Types

extension CGFloat: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        return self as NSNumber
    }

}

extension CGPoint: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        #if os(macOS)
        return NSValue(point: self)
        #else
        return NSValue(cgPoint: self)
        #endif
    }

}

extension CGSize: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        #if os(macOS)
        return NSValue(size: self)
        #else
        return NSValue(cgSize: self)
        #endif
    }

}

extension CGRect: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        #if os(macOS)
        return NSValue(rect: self)
        #else
        return NSValue(cgRect: self)
        #endif
    }

}
