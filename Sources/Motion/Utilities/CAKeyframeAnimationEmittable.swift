//
//  CAKeyframeAnimationEmittable.swift
//  
//
//  Created by Adam Bell on 12/3/20.
//

import Foundation
import QuartzCore

// MARK: - CAKeyframeAnimationEmittable

protocol CAKeyframeAnimationEmittable {

    func keyframeAnimation(for framerate: Int?) -> CAKeyframeAnimation
    func generate(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval

}

extension CAKeyframeAnimationEmittable {

    func keyframeAnimation(for framerate: Int?) -> CAKeyframeAnimation {
        let dt: TimeInterval
        if let framerate = framerate {
            dt = 1.0 / TimeInterval(framerate)
        } else {
            dt = 1.0 / TimeInterval(Animator.shared.targetFramerate)
        }

        var values = [AnyObject]()
        var keyTimes = [NSNumber]()

        let duration = generate(dt: dt, values: &values, keyTimes: &keyTimes)

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

    func generate(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval {
        var velocity = _velocity
        var value = _value

        var t = 0.0
        var hasResolved = false
        while !hasResolved {
            tickOptimized(Value.SIMDType.SIMDType.Scalar(dt), spring: &spring, value: &value, toValue: &_toValue, velocity: &velocity, clampingRange: &_clampingRange)
            hasResolved = self.hasResolved(velocity: &velocity, value: &value)

            let nsValue = Value(value).toKeyframeValue()
            values.append(nsValue)
            keyTimes.append(t as NSNumber)

            t += dt
        }

        return t
    }

}

// MARK: DecayAnimation

extension DecayAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    func generate(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval {
        var values = [AnyObject]()
        var keyTimes = [NSNumber]()

        var velocity = _velocity
        var value = _value

        var t = 0.0
        var hasResolved = false
        while !hasResolved {
            tickOptimized(Value.SIMDType.SIMDType.Scalar(dt), decay: &decay, value: &value, velocity: &velocity)
            hasResolved = self.hasResolved(velocity: &velocity)

            let nsValue = Value(value).toKeyframeValue()
            values.append(nsValue)
            keyTimes.append(t as NSNumber)

            t += dt
        }

        return t
    }

}


// MARK: BasicAnimation

extension BasicAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    func generate(dt: TimeInterval, values: inout [AnyObject], keyTimes: inout [NSNumber]) -> TimeInterval {
        var values = [AnyObject]()
        var keyTimes = [NSNumber]()

        var value = _value

        var t = 0.0
        var hasResolved = false
        while !hasResolved {
            tickOptimized(easingFunction: &easingFunction, range: &_range, fraction: Value.SIMDType.SIMDType.Scalar(t / duration), value: &value)
            hasResolved = self.hasResolved(value: &value)

            let nsValue = Value(value).toKeyframeValue()
            values.append(nsValue)
            keyTimes.append(t as NSNumber)

            t += dt
        }

        return t
    }

}

// MARK: - CAKeyframeAnimationValueConvertible

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
        return NSValue(point: self)
    }

}

extension CGSize: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        return NSValue(size: self)
    }

}

extension CGRect: CAKeyframeAnimationValueConvertible {

    public func toKeyframeValue() -> AnyObject {
        return NSValue(rect: self)
    }

}
