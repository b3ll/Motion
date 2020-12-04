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

}

// MARK: SpringAnimation

extension SpringAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    func keyframeAnimation(for framerate: Int? = nil) -> CAKeyframeAnimation {
        let dt: TimeInterval
        if let framerate = framerate {
            dt = 1.0 / TimeInterval(framerate)
        } else {
            dt = 1.0 / TimeInterval(Animator.shared.targetFramerate)
        }

        var values = [AnyObject]()
        var keyTimes = [NSNumber]()

        var velocity = self._velocity
        var value = self._value

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

        let keyframeAnimation = CAKeyframeAnimation()
        keyframeAnimation.calculationMode = .discrete
        keyframeAnimation.values = values
        keyframeAnimation.keyTimes = keyTimes
        keyframeAnimation.duration = t
        return keyframeAnimation
    }

}

// MARK: DecayAnimation

extension DecayAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    func keyframeAnimation(for framerate: Int? = nil) -> CAKeyframeAnimation {
        let dt: TimeInterval
        if let framerate = framerate {
            dt = 1.0 / TimeInterval(framerate)
        } else {
            dt = 1.0 / TimeInterval(Animator.shared.targetFramerate)
        }

        var values = [AnyObject]()
        var keyTimes = [NSNumber]()

        var velocity = self._velocity
        var value = self._value

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

        let keyframeAnimation = CAKeyframeAnimation()
        keyframeAnimation.calculationMode = .discrete
        keyframeAnimation.values = values
        keyframeAnimation.keyTimes = keyTimes
        keyframeAnimation.duration = t
        return keyframeAnimation
    }

}


// MARK: BasicAnimation

extension BasicAnimation: CAKeyframeAnimationEmittable where Value: CAKeyframeAnimationValueConvertible {

    func keyframeAnimation(for framerate: Int? = nil) -> CAKeyframeAnimation {
        let dt: TimeInterval
        if let framerate = framerate {
            dt = 1.0 / TimeInterval(framerate)
        } else {
            dt = 1.0 / TimeInterval(Animator.shared.targetFramerate)
        }

        var values = [AnyObject]()
        var keyTimes = [NSNumber]()

        var value = self._value

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

        let keyframeAnimation = CAKeyframeAnimation()
        keyframeAnimation.calculationMode = .discrete
        keyframeAnimation.values = values
        keyframeAnimation.keyTimes = keyTimes
        keyframeAnimation.duration = t
        return keyframeAnimation
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
