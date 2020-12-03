//
//  EasingFunctions.swift
//  
//
//  Created by Adam Bell on 8/29/20.
//

import Foundation

/**
 An easing function powered by a `Bezier` that can be used with a `BasicAnimation`.

 - Note: This can be used on its own, but it's mainly used by `BasicAnimation`'s `tick` method.
 - SeeAlso: `BasicAnimation`
 */
public struct EasingFunction<Value: SIMDRepresentable>: Hashable {

    /// An easing function with a linear bezier curve.
    public static var linear: Self {
        Self(bezier: .linear)
    }

    /// An easing function with an ease-in bezier curve that matches UIKit's `kCAMediaTimingFunctionEaseIn`.
    public static var easeIn: Self {
        Self(bezier: .easeIn)
    }

    /// An easing function with an ease-out bezier curve that matches`kCAMediaTimingFunctionEaseOut`.
    public static var easeOut: Self {
        Self(bezier: .easeOut)
    }

    /// An easing function with an ease-out bezier curve that matches`kCAMediaTimingFunctionEaseInOut`.
    public static var easeInOut: Self {
        Self(bezier: .easeInOut)
    }

    /// The easing function's bezier curve.
    public let bezier: Bezier<Value.SIMDType.Scalar>

    /**
     Initializes the easing function with a given `Bezier`.
     */
    public init(bezier: Bezier<Value.SIMDType.Scalar>) {
        self.bezier = bezier
    }

    internal static var allFunctions: [EasingFunction] {
        return [.linear, .easeIn, .easeOut, .easeInOut, Self(bezier: Bezier(x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0))]
    }

    /**
     Solves for a SIMD value within a given range based on the easing function.

     - Parameters:
        - range: The starting and ending values to interpolate between.
        - fraction: The fraction of progress through the easing curve (from 0.0 to 1.0).

     - Returns: An interpolated SIMD value between the supplied range's bounds based on a fraction (from 0.0 to 1.0) of the easing function.
     */
    @inlinable public func solveSIMD<SIMDType: SupportedSIMD>(_ range: ClosedRange<SIMDType>, fraction: SIMDType.Scalar) -> SIMDType where SIMDType == Value.SIMDType {
        let x = bezier.solve(x: fraction)

        let min = range.lowerBound
        let max = range.upperBound

        let delta = (max - min)

        let newValue = min + (delta * x)

        return newValue
    }

    /**
     Solves for a `Value` within a given range based on the easing function.

     - Note: This mirrors the `solveSIMD` variant, but works for `Value` types.
     */
    @inlinable public func solve(_ range: ClosedRange<Value>, fraction: Value.SIMDType.Scalar) -> Value {
        let newValue = solveSIMD(range.lowerBound.simdRepresentation()...range.upperBound.simdRepresentation(), fraction: fraction)
        return Value(newValue)
    }

    // MARK: - Hashable

    /// Hashes this easing curve into a hash.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bezier)
    }

}

extension EasingFunction where Value: SupportedSIMD {

    /**
     Solves for a `Value` within a given range based on the easing function when the `Value` type conforms to `SupportedSIMD`.

     - Note: This mirrors the `solveSIMD` variant, but works for `Value` types and acts as a fast path to skip boxing and unboxing `Value`.
     */
    @inlinable public func solve<SIMDType: SupportedSIMD>(_ range: ClosedRange<SIMDType>, fraction: SIMDType.Scalar) -> SIMDType where SIMDType == Value.SIMDType {
        return solveSIMD(range, fraction: fraction)
    }

}

/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 A Swift adaptation of UnitBezier from WebKit: https://opensource.apple.com/source/WebCore/WebCore-955.66/platform/graphics/UnitBezier.h
 */
public struct Bezier<Scalar: FloatingPointInitializable>: Hashable {

    public let x1: Scalar
    public let x2: Scalar
    public let y1: Scalar
    public let y2: Scalar

    private let cx: Scalar
    private let cy: Scalar
    private let bx: Scalar
    private let by: Scalar
    private let ax: Scalar
    private let ay: Scalar

    /**
     Initializes the bezier curve with two points.

     - Parameters:
       - x1: The x value of the first point.
       - y1: The y value of the first point.
       - x2: The x value of the second point.
       - y2: The y value of the second point.
     */
    public init(x1: Scalar, y1: Scalar, x2: Scalar, y2: Scalar) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2

        // Calculate the polynomial coefficients, implicit first and last control points are (0,0) and (1,1).
        self.cx = 3.0 * x1
        self.cy = 3.0 * y1

        self.bx = 3.0 * (x2 - x1) - cx
        self.by = 3.0 * (y2 - y1) - cy

        self.ax = 1.0 - cx - bx
        self.ay = 1.0 - cy - by
    }

    private func sampleCurveX(t: Scalar) -> Scalar {
        // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
        return ((ax * t + bx) * t + cx) * t
    }

    private func sampleCurveY(t: Scalar) -> Scalar {
        return ((ay * t + by) * t + cy) * t
    }

    private func sampleCurveDerivativeX(t: Scalar) -> Scalar {
        return (3.0 * ax * t + 2.0 * bx) * t + cx
    }

    /// Solves for the y value given an x value.
    public func solveCurveX(x: Scalar, epsilon: Scalar) -> Scalar {
        var x2: Scalar = 0.0
        var d2: Scalar = 0.0
        var t2 = x

        // First try a few iterations of Newton's method -- normally very fast.
        for _ in 0..<8 {
            x2 = sampleCurveX(t: t2) - x
            if (abs(x2) < epsilon) {
                return t2
            }
            d2 = sampleCurveDerivativeX(t: t2)
            if (abs(d2) < 1e-6) {
                break
            }
            t2 = t2 - x2 / d2
        }

        // Fall back to the bisection method for reliability.
        var t0: Scalar = 0.0
        var t1: Scalar = 1.0
        t2 = x

        if t2 < t0 {
            return t0
        }

        if t2 > t1 {
            return t1
        }

        while t0 < t1 {
            x2 = sampleCurveX(t: t2)
            if abs(x2 - x) < epsilon {
                return t2
            }
            if x > x2 {
                t0 = t2
            } else {
                t1 = t2
            }
            t2 = (t1 - t0) * 0.5 + t0
        }

        // Failure.
        return t2
    }

    /// Solves for the y value for the bezier curve for a given x value and an optional epsilon.
    public func solve(x: Scalar, epsilon: Scalar = 0.0001) -> Scalar {
        return sampleCurveY(t: solveCurveX(x: x, epsilon: epsilon))
    }

}

/// UIKit Constants for Animation Curves
extension Bezier {

    /// A `Bezier` with a linear ramp.
    static var linear: Self {
        return Self(x1: 0.0, y1: 0.0, x2: 1.0, y2: 1.0)
    }

    /// A `Bezier` that starts out slow and then speeds up.
    static var easeIn: Self {
        return Self(x1: 0.42, y1: 0.0, x2: 1.0, y2: 1.0)
    }

    /// A `Bezier` that starts out fast and then slows down.
    static var easeOut: Self {
        return Self(x1: 0.0, y1: 0.0, x2: 0.58, y2: 1.0)
    }

    /// A `Bezier` that starts out slow, speeds up, and then slows down.
    static var easeInOut: Self {
        return Self(x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0)
    }

}
