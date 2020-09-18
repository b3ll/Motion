//
//  File.swift
//  
//
//  Created by Adam Bell on 9/16/20.
//

import Foundation
import RealModule
import simd

public let UIKitDecayConstant: Double = 0.998

public struct Decay<Value: SIMDRepresentable> {

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

    private mutating func updateConstants() {
        self.one_ln_decayConstant_1000 = 1.0 / (Value.SIMDType.Scalar.log(decayConstant) * 1000.0)
    }

    @_specialize(where Value_ == SIMD2<Float>, Value == SIMD2<Float>)
    @_specialize(where Value_ == SIMD2<Double>, Value == SIMD2<Double>)
    @_specialize(where Value_ == SIMD3<Float>, Value == SIMD3<Float>)
    @_specialize(where Value_ == SIMD3<Double>, Value == SIMD3<Double>)
    @_specialize(where Value_ == SIMD4<Float>, Value == SIMD4<Float>)
    @_specialize(where Value_ == SIMD4<Double>, Value == SIMD4<Double>)
    @_specialize(where Value_ == SIMD8<Float>, Value == SIMD8<Float>)
    @_specialize(where Value_ == SIMD8<Double>, Value == SIMD8<Double>)
    @_specialize(where Value_ == SIMD16<Float>, Value == SIMD16<Float>)
    @_specialize(where Value_ == SIMD16<Double>, Value == SIMD16<Double>)
    @_specialize(where Value_ == SIMD32<Float>, Value == SIMD32<Float>)
    @_specialize(where Value_ == SIMD32<Double>, Value == SIMD32<Double>)
    @_specialize(where Value_ == SIMD64<Float>, Value == SIMD64<Float>)
    @_specialize(where Value_ == SIMD64<Double>, Value == SIMD64<Double>)
    @inlinable public func solve<Value_: SupportedSIMD>(dt: Value_.Scalar, x0: Value_, velocity: inout Value_) -> Value_ where Value_.Scalar == Value.SIMDType.Scalar {
        let d_1000_dt = Value_.Scalar.pow(decayConstant, 1000.0 * dt)

        // Analytic decay equation with constants extracted out.
        let x = x0 + velocity * ((d_1000_dt - 1.0) * one_ln_decayConstant_1000)

        // Velocity is the derivative of the above equation
        velocity = velocity * d_1000_dt

        return x
    }

    @inlinable public func solve(dt: Value.SIMDType.Scalar, x0: Value, velocity: inout Value) -> Value {
        var velocity_ = velocity.simdRepresentation()
        let x0_ = x0.simdRepresentation()
        let x = solve(dt: dt, x0: x0_, velocity: &velocity_)
        return Value(x)
    }

}