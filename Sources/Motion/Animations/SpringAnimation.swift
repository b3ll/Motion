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
    internal var _velocity: Value.SIMDType = .zero

    private var spring: Spring<Value>

    public var damping: Value.SIMDType.Scalar {
        get {
            return spring.damping
        }
        set {
            spring.damping = newValue
        }
    }
    public var stiffness: Value.SIMDType.Scalar {
        get {
            return spring.stiffness
        }
        set {
            spring.stiffness = newValue
        }
    }

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

    public init(initialValue: Value = .zero) {
        self.spring = Spring()
        super.init()
        self.value = initialValue
    }

    public convenience init(initialValue: Value = .zero, response: Value.SIMDType.Scalar, dampingRatio: Value.SIMDType.Scalar) {
        self.init(initialValue: initialValue)
        configure(response: response, dampingRatio: dampingRatio)
    }

    public convenience init(initialValue: Value = .zero, stiffness: Value.SIMDType.Scalar, damping: Value.SIMDType.Scalar) {
        self.init(initialValue: initialValue)
        self.stiffness = stiffness
        self.damping = damping
    }

    public func configure(response: Value.SIMDType.Scalar, dampingRatio: Value.SIMDType.Scalar) {
        spring.configure(response: response, dampingRatio: dampingRatio)
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
        let x0 = _toValue - _value

        self._value = (_toValue - spring.solve(dt: Value.SIMDType.Scalar(dt), x0: x0, velocity: &_velocity))

        if let clampingRange = _clampingRange {
            let clampedValue = Value(_value.clamped(lowerBound: clampingRange.lowerBound, upperBound: clampingRange.upperBound))
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
    
}

