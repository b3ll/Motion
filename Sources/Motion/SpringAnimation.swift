//
//  SpringAnimation.swift
//
//
//  Created by Adam Bell on 7/12/20.
//

import Combine
import QuartzCore

public class SpringAnimation<Value: SIMDRepresentable>: Animation<Value> {

    public var velocity: Value {
        get {
            return Value(_velocity)
        }
        set {
            self._velocity = newValue.simdRepresentation()
        }
    }
    private var _velocity: SIMDType = .zero

    public var friction: Double = 10.0
    public var stiffness: Double = 300.0

    public init(_ initialValue: Value = .zero) {
        super.init()
        self.value = initialValue
    }

    public func configure(response: Double, damping: Double) {
        let stiffness = pow(2 * .pi / response, 2)
        let friction = 4 * .pi * damping / response

        self.stiffness = stiffness
        self.friction = friction
    }

    public var hasConverged: Bool {
        return _value.approximatelyEqual(to: _toValue)
    }

    override public func start() {
        self.enabled = true
    }

    override public func stop() {
        self.enabled = false
        self.velocity = .zero
    }

    // MARK: - DisplayLinkObserver

    override public func tick(_ dt: CFTimeInterval) {
        if dt > 1.0 {
            return
        }

        let springForce = (_toValue - _value) * Scalar(stiffness)
        let frictionForce = _velocity * Scalar(friction)

        let force = springForce - frictionForce

        self._velocity += force * Scalar(dt)
        self._value += _velocity * Scalar(dt)

        _valueChanged?(value)

        if hasConverged && _velocity.approximatelyEqual(to: .zero) {
            // done
            self.value = toValue
            self.stop()

            _valueChanged?(value)
            completion?(true)
        }

    }

}

