//
//  RubberBanding.swift
//  
//
//  Created by Adam Bell on 8/27/20.
//

import Foundation
import QuartzCore

/// The standard rubberbanding constant for `UIScrollView`.
public let UIScrollViewRubberBandingConstant = 0.55

/**
 Rubberbands a floating point value based on a given coefficient and range.

 - Parameters:
   - value: The floating point value to rubberband.
   - coefficient: A multiplier to decay the value when it's being rubberbanded. Defaults to `UIScrollViewRubberBandingConstant`.
   - range: The range over which the value won't rubberband.
 */
public func rubberband<Value: FloatingPointInitializable>(_ value: Value, coefficient: Value = Value(UIScrollViewRubberBandingConstant), range: Value) -> Value {
    if (0...range).contains(value) {
        return value
    }

    let x: Value
    if value > range {
        x = value - range
    } else {
        x = -value
    }

    // (1.0 - (1.0 / ((x * c / d) + 1.0))) * d

    // Without this, the swift type checker is super slow.
    let x1 = (x * coefficient / range) + 1.0

    let rubberBandedAmount = ((1.0 - (1.0 / x1)) * range)

    // We're beyond the range
    if value > range {
        return range + rubberBandedAmount
    } else { // We're beyond the range in the opposite direction
        return -rubberBandedAmount
    }
}

/**
 Rubberbands a floating point value based on a given coefficient and range.

 - Parameters:
   - value: The floating point value to rubberband.
   - coefficient: A multiplier to decay the value when it's being rubberbanded. Defaults to `UIScrollViewRubberBandingConstant`.
   - range: The range over which the value won't rubberband.
 */
public func rubberband<Value: FloatingPointInitializable>(_ value: Value, coefficient: Value = Value(UIScrollViewRubberBandingConstant), range: ClosedRange<Value>) -> Value {
    if range.contains(value) {
        return value
    }

    return rubberband(value, coefficient: coefficient, range: range.upperBound - range.lowerBound)
}

// TODO: SIMD variants at some point. It's kinda tricky.
