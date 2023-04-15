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
public let UIScrollViewDecayConstant: Double = 0.998

/**
 This class provides an interface to use various optimized implementations of a decay function with `SupportedSIMD` and `Value` types.

 This function essentially provides the same "decaying" that `UIScrollView` does when you drag and let go... the value changes based on velocity and slows down to a stop (the velocity decays).

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

    /**
     A value used to round the final value. Defaults to 0.5.

     - Description: This is useful when implementing things like scroll views, where the final value will rest on nice pixel values so that text remains sharp. It defaults to 0.5, but applying 1.0 / the scale factor of the view will lead to similar behaviours as `UIScrollView`. Setting this to `0.0` disables any rounding.
     */
    public var roundingFactor: Value.SIMDType.Scalar = 0.5

    /// A cached invocation of `1.0 / (ln(decayConstant) * 1000.0)`
    private(set) public var one_ln_decayConstant_1000: Value.SIMDType.Scalar = 0.0

    /**
     Initializes a decay function.

     - Parameters:
        - decayConstant: The rate at which the velocity decays over time. Defaults to `UIKitDecayConstant`.
     */
    public init(decayConstant: Value.SIMDType.Scalar = Value.SIMDType.Scalar(UIScrollViewDecayConstant)) {
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
        - velocity: The velocity of the decay.

     - Returns: The new value as its velocity decays.
     */
    @inlinable public func solveSIMD(dt: Value.SIMDType.Scalar, x0: Value.SIMDType, velocity: inout Value.SIMDType) -> Value.SIMDType {
        let d_1000_dt = Value.SIMDType.Scalar.pow(decayConstant, 1000.0 * dt)

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

    /**
     Solves the destination for the decay function based on the given parameters for a `SupportedSIMD` type.

     - Parameters:
        - value: The starting value.
        - velocity: The starting velocity of the decay.
        - decayConstant: The decay constant.
        - roundingFactor: The desired rounding factor. Supplying `0.0` will disable any rounding.

     - Returns: The destination when the decay reaches zero velocity.
     */
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
    @inlinable public func solveToValueSIMD<SIMDType: SupportedSIMD>(value: SIMDType, velocity: SIMDType, decayConstant: SIMDType.Scalar, roundingFactor: SIMDType.Scalar) -> SIMDType {
        let decay = (1000.0 * SIMDType.Scalar.log(decayConstant))
        let toValue = value - velocity / decay
        return roundSIMD(toValue, toNearest: roundingFactor)
    }

    /**
     Solves the destination for the decay function based on the given parameters for a `Value`.

     - Parameters:
        - value: The starting value.
        - velocity: The starting velocity of the decay.
        - decayConstant: The decay constant.
        - roundingFactor: The desired rounding factor. Supplying `0.0` will disable any rounding.

     - Returns: The destination when the decay reaches zero velocity.

     - Note: This mirrors the `SupportedSIMD` version above, but for `Value` types.
     */
    @inlinable public func solveToValue(value: Value, velocity: Value) -> Value {
        let toValue = solveToValueSIMD(value: value.simdRepresentation(), velocity: velocity.simdRepresentation(), decayConstant: decayConstant, roundingFactor: roundingFactor)
        return Value(toValue)
    }

    /**
     Solves the velocity required to reach a desired destination for a decay function based on the given parameters for a `SupportedSIMD` type.

     - Parameters:
        - value: The starting value.
        - toValue: The desired destination for the decay.
        - decayConstant: The decay constant.

     - Returns: The velocity required to reach `toValue`.
     */
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
    @inlinable public func solveVelocitySIMD<SIMDType: SupportedSIMD>(value: SIMDType, toValue: SIMDType, decayConstant: SIMDType.Scalar) -> SIMDType {
        let decay = (1000.0 * SIMDType.Scalar.log(decayConstant))
        return (value - toValue) * decay
    }

    /**
     Solves the velocity required to reach a desired destination for a decay function based on the given parameters for a `Value`.

     - Parameters:
        - value: The starting value.
        - toValue: The desired destination for the decay.

     - Returns: The velocity required to reach `toValue`.

     - Note: This mirrors the `SupportedSIMD` version above, but for `Value` types.
     */
    @inlinable public func solveVelocity(value: Value, toValue: Value) -> Value {
        let velocity = solveVelocitySIMD(value: value.simdRepresentation(), toValue: toValue.simdRepresentation(), decayConstant: decayConstant)
        return Value(velocity)
    }

    // MARK: - Rounding

    /**
     Rounds the given value to the nearest decimal point and factor (supplied by the `roundingFactor`).
     - Description: i.e. supplying a rounding factor of `0.5` for a value of `3.70`, will return `3.5`.

     - Parameters:
        - value: The value to round.
        - toValue: The rounding factor.

     - Returns: The value rounded to the nearest supplied decimal and factor.

     - Note: This mirrors the `SupportedSIMD` version above, but for `Value` types.
     */
    @inlinable public func round(_ value: Value, toNearest roundingFactor: Value.SIMDType.Scalar) -> Value {
        let roundedValue = roundSIMD(value.simdRepresentation(), toNearest: roundingFactor)
        return Value(roundedValue)
    }

    /**
     Rounds the given value to the nearest decimal point and factor (supplied by the `roundingFactor`).
     - Description: i.e. supplying a rounding factor of `0.5` for a value of `3.70`, will return `3.5`.

     - Parameters:
        - value: The value to round.
        - toValue: The rounding factor.

     - Returns: The value rounded to the nearest supplied decimal and factor.
     */
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
    @inlinable public func roundSIMD<SIMDType: SupportedSIMD>(_ value: SIMDType, toNearest roundingFactor: SIMDType.Scalar) -> SIMDType {
        if roundingFactor.approximatelyEqual(to: 0.0) {
            return value
        }

        let rounded = (value / roundingFactor).rounded(.up) * roundingFactor
        return rounded
    }

}

extension DecayFunction where Value: SupportedSIMD {

    /**
     Solves the decay function for a given `Value` when `Value` conforms to `SupportedSIMD`.

     - Note: This mirrors the `SupportedSIMD` version above, but acts as a fast path to call the `solveSIMD` method directly instead of boxing and unboxing the same value.
     */
    @inlinable public func solve(dt: Value.SIMDType.Scalar, x0: Value.SIMDType, velocity: inout Value.SIMDType) -> Value.SIMDType {
        return solveSIMD(dt: dt, x0: x0, velocity: &velocity)
    }

    /**
     Solves the decay function for a given `Value`.

     - Note: This mirrors the `SupportedSIMD` version above, but acts as a fast path to call the `solveToValueSIMD` method directly instead of boxing and unboxing the same value.
     */
    @inlinable public func solveToValue(value: Value.SIMDType, velocity: Value.SIMDType) -> Value.SIMDType {
        return solveToValueSIMD(value: value, velocity: velocity, decayConstant: decayConstant, roundingFactor: roundingFactor)
    }

    /**
     Solves the velocity required to reach a desired destination for a decay function based on the given parameters for a `Value`.

     - Note: This mirrors the `SupportedSIMD` version above, but acts as a fast path to call the `solveVelocitySIMD` method directly instead of boxing and unboxing the same value.
     */
    @inlinable public func solveVelocity(value: Value.SIMDType, toValue: Value.SIMDType) -> Value.SIMDType {
        return solveVelocitySIMD(value: value, toValue: toValue, decayConstant: decayConstant)
    }

    /**
     Rounds the given value to the nearest decimal point and factor (supplied by the `roundingFactor`).
     - Description: i.e. supplying a rounding factor of `0.5` for a value of `3.70`, will return `3.5`.

     - Note: This mirrors the `SupportedSIMD` version above, but acts as a fast path to call the `roundSIMD` method directly instead of boxing and unboxing the same value.
     */
    @inlinable public func round(_ value: Value.SIMDType, toNearest roundingFactor: Value.SIMDType.Scalar) -> Value.SIMDType {
        return roundSIMD(value, toNearest: roundingFactor)
    }

}
