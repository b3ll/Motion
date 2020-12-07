//
//  DecayAnimation.swift
//  
//
//  Created by Adam Bell on 8/20/20.
//

import Foundation
import simd

public final class DecayAnimation<Value: SIMDRepresentable>: ValueAnimationWithVelocity<Value> {

    public var decayConstant: Value.SIMDType.SIMDType.Scalar {
        set {
            decay.decayConstant = newValue
        }
        get {
            return decay.decayConstant
        }
    }

    internal var decay: DecayFunction<Value.SIMDType>

    public override func hasResolved() -> Bool {
        return hasResolved(velocity: &_velocity)
    }

    internal func hasResolved(velocity: inout Value.SIMDType) -> Bool {
        return velocity < Value.SIMDType(repeating: 0.5)
    }

    public init(initialValue: Value = .zero, decayConstant: Value.SIMDType.SIMDType.Scalar = Value.SIMDType.SIMDType.Scalar(UIKitDecayConstant)) {
        self.decay = DecayFunction(decayConstant: decayConstant)
        super.init()
        self.value = initialValue
    }

    public override func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        // We don't call super here, as jumping to the end requires knowing the end point, and we don't know that (yet).
        self.enabled = false
        completion?()
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

    // See docs in SpringAnimation.swift for why this exists.
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
    internal func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType.SIMDType.Scalar, decay: inout DecayFunction<SIMDType>, value: inout SIMDType, velocity: inout SIMDType) {
        value = decay.solve(dt: dt, x0: value, velocity: &velocity)
    }

}
