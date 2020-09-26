//
//  DecayFunction.swift
//  
//
//  Created by Adam Bell on 9/16/20.
//

import Foundation
import RealModule
import simd

public let UIKitDecayConstant: Double = 0.998

public struct DecayFunction<Value: SIMDRepresentable> {

    public var decayConstant: Value.SIMDType.Scalar {
        didSet {
            updateConstants()
        }
    }

    private(set) public var one_ln_decayConstant_1000: Value.SIMDType.Scalar = 0.0

    init(decayConstant: Value.SIMDType.Scalar = Value.SIMDType.Scalar(UIKitDecayConstant)) {
        self.decayConstant = decayConstant
        // Explicitly update constants.
        updateConstants()
    }

    fileprivate mutating func updateConstants() {
        self.one_ln_decayConstant_1000 = 1.0 / (Value.SIMDType.Scalar.log(decayConstant) * 1000.0)
    }

    @inlinable public func solveSIMD<SIMDType: SupportedSIMD>(dt: SIMDType.Scalar, x0: SIMDType, velocity: inout SIMDType) -> SIMDType where SIMDType == Value.SIMDType {
        let d_1000_dt = SIMDType.Scalar.pow(decayConstant, 1000.0 * dt)

        // Analytic decay equation with constants extracted out.
        let x = x0 + velocity * ((d_1000_dt - 1.0) * one_ln_decayConstant_1000)

        // Velocity is the derivative of the above equation
        velocity = velocity * d_1000_dt

        return x
    }

    @inlinable public func solve(dt: Value.SIMDType.Scalar, x0: Value, velocity velocity_: inout Value) -> Value {
        var velocity = velocity_.simdRepresentation()
        let x = solveSIMD(dt: dt, x0: x0.simdRepresentation(), velocity: &velocity)
        velocity_ = Value(velocity)

        return Value(x)
    }

}

extension DecayFunction where Value: SupportedSIMD {

    @inlinable public func solve<SIMDType: SupportedSIMD>(dt: SIMDType.Scalar, x0: SIMDType, velocity: inout SIMDType) -> SIMDType where SIMDType == Value.SIMDType {
        return solveSIMD(dt: dt, x0: x0, velocity: &velocity)
    }

}
