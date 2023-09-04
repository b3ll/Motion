//
//  EquatableEnough.swift
//  
//
//  Created by Adam Bell on 8/2/20.
//

import CoreGraphics
import Foundation
import RealModule
import simd

// MARK: - FloatingPointInitializable

/**
 A protocol that describes something that can be initialized by a floating point value.

 - Note: I hate that this has to exist, I really want to get rid of it.
 It really only exists so that when working with Scalars and SIMD, one can convert to / from them using Doubles or Floating point numbers.
 Technically there shouldn't be any overhead by this, it's just to make the compiler believe that it's ok to convert types.
 */
public protocol FloatingPointInitializable: FloatingPoint & ExpressibleByFloatLiteral & Comparable {

    init(_ value: Float)
    init(_ value: Double)

}

extension Float: FloatingPointInitializable, EquatableEnough {}
extension Double: FloatingPointInitializable, EquatableEnough {}
extension CGFloat: FloatingPointInitializable, EquatableEnough {}

// MARK: - EquatableEnough

/// A protocol that describes something that is approximately equal to something else within a given tolerance (e.g. a floating point value that is equal to another floating point value within a given epsilon).
public protocol EquatableEnough: Comparable {

    associatedtype EpsilonType: EquatableEnough, FloatingPointInitializable

    /**
     Declares whether or not something else is equal to `self` within a given tolerance.
     (e.g. a floating point value that is equal to another floating point value within a given epsilon)
     */
    func isApproximatelyEqual(to: Self, epsilon: EpsilonType) -> Bool

}

public extension EquatableEnough {

    /**
     The epsilon used for the tolerance range in `EquatableEnough`. Defaults to `0.001`.
     - Note: An example of this would be if two floating point values are equal if their difference is `<= 0.001`.
     */
    @inlinable static var epsilon: Double {
        return 0.001
    }

}

public extension EquatableEnough where Self: FloatingPointInitializable {

    /**
     The epsilon used for the tolerance range in `EquatableEnough`. Defaults to `0.001`.
     - Note: An example of this would be if two floating point values are equal if their difference is `<= 0.001`.
     */
    @inlinable static var epsilon: Self {
        return 0.001
    }

}

public extension EquatableEnough where Self: SupportedSIMD {

    /**
     The epsilon used for the tolerance range in `EquatableEnough`. Defaults to `Self(0.001)`.
     - Note: An example of this would be if two floating point values are equal if their difference is `<= 0.001`.
     */
    @inlinable static var epsilon: Scalar {
        return .epsilon
    }

}

public extension EquatableEnough where Self: FloatingPoint & FloatingPointInitializable {

    /**
     Declares whether or not something else is equal to `self` within a given tolerance.
     (e.g. a floating point value that is equal to another floating point value within a given epsilon)

     Bridges to Swift Numerics' `isApproximatelyEqual` (https://github.com/schwa/ApproximateEquality/blob/main/Sources/ApproximateEquality/ApproximateEquality.swift).
     */
    @inlinable func isApproximatelyEqual(to other: Self, epsilon: Self = .epsilon) -> Bool {
        return isApproximatelyEqual(to: other, absoluteTolerance: epsilon, relativeTolerance: .zero)
    }

}

// MARK: - SIMD Extensions

/**
 Exposes a variant of `abs` that supports all SIMD types.

 - Parameters:
    - x: The SIMD type to take the absolute value of.

 - Returns: `abs(x)`
 */
@inlinable public func mabs<SIMDType: SupportedSIMD>(_ x: SIMDType) -> SIMDType {
    let elementsLessThanZero = x .< SIMDType.Scalar.zero
    if !any(elementsLessThanZero) {
        return x
    }

    let inverse = x * -1.0
    let copy = x.replacing(with: inverse, where: elementsLessThanZero)
    return copy
}

/**
 - Note: These are probably not the most optimal, especially in the bigger SIMD types. I haven't yet figured out how to do an equality within a given tolerance across all values simultaneously, so for now it's just an early return if anything isn't approximately equal.
*/
extension SupportedSIMD where Self: EquatableEnough & Comparable, Scalar: SupportedScalar {

    @inlinable public func isApproximatelyEqual(to other: Self, epsilon: Scalar = .epsilon) -> Bool {
        for i in 0..<indices.count {
            let equal = self[i].isApproximatelyEqual(to: other[i], epsilon: epsilon)
            if !equal {
                return false
            }
        }

        return true
    }

    /// Returns whether or not all values of `lhs` (individually, sequentially) are less than all values of `rhs` (following the same ordering as `lhs`).
    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        return all(lhs .< rhs)
    }

}
