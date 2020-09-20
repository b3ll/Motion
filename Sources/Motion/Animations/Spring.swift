//
//  Spring.swift
//  
//
//  Created by Adam Bell on 9/15/20.
//

import Foundation
import RealModule
import simd

public struct Spring<Value: SIMDRepresentable> {

    public var stiffness: Value.SIMDType.Scalar {
        didSet {
            updateConstants()
        }
    }

    public var damping: Value.SIMDType.Scalar {
        didSet {
            updateConstants()
        }
    }

    private(set) public var w0: Value.SIMDType.Scalar = 0.0
    private(set) public var dampingRatio: Value.SIMDType.Scalar = 0.0
    private(set) public var wD: Value.SIMDType.Scalar = 0.0

    public init(stiffness: Value.SIMDType.Scalar = 300.0, damping: Value.SIMDType.Scalar = 10.0) {
        self.stiffness = stiffness
        self.damping = damping

        // Explicitly update constants.
        updateConstants()
    }

    public mutating func configure(response: Value.SIMDType.Scalar, dampingRatio: Value.SIMDType.Scalar) {
        let stiffness = Value.SIMDType.Scalar.pow(2.0 * .pi / response, 2.0)
        let damping = 4.0 * .pi * dampingRatio / response

        self.stiffness = stiffness
        self.damping = damping
    }

    private mutating func updateConstants() {
        self.w0 = sqrt(stiffness)
        self.dampingRatio = damping / (2.0 * w0)
        self.wD = w0 * sqrt(1.0 - dampingRatio * dampingRatio)
    }

    /**
     This looks hideous, yes, but it forces the compiler to generate hardcoded versions (where the type is hardcoded) of the spring evaluation function below.
     This results in a performance boost of more than 2x.

      A lot of this looks illegible, but they're various (optimized) implentations of the analytic versions of Spring functions (depending on the damping ratio).

      Long story short, each equation is split into two coefficients A and B, each of which changes (decays, oscillates, etc.) differently based on the damping ratio.

      We calculate the position and velocity for each, which is seeded into the next frame.
     */
    @_specialize(where SIMDType == SIMD2<Float>, Value == SIMD2<Float>)
    @_specialize(where SIMDType == SIMD2<Double>, Value == SIMD2<Double>)
    @_specialize(where SIMDType == SIMD3<Float>, Value == SIMD3<Float>)
    @_specialize(where SIMDType == SIMD3<Double>, Value == SIMD3<Double>)
    @_specialize(where SIMDType == SIMD4<Float>, Value == SIMD4<Float>)
    @_specialize(where SIMDType == SIMD4<Double>, Value == SIMD4<Double>)
    @_specialize(where SIMDType == SIMD8<Float>, Value == SIMD8<Float>)
    @_specialize(where SIMDType == SIMD8<Double>, Value == SIMD8<Double>)
    @_specialize(where SIMDType == SIMD16<Float>, Value == SIMD16<Float>)
    @_specialize(where SIMDType == SIMD16<Double>, Value == SIMD16<Double>)
    @_specialize(where SIMDType == SIMD32<Float>, Value == SIMD32<Float>)
    @_specialize(where SIMDType == SIMD32<Double>, Value == SIMD32<Double>)
    @_specialize(where SIMDType == SIMD64<Float>, Value == SIMD64<Float>)
    @_specialize(where SIMDType == SIMD64<Double>, Value == SIMD64<Double>)
    @inlinable public func solve<SIMDType: SupportedSIMD>(dt: SIMDType.Scalar, x0: SIMDType, velocity: inout SIMDType) -> SIMDType where SIMDType.Scalar == Value.SIMDType.Scalar {
        let x: SIMDType
        if dampingRatio < 1.0 {
            let decayEnvelope = SIMDType.Scalar.exp(-dampingRatio * w0 * dt)

            let sin_wD_dt = SIMDType.Scalar.sin(wD * dt)
            let cos_wD_dt = SIMDType.Scalar.cos(wD * dt)

            let velocity_x0_dampingRatio_w0 = (velocity + x0 * (dampingRatio * w0))

            let A = x0
            let B = velocity_x0_dampingRatio_w0 / wD

            // Underdamped analytic equation for a spring. (position)
            x = decayEnvelope * (A * cos_wD_dt + B * sin_wD_dt)

            // Derivative of the above analytic equation to get the speed of a spring. (velocity)
            let d_x = velocity_x0_dampingRatio_w0 * cos_wD_dt - x0 * (wD * sin_wD_dt)
            velocity = -(dampingRatio * w0 * x - decayEnvelope * d_x)
        } else if dampingRatio.approximatelyEqual(to: 1.0) {
            let decayEnvelope = SIMDType.Scalar.exp(-w0 * dt)

            let A = x0
            let B = velocity + w0 * x0

            // Critically damped analytic equation for a spring. (position)
            x = decayEnvelope * (A + B * dt)

            // Derivative of the above analytic equation to get the speed of a spring. (velocity)
            let v1 = dt * w0 * w0
            let v2 = velocity * (dt * w0)
            velocity = (-decayEnvelope) * (x0 * v1 + v2 - velocity)
        } else /* if dampingRatio > 1.0 */ {
            let x_ = sqrt((damping * damping) - 4.0 * w0)

            let r0 = (-damping + x_) / 2.0
            let r1 = (-damping - x_) / 2.0

            let r1_r0 = r1 - r0

            let A = x0 - ((r1 * x0 - velocity) / r1_r0)
            let B = A + x0

            let decayEnvelopeA = SIMDType.Scalar.exp(r1 * dt)
            let decayEnvelopeB = SIMDType.Scalar.exp(r0 * dt)

            // Overdamped analytic equation for a spring. (position)
            x = decayEnvelopeA * A + decayEnvelopeB * B

            // Derivative of the above analytic equation to get the speed of a spring. (velocity)
            velocity = (decayEnvelopeA * r1) * A + (decayEnvelopeB * r0) * B
        }

        return x
    }

    @inlinable public func solve(dt: Value.SIMDType.Scalar, x0: Value, velocity: inout Value) -> Value {
        var velocity_ = velocity.simdRepresentation()
        let x0_ = x0.simdRepresentation()
        let x = solve(dt: dt, x0: x0_, velocity: &velocity_)
        return Value(x)
    }

}
