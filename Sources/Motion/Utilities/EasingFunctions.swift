//
//  EasingFunctions.swift
//  
//
//  Created by Adam Bell on 8/29/20.
//

import Foundation

// Swift Enums are /so/ cool.
public struct EasingFunction<Value: SIMDRepresentable>: Hashable {

    public static var linear: Self {
        Self(bezier: .linear)
    }

    public static var easeIn: Self {
        Self(bezier: .easeIn)
    }

    public static var easeOut: Self {
        Self(bezier: .easeOut)
    }

    public static var easeInOut: Self {
        Self(bezier: .easeInOut)
    }

    let bezier: Bezier<Double>

    init(bezier: Bezier<Double>) {
        self.bezier = bezier
    }

    public static var allFunctions: [EasingFunction] {
        return [.linear, .easeIn, .easeOut, .easeInOut, Self(bezier: Bezier(x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0))]
    }

    public func interpolate(_ range: ClosedRange<Value>, fraction: Double) -> Value {
        let newValue = interpolate(range.lowerBound.simdRepresentation()...range.upperBound.simdRepresentation(), fraction: fraction)
        return Value(newValue)
    }

    public func interpolate(_ range: ClosedRange<Value.SIMDType>, fraction: Double) -> Value.SIMDType {
        typealias Scalar = Value.SIMDType.Scalar

        let x = bezier.solve(x: fraction)

        let min = range.lowerBound
        let max = range.upperBound

        let delta = (max - min)

        let newValue = min + (delta * Scalar(x))

        return newValue
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bezier)
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

// Swift Adaptation of UnitBezier from WebKit: https://opensource.apple.com/source/WebCore/WebCore-955.66/platform/graphics/UnitBezier.h

public struct Bezier<Value: DoubleIntializable>: Hashable {

    public let x1: Value
    public let x2: Value
    public let y1: Value
    public let y2: Value

    private let cx: Value
    private let cy: Value
    private let bx: Value
    private let by: Value
    private let ax: Value
    private let ay: Value

    init(x1: Value, y1: Value, x2: Value, y2: Value) {
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

    func sampleCurveX(t: Value) -> Value {
        // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
        return ((ax * t + bx) * t + cx) * t
    }

    func sampleCurveY(t: Value) -> Value {
        return ((ay * t + by) * t + cy) * t
    }

    func sampleCurveDerivativeX(t: Value) -> Value {
        return (3.0 * ax * t + 2.0 * bx) * t + cx
    }

    // Given an x value, find a parametric value it came from.
    func solveCurveX(x: Value, epsilon: Value) -> Value {
        var x2: Value = 0.0
        var d2: Value = 0.0
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
        var t0: Value = 0.0
        var t1: Value = 1.0
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

    func solve(x: Value, epsilon: Value = 0.0001) -> Value {
        return sampleCurveY(t: solveCurveX(x: x, epsilon: epsilon))
    }

}

// UIKit Constants for Animation Curves
extension Bezier {

    static var linear: Self {
        return Self(x1: 0.0, y1: 0.0, x2: 1.0, y2: 1.0)
    }

    static var easeIn: Self {
        return Self(x1: 0.42, y1: 0.0, x2: 1.0, y2: 1.0)
    }

    static var easeOut: Self {
        return Self(x1: 0.0, y1: 0.0, x2: 0.58, y2: 1.0)
    }

    static var easeInOut: Self {
        return Self(x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0)
    }

}
