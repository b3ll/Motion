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

    fileprivate var spring: SpringFunction<Value.SIMDType>

    public var damping: Value.SIMDType.SIMDType.Scalar {
        get {
            return spring.damping
        }
        set {
            spring.damping = newValue
        }
    }
    public var stiffness: Value.SIMDType.SIMDType.Scalar {
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
        self.spring = SpringFunction()
        super.init()
        self.value = initialValue
    }

    public convenience init(initialValue: Value = .zero, response: Value.SIMDType.SIMDType.Scalar, dampingRatio: Value.SIMDType.SIMDType.Scalar) {
        self.init(initialValue: initialValue)
        configure(response: response, dampingRatio: dampingRatio)
    }

    public convenience init(initialValue: Value = .zero, stiffness: Value.SIMDType.SIMDType.Scalar, damping: Value.SIMDType.SIMDType.Scalar) {
        self.init(initialValue: initialValue)
        self.stiffness = stiffness
        self.damping = damping
    }

    public func configure(response: Value.SIMDType.SIMDType.Scalar, dampingRatio: Value.SIMDType.SIMDType.Scalar) {
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
        tickOptimized(Value.SIMDType.SIMDType.Scalar(dt), spring: &spring, value: &_value, toValue: &_toValue, velocity: &_velocity, clampingRange: &_clampingRange)

        _valueChanged?(value)

        if hasResolved() {
            stop()

            self.value = toValue
            _valueChanged?(value)

            completion?()
        }
    }

    /*
     This looks hideous, yes, but it forces the compiler to generate specialized versions (where the type is hardcoded) of the spring evaluation function.
     Normally this would be specialized, but becuase of the dynamic dispatch of -tick:, it fails to specialize.
     This results in a performance boost of more than 2x.
     */
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
    fileprivate func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType.SIMDType.Scalar, spring: inout SpringFunction<SIMDType>, value: inout SIMDType, toValue: inout SIMDType, velocity: inout SIMDType, clampingRange: inout ClosedRange<SIMDType>?) {
        let x0 = toValue - value

        let x = spring.solve(dt: dt, x0: x0, velocity: &velocity)

        value = toValue - x

        if let clampingRange = clampingRange {
            value.clamp(lowerBound: clampingRange.lowerBound, upperBound: clampingRange.upperBound)
        }
    }
    
}
