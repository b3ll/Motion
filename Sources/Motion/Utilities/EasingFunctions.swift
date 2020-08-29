//
//  EasingFunctions.swift
//  
//
//  Created by Adam Bell on 8/29/20.
//

import Foundation

// Swift Enums are /so/ cool.
public enum EasingFunction<Value: SIMDRepresentable>: CaseIterable, Hashable {

    case linear
    case easeIn
    case easeOut
    case easeInOut
    case custom(x1: Double, y1: Double, x2: Double, y2: Double)

    public static var allCases: [EasingFunction] {
        return [.linear, .easeIn, .easeOut, .easeInOut, .custom(x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0)]
    }

    public func interpolate(_ range: ClosedRange<Value>, fraction: Double) -> Value {
        let newValue = interpolate(range.lowerBound.simdRepresentation()...range.upperBound.simdRepresentation(), fraction: fraction)
        return Value(newValue)
    }

    public func interpolate(_ range: ClosedRange<Value.SIMDType>, fraction: Double) -> Value.SIMDType {
        typealias Scalar = Value.SIMDType.Scalar

        let x: Double
        switch self {
        case .linear:
            x = fraction
            break
        case .easeIn:
            x = 1.0 - cos((fraction * .pi) / 2.0)
            break
        case .easeOut:
            x = sin((fraction * .pi) / 2.0)
            break
        case .easeInOut:
            x = -(cos(fraction * .pi) - 1.0) / 2.0
            break
        case let .custom(x1, y1, x2, y2):
            x = bezier(t: fraction, x1: x1, y1: y1, x2: x2, y2: y2)
            break
        }

        let min = range.lowerBound
        let max = range.upperBound

        let delta = (max - min)

        let newValue = min + (delta * Scalar(x))

        return newValue
    }

    @inlinable @inline(__always) func bezier(t: Double, x1: Double, y1: Double, x2: Double, y2: Double) -> Double {
        // Thank you Rob Napier for the insight into writing fast bezier curve functions: https://robnapier.net/faster-bezier

        // ((1−t)^3 * P1) + (3(1−t)^2 * t * P2) + (3(1−t) * t^2 * P3) + (t^3 * P4)
        let onemx = 1.0 - t

        return
            onemx * onemx * onemx * x1
            + 3.0 * onemx * onemx * t * y1
            + 3.0 * onemx * t * t * x2
            + t * t * t * y2
    }

}
