//
//  DecayFunction.swift
//  
//
//  Created by Adam Bell on 9/16/20.
//

import Foundation
import RealModule
import simd

/// The standard decay constant for `UIScrollView`.
public let UIKitDecayConstant: Double = 0.998

/**
 This class provides an interface to use various optimized implementations of a decay function with `SupportedSIMD` and `Value` types.

 This function essentially provides the same "decaying" that UIScrollView does when you drag and let go... the value changes based on velocity and slows down to a stop (the velocity decays).

 - Note: This can be used on its own, but it's mainly used by `DecayAnimation`'s `tick` method.
 - SeeAlso: `DecayAnimation`
*/
public struct DecayFunction<Value: SIMDRepresentable> {

    /// The rate at which the velocity decays over time. Defaults to `UIKitDecayConstant`.
    public var decayConstant: Value.SIMDType.Scalar {
        didSet {
            updateConstants()
        }
    }

    /// A cached invocation of `1.0 / (ln(decayConstant) * 1000.0)`
    private(set) public var one_ln_decayConstant_1000: Value.SIMDType.Scalar = 0.0

    /**
     Initializes a decay function.

     - Parameters:
        - decayConstant: The rate at which the velocity decays over time. Defaults to `UIKitDecayConstant`.
     */
    public init(decayConstant: Value.SIMDType.Scalar = Value.SIMDType.Scalar(UIKitDecayConstant)) {
        self.decayConstant = decayConstant
        // Explicitly update constants.
        updateConstants()
    }

    fileprivate mutating func updateConstants() {
        self.one_ln_decayConstant_1000 = 1.0 / (Value.SIMDType.Scalar.log(decayConstant) * 1000.0)
    }

    /**
     Solves the decay function based on the given parameters for a `SupportedSIMD` type.

     - Parameters:
        - dt: The duration in seconds since the last frame.
        - x0: The starting value.
        - velocity: The velocity of the spring.

     - Returns: The new value as its velocity decays.
     */
    @inlinable public func solveSIMD<SIMDType: SupportedSIMD>(dt: SIMDType.Scalar, x0: SIMDType, velocity: inout SIMDType) -> SIMDType where SIMDType == Value.SIMDType {
        let d_1000_dt = SIMDType.Scalar.pow(decayConstant, 1000.0 * dt)

        // Analytic decay equation with constants extracted out.
        let x = x0 + velocity * ((d_1000_dt - 1.0) * one_ln_decayConstant_1000)

        // Velocity is the derivative of the above equation
        velocity = velocity * d_1000_dt

        return x
    }

    /**
     Solves the decay function for a given `Value`.

     - Note: This mirrors the `SupportedSIMD` version above, but for `Value` types.
     */
    @inlinable public func solve(dt: Value.SIMDType.Scalar, x0: Value, velocity velocity_: inout Value) -> Value {
        var velocity = velocity_.simdRepresentation()
        let x = solveSIMD(dt: dt, x0: x0.simdRepresentation(), velocity: &velocity)
        velocity_ = Value(velocity)

        return Value(x)
    }

}

extension DecayFunction where Value: SupportedSIMD {

    /**
     Solves the decay function for a given `Value` when `Value` conforms to `SupportedSIMD`.

     - Note: This mirrors the `SupportedSIMD` version above, but acts as a fast path to call the `solveSIMD` method directly instead of boxing and unboxing the same value.
     */
    @inlinable public func solve<SIMDType: SupportedSIMD>(dt: SIMDType.Scalar, x0: SIMDType, velocity: inout SIMDType) -> SIMDType where SIMDType == Value.SIMDType {
        return solveSIMD(dt: dt, x0: x0, velocity: &velocity)
    }

}
