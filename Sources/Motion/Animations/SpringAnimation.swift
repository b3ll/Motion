//
//  SpringAnimation.swift
//
//
//  Created by Adam Bell on 7/12/20.
//

import Combine
import QuartzCore
import simd

public class SpringAnimation<Value: SIMDRepresentable>: Animation<Value> {

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
        let w0 = sqrt(stiffness)

        let dampingRatio = friction / (2.0 * w0)

        let x0 = _toValue - _value

        let x: Value.SIMDType
        if dampingRatio < 1.0 {
            let decayEnvelope = exp(-dampingRatio * w0 * dt)
            let wD = w0 * sqrt(1.0 - dampingRatio * dampingRatio)

            let sin_wD_dt = sin(wD * dt)
            let cos_wD_dt = cos(wD * dt)

            let velocity_x0_dampingRatio_w0 = (_velocity + x0 * Scalar(dampingRatio * w0))

            let A = x0
            let B = velocity_x0_dampingRatio_w0 / Scalar(wD)

            // Underdamped analytic equation for a spring. (position)
            x = Scalar(decayEnvelope) * (A * Scalar(cos_wD_dt) + B * Scalar(sin_wD_dt))

            // Derivative of the above analytic equation to get the speed of a spring. (velocity)
            let d_x = (velocity_x0_dampingRatio_w0 * Scalar(cos_wD_dt) - x0 * Scalar(wD * sin_wD_dt))
            _velocity = -(Scalar(dampingRatio * w0) * x - Scalar(decayEnvelope) * d_x)
        } else if dampingRatio.approximatelyEqual(to: 1.0) {
            let A = x0
            let B = _velocity * Scalar(w0) * x0

            x = Scalar(exp(-w0 * dt)) * (A + B * Scalar(dt))
        } else /* if dampingRatio > 1.0 */ {
            let x_ = sqrt(pow(friction, 2.0) - 4.0 * w0)
            let gP = (-friction + x_) / 2.0
            let gM = (-friction - x_) / 2.0

            let A = x0 - (Scalar(gM) * x0 - _velocity) / Scalar(gM - gP)
            let B = (Scalar(gM) * x0 - _velocity) / Scalar(gM - gP)

            x = A * Scalar(exp(gM * dt)) + B * Scalar(exp(gP * dt))
        }

        self._value = (_toValue - x)

        if let clampingRange = clampingRange {
            _value.clamp(lowerBound: clampingRange.lowerBound.simdRepresentation(), upperBound: clampingRange.upperBound.simdRepresentation())
        }

        _valueChanged?(value)

        if hasResolved() {
            stop()

            self.value = toValue
            _valueChanged?(value)

            completion?()
        }
    }

}

