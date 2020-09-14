//
//  SpringAnimation.swift
//
//
//  Created by Adam Bell on 7/12/20.
//

import Combine
import QuartzCore
import simd

public final class SpringAnimation<Value: SIMDRepresentable>: Animation<Value> {

    public var velocity: Value {
        get {
            return Value(-_velocity)
        }
        set {
            self._velocity = -newValue.simdRepresentation()
        }
    }
    internal var _velocity: SIMDType = .zero

    public var friction: Double = 10.0
    public var stiffness: Double = 300.0

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
    internal var _clampingRange: ClosedRange<SIMDType>? = nil

    public init(_ initialValue: Value = .zero) {
        super.init()
        self.value = initialValue
    }

    public convenience init(_ initialValue: Value = .zero, response: Double, damping: Double) {
        self.init(initialValue)
        configure(response: response, damping: damping)
    }

    public convenience init(_ initialValue: Value = .zero, stiffness: Double, friction: Double) {
        self.init(initialValue)
        self.stiffness = stiffness
        self.friction = friction
    }

    public func configure(response: Double, damping: Double) {
        let stiffness = pow(2.0 * .pi / response, 2.0)
        let friction = 4.0 * .pi * damping / response

        self.stiffness = stiffness
        self.friction = friction
    }

    public override func hasResolved() -> Bool { 
        return _velocity.approximatelyEqual(to: .zero) && _value.approximatelyEqual(to: _toValue)
    }

    public override func stop() {
        super.stop()
        self.velocity = .zero
    }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {

        /**
         A lot of this looks illegible, but they're various (optimized) implentations of the analytic versions of Spring functions (depending on the damping ratio).

         Long story short, each equation is split into two coefficients A and B, each of which changes (decays, oscillates, etc.) differently based on the damping ratio.

         We calculate the position and velocity for each, which is seeded into the next frame.
         */

        let x0 = _toValue - _value

        self._value = (_toValue - solveSpring(dt: dt, x0: x0, velocity: &_velocity))

        if let clampingRange = clampingRange {
            let clampedValue = Value(_value.clamped(lowerBound: clampingRange.lowerBound.simdRepresentation(), upperBound: clampingRange.upperBound.simdRepresentation()))
            _valueChanged?(clampedValue)
        } else {
            _valueChanged?(value)
        }

        if hasResolved() {
            stop()

            self.value = toValue
            _valueChanged?(value)

            completion?()
        }
    }

    @inlinable public func solveSpring<Value: SupportedSIMDType>(dt: CFTimeInterval, x0: Value, velocity: inout Value) -> Value {
        typealias Scalar = Value.Scalar

        let w0 = sqrt(stiffness)

        let dampingRatio = friction / (2.0 * w0)

        let x: Value
        if dampingRatio < 1.0 {
            let decayEnvelope = exp(-dampingRatio * w0 * dt)
            let wD = w0 * sqrt(1.0 - dampingRatio * dampingRatio)

            let sin_wD_dt = sin(wD * dt)
            let cos_wD_dt = cos(wD * dt)

            let velocity_x0_dampingRatio_w0 = (velocity + x0 * Scalar(dampingRatio * w0))

            let A = x0
            let B = velocity_x0_dampingRatio_w0 / Scalar(wD)

            // Underdamped analytic equation for a spring. (position)
            x = Scalar(decayEnvelope) * (A * Scalar(cos_wD_dt) + B * Scalar(sin_wD_dt))

            // Derivative of the above analytic equation to get the speed of a spring. (velocity)
            let d_x = (velocity_x0_dampingRatio_w0 * Scalar(cos_wD_dt) - x0 * Scalar(wD * sin_wD_dt))
            velocity = -(Scalar(dampingRatio * w0) * x - Scalar(decayEnvelope) * d_x)
        } else if dampingRatio.approximatelyEqual(to: 1.0) {
            let decayEnvelope = exp(-w0 * dt)

            let A = x0
            let B = velocity + Scalar(w0) * x0

            // Critically damped analytic equation for a spring. (position)
            x = Scalar(decayEnvelope) * (A + B * Scalar(dt))

            // Derivative of the above analytic equation to get the speed of a spring. (velocity)
            velocity = Scalar(-decayEnvelope) * (x0 * Scalar(dt * w0 * w0) + (velocity * Scalar(dt * w0)) - velocity)
        } else /* if dampingRatio > 1.0 */ {
            let x_ = sqrt((friction * friction) - 4.0 * w0)

            let r0 = (-friction + x_) / 2.0
            let r1 = (-friction - x_) / 2.0

            let r1_r0 = r1 - r0

            let A = x0 - (((Scalar(r1) * x0) - velocity) / Scalar(r1_r0))
            let B = A + x0

            let decayEnvelopeA = exp(r1 * dt)
            let decayEnvelopeB = exp(r0 * dt)

            // Overdamped analytic equation for a spring. (position)
            x = Scalar(decayEnvelopeA) * A + Scalar(decayEnvelopeB) * B

            // Derivative of the above analytic equation to get the speed of a spring. (velocity)
            velocity = Scalar(decayEnvelopeA * r1) * A + Scalar(decayEnvelopeB * r0) * B
        }

        return x
    }

}

