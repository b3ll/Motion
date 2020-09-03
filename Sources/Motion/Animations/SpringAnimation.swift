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
        self.velocity = .zero
    }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {
        if dt > 1.0 {
            return
        }

        let springForce = (_toValue - _value) * Scalar(stiffness)
        let frictionForce = _velocity * Scalar(friction)

        let force = springForce - frictionForce

        self._velocity += force * Scalar(dt)
        self._value += _velocity * Scalar(dt)

        if let clampingRange = clampingRange {
            self._value.clamp(lowerBound: clampingRange.lowerBound.simdRepresentation(), upperBound: clampingRange.upperBound.simdRepresentation())
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

