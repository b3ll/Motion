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
   - value: The floating point value to be rubberbanded.
   - coefficient: A multiplier to decay the value when it's being rubberbanded. Defaults to `UIScrollViewRubberBandingConstant`.
   - range: The range over which the value won't be rubberbanded.
 */
public func rubberband<Value: FloatingPointInitializable>(_ value: Value, coefficient: Value = Value(UIScrollViewRubberBandingConstant), range: Value) -> Value {
    // Without this, the swift type checker is super slow.
    let x1 = (value * coefficient / range) + 1.0

    return (1.0 - (1.0 / x1)) * range
}

/**
 Rubberbands a floating point value based on a given coefficient and range.

 - Parameters:
   - value: The floating point value to be rubberbanded.
   - coefficient: A multiplier to decay the value when it's being rubberbanded. Defaults to `UIScrollViewRubberBandingConstant`.
   - range: The range over which the value won't be rubberbanded.
 */
public func rubberband<Value: FloatingPointInitializable>(_ value: Value, coefficient: Value = Value(UIScrollViewRubberBandingConstant), range: ClosedRange<Value>) -> Value {
    if range.contains(value) {
        return value
    }

    return rubberband(value, coefficient: coefficient, range: range.upperBound - range.lowerBound)
}

/**
 Rubberbands a `Value` based on a given coefficient and range.

 - Parameters:
   - value: The floating point value to be rubberbanded.
   - coefficient: A multiplier to decay the value when it's being rubberbanded. Defaults to `UIScrollViewRubberBandingConstant`.
   - range: The range over which the value won't be rubberbanded.
 */
public func rubberband<Value: SIMDRepresentable>(_ value: Value, coefficient: Value.SIMDType.Scalar = Value.SIMDType.Scalar(UIScrollViewRubberBandingConstant), range: Value) -> Value {
    typealias SIMDType = Value.SIMDType

    // Same here.
    let v = value.simdRepresentation()
    let r = range.simdRepresentation()

    let x1 = (v * coefficient / range.simdRepresentation()) + 1.0

    let rubberbanded = (1.0 - (1.0 / x1)) * r

    return Value(rubberbanded)
}

/**
 Rubberbands a `Value` based on a given coefficient and range.

 - Parameters:
   - value: The floating point value to be rubberbanded.
   - coefficient: A multiplier to decay the value when it's being rubberbanded. Defaults to `UIScrollViewRubberBandingConstant`.
   - range: The range over which the value won't be rubberbanded.
 */
public func rubberband<Value: SIMDRepresentable>(_ value: Value, coefficient: Value.SIMDType.Scalar = Value.SIMDType.Scalar(UIScrollViewRubberBandingConstant), range: ClosedRange<Value>) -> Value {
    if range.contains(value) {
        return value
    }

    return rubberband(value, coefficient: coefficient, range: range)
}
