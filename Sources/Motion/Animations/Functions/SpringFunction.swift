//
//  SpringFunction.swift
//  
//
//  Created by Adam Bell on 9/15/20.
//

import Foundation
import RealModule
import simd

/**
 This class provides an interface to use various optimized implementations of the analytic versions of spring functions with `SupportedSIMD` and `Value` types.

 - Note: This can be used on its own, but it's mainly used by `SpringAnimation`'s `tick` method.
 - SeeAlso: `SpringAnimation`
*/
public struct SpringFunction<Value: SIMDRepresentable> where Value.SIMDType.Scalar == Value.SIMDType.SIMDType.Scalar {

    /**
     The stiffness coefficient of the string.
     This is meant to be paired with the `damping`.

     - Description: This may be changed using `configure(stiffness:damping:)`.
     */
    private(set) public var stiffness: Value.SIMDType.Scalar = 0.0

    /**
     The damping amount of the spring.
     This is meant to be paired with the `stiffness`.

     - Description: This is equivalent to the friction of the spring. This may be changed using `configure(stiffness:damping:)`.
     */
    private(set) public var damping: Value.SIMDType.Scalar = 0.0

    /**
     The response time of the spring (in seconds). This is used to change how long (approximately) it will take for the spring to reach its destination.
     This is meant to be paired with the `dampingRatio`. Changing this will override the `stiffness` and `damping` values.

     - Description: This may be changed using `configure(response:dampingRatio:)`.
     */
    private(set) public var response: Value.SIMDType.Scalar = 0.0

    /**
     The damping ratio of the spring ranging from `0.0` to `1.0`. This describes how much the spring should oscillate around its destination point.

     The supported values are as follows:
        - `0.0`: An infinitely oscillating spring.
        - `1.0`: A critically damped spring.
        - `0.0 < value > 1.0`: An underdamped spring.

     This is meant to be paired with the `dampingRatio`. Changing this will override the `stiffness` and `damping` values.

     - Description: This may be changed using `configure(response:dampingRatio:)`.
     */
    private(set) public var dampingRatio: Value.SIMDType.Scalar = 0.0

    /// The undamped angular frequency of the spring.
    private(set) public var w0: Value.SIMDType.Scalar = 0.0

    /// A cached constant representing the decaying amount of the harmonic frequency derived from `w0 * sqrt(1.0 - dampingRatio^2)`.
    private(set) public var wD: Value.SIMDType.Scalar = 0.0

    /**
     Initializes a spring function.

     - Parameters:
        - stiffness: How stiff the spring should be.
        - damping: How much friction should be exerted on the spring.
     */
    public init(stiffness: Value.SIMDType.Scalar = 300.0, damping: Value.SIMDType.Scalar = 10.0) {
        self.stiffness = stiffness
        self.damping = damping

        // Explicitly update constants.
        updateConstants()
    }

    /**
     Initializes a spring function.

     - Parameters:
        - response: How long (approximately) it should take the spring to reach its destination (in seconds).
        - dampingRatio: How much the spring should bounce around its destination specified as a ratio from 0.0 (bounce forever) to 1.0 (don't bounce at all).
        The supported values are as follows:
          - `0.0`: An infinitely oscillating spring.
          - `1.0`: A critically damped spring.
          - `0.0 < value > 1.0`: An underdamped spring.
     */
    public init(response: Value.SIMDType.Scalar, dampingRatio: Value.SIMDType.Scalar) {
        self.response = response
        self.dampingRatio = dampingRatio

        configure(response: response, dampingRatio: dampingRatio)
    }

    /**
     Convenience function to configure the `stiffness` and `damping` based on easier to work with constants.

     - Parameters:
        - response: How long (approximately) it should take the spring to reach its destination (in seconds).
        - dampingRatio: How much the spring should bounce around its destination specified as a ratio from 0.0 (bounce forever) to 1.0 (don't bounce at all).
        The supported values are as follows:
          - `0.0`: An infinitely oscillating spring.
          - `1.0`: A critically damped spring.
          - `0.0 <-> 1.0`: An underdamped spring.

     - Note: Configuring this spring via this method will override the values for `stiffness` and `damping`.
     - Description: For more info check out the WWDC talk on this: https://developer.apple.com/videos/play/wwdc2018/803/
     */
    public mutating func configure(response response_: Value.SIMDType.Scalar, dampingRatio: Value.SIMDType.Scalar) {
        let response: Value.SIMDType.Scalar
        if response_.approximatelyEqual(to: 0.0) {
            // Having a zero response is unsupported, so we'll just supply an arbitrarily small value.
            response = 0.0001
        } else {
            response = response_
        }
        let stiffness = Value.SIMDType.Scalar.pow(2.0 * .pi / response, 2.0)
        let damping = 4.0 * .pi * dampingRatio / response

        self.stiffness = stiffness
        self.damping = damping
        updateConstants()
    }

    /**
     Convenience function to configure the `stiffness` and `damping` all at once.

     - Parameters:
        - stiffness: The stiffness coefficient of the string.
        - damping: The damping amount of the spring (friction).
     */
    public mutating func configure(stiffness: Value.SIMDType.Scalar, damping: Value.SIMDType.Scalar) {
        self.stiffness = stiffness
        self.damping = damping
        updateConstants()
    }

    private mutating func updateConstants() {
        self.w0 = sqrt(stiffness)
        self.dampingRatio = damping / (2.0 * w0)
        self.wD = w0 * sqrt(1.0 - dampingRatio * dampingRatio)
    }

    /**
     Solves the spring function based on the given parameters for a `SupportedSIMD` type.

     A lot of this looks illegible, but they're various (optimized) implentations of the analytic versions of spring functions (depending on the damping ratio).

     Long story short, each equation is split into two coefficients A and B, each of which changes (decays, oscillates, etc.) differently based on the damping ratio.

     We calculate the value and velocity for each, which is seeded into the next frame.

     If you're curious, something like this is helpful https://www.myphysicslab.com/springs/spring-analytic-en.html

     - Parameters:
        - dt: The duration in seconds since the last frame.
        - x0: The starting value of the spring.
        - velocity: The velocity of the spring.

     - Returns: The new value of the spring as it advances towards zero.
     */
    @inlinable public func solveSIMD(dt: Value.SIMDType.Scalar, x0: Value.SIMDType, velocity: inout Value.SIMDType) -> Value.SIMDType {
        typealias SIMDType = Value.SIMDType
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

    /**
     Solves the spring function for a given `Value`.

     - Note: This mirrors the `SupportedSIMD` version above, but for `Value` types.
     */
    @inlinable public func solve(dt: Value.SIMDType.Scalar, x0: Value, velocity velocity_: inout Value) -> Value {
        var velocity = velocity_.simdRepresentation()
        let x = solveSIMD(dt: dt, x0: x0.simdRepresentation(), velocity: &velocity)
        velocity_ = Value(velocity)

        return Value(x)
    }

}

extension SpringFunction where Value: SupportedSIMD {

    /**
     Solves the spring function for a given `Value` when `Value` conforms to `SupportedSIMD`.

     - Note: This mirrors the `SupportedSIMD` version above, but acts as a fast path to call the `solveSIMD` method directly instead of boxing and unboxing the same value.
     */
    @inlinable public func solve(dt: Value.SIMDType.Scalar, x0: Value.SIMDType, velocity: inout Value.SIMDType) -> Value.SIMDType {
        return solveSIMD(dt: dt, x0: x0, velocity: &velocity)
    }

}
