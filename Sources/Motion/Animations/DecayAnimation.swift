//
//  DecayAnimation.swift
//  
//
//  Created by Adam Bell on 8/20/20.
//

import Foundation
import simd

public class DecayAnimation<Value: SIMDRepresentable>: Animation<Value> {

    public var velocity: Value {
        get {
            return Value(_velocity)
        }
        set {
            self._velocity = newValue.simdRepresentation()
        }
    }
    internal var _velocity: SIMDType = .zero

    public var decayConstant: Double = 0.998

    public override func hasResolved() -> Bool {
        return _velocity < SIMDType(repeating: 0.5)
    }

    public init(_ initialValue: Value = .zero) {
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
        if dt > 1.0 {
            return
        }

        let scaledDT = dt * 1000.0
        let scaledV = _velocity / 1000.0

        let decayAmount = pow(decayConstant, scaledDT)

        let decayedVelocityAmount = decayConstant * (1.0 - decayAmount) / (1.0 - decayConstant)

        self._value += scaledV * Scalar(decayedVelocityAmount)

        self._velocity = scaledV * Scalar(decayAmount * 1000.0)

        _valueChanged?(value)

        if hasResolved() {
            self.stop()
            
            completion?(true)
        }
    }

}
