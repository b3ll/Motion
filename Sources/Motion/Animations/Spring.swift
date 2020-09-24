//
//  Spring.swift
//  
//
//  Created by Adam Bell on 9/15/20.
//

import Foundation
import RealModule
import simd

public struct Spring<SIMDType: SupportedSIMD> {

    public var stiffness: SIMDType.Scalar {
        didSet {
            updateConstants()
        }
    }

    public var damping: SIMDType.Scalar {
        didSet {
            updateConstants()
        }
    }

    private(set) public var w0: SIMDType.Scalar = 0.0
    private(set) public var dampingRatio: SIMDType.Scalar = 0.0
    private(set) public var wD: SIMDType.Scalar = 0.0

    public init(stiffness: SIMDType.Scalar = 300.0, damping: SIMDType.Scalar = 10.0) {
        self.stiffness = stiffness
        self.damping = damping

        // Explicitly update constants.
        updateConstants()
    }

    public mutating func configure(response: SIMDType.Scalar, dampingRatio: SIMDType.Scalar) {
        let stiffness = SIMDType.Scalar.pow(2.0 * .pi / response, 2.0)
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
      A lot of this looks illegible, but they're various (optimized) implentations of the analytic versions of Spring functions (depending on the damping ratio).

      Long story short, each equation is split into two coefficients A and B, each of which changes (decays, oscillates, etc.) differently based on the damping ratio.

      We calculate the position and velocity for each, which is seeded into the next frame.
     */
    @inlinable public func solve(dt: SIMDType.Scalar, x0: SIMDType, velocity: inout SIMDType) -> SIMDType {
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

}
