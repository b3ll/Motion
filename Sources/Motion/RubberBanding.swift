//
//  RubberBanding.swift
//  
//
//  Created by Adam Bell on 8/27/20.
//

import Foundation
import QuartzCore

public func rubberband<Value: DoubleIntializable>(_ value: Value, coefficient: Value, range: Value) -> Value {
    // Without this, the swift type checker is super slow.
    let x1 = (value * coefficient / range) + 1.0

    return (1.0 - (1.0 / x1)) * range
}

public func rubberband<Value: SIMDRepresentable>(_ value: Value, coefficient: Value.SIMDType.Scalar, range: Value) -> Value {
    typealias SIMDType = Value.SIMDType

    // Same here.
    let v = value.simdRepresentation()
    let r = range.simdRepresentation()

    let x1 = (v * coefficient / range.simdRepresentation()) + 1.0

    let rubberbanded = (1.0 - (1.0 / x1)) * r

    return Value(rubberbanded)
}
