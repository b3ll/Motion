//
//  DecayAnimation.swift
//  
//
//  Created by Adam Bell on 8/20/20.
//

import Foundation
import simd

public final class DecayAnimation<Value: SIMDRepresentable>: Animation<Value> {

    public var velocity: Value {
        get {
            return Value(_velocity)
        }
        set {
            self._velocity = newValue.simdRepresentation()
        }
    }
    internal var _velocity: Value.SIMDType = .zero

    public var decayConstant: Value.SIMDType.SIMDType.Scalar {
        set {
            decay.decayConstant = newValue
        }
        get {
            return decay.decayConstant
        }
    }

    fileprivate var decay: Decay<Value.SIMDType>

    public override func hasResolved() -> Bool {
        return _velocity < Value.SIMDType(repeating: 0.5)
    }

    public init(initialValue: Value = .zero, decayConstant: Value.SIMDType.SIMDType.Scalar = Value.SIMDType.SIMDType.Scalar(UIKitDecayConstant)) {
        self.decay = Decay(decayConstant: decayConstant)
        super.init()
        self.value = initialValue
    }

    // MARK: - Disabled API

    @available(*, unavailable, message: "Not Supported in DecayAnimation.")
    public override var toValue: Value {
        get { return .zero }
        set { }
    }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {
        tickOptimized(Value.SIMDType.SIMDType.Scalar(dt), decay: &decay, value: &_value, velocity: &_velocity)

        _valueChanged?(value)

        if hasResolved() {
            stop()

            completion?()
        }
    }

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
    fileprivate func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType.SIMDType.Scalar, decay: inout Decay<SIMDType>, value: inout SIMDType, velocity: inout SIMDType) {
        value = decay.solve(dt: dt, x0: value, velocity: &velocity)
    }

}
