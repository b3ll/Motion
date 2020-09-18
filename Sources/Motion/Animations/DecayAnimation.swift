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

    public var decayConstant: Value.SIMDType.Scalar {
        set {
            decay.decayConstant = newValue
        }
        get {
            return decay.decayConstant
        }
    }

    private var decay: Decay<Value>

    public override func hasResolved() -> Bool {
        return _velocity < Value.SIMDType(repeating: 0.5)
    }

    public init(initialValue: Value = .zero, decayConstant: Value.SIMDType.Scalar = Value.SIMDType.Scalar(UIKitDecayConstant)) {
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
        _value = decay.solve(dt: Value.SIMDType.Scalar(dt), x0: _value, velocity: &_velocity)

        _valueChanged?(value)

        if hasResolved() {
            stop()
            
            completion?()
        }
    }

}
