//
//  BasicAnimation.swift
//  
//
//  Created by Adam Bell on 8/27/20.
//

import Foundation
import simd

public final class BasicAnimation<Value: SIMDRepresentable>: Animation<Value> {

    public var fromValue: Value {
        get {
            return Value(_fromValue)
        }
        set {
            self._fromValue = newValue.simdRepresentation()
            updateRange()
        }
    }
    internal var _fromValue: Value.SIMDType = .zero {
        didSet {
            updateRange()
        }
    }

    internal override var _toValue: Value.SIMDType {
        didSet {
            updateRange()
        }
    }

    fileprivate var _range: ClosedRange<Value.SIMDType> = Value.SIMDType.zero...Value.SIMDType.zero

    public var duration: CFTimeInterval = 0.3

    public var easingFunction: EasingFunction<Value.SIMDType> = .linear

    private var accumulatedTime: CFTimeInterval = 0.0

    public func reset() {
        self.accumulatedTime = 0.0
        self._value = _fromValue
    }

    public override func hasResolved() -> Bool {
        return _value.approximatelyEqual(to: _toValue)
    }

    fileprivate func updateRange() {
        _range = _fromValue..._toValue
    }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {
        let fraction = accumulatedTime / duration

        tickOptimized(easingFunction: &easingFunction, range: &_range, fraction: Value.SIMDType.SIMDType.Scalar(fraction), value: &_value)

        _valueChanged?(value)

        accumulatedTime += dt

        if hasResolved() {
            stop()

            completion?()
        }
    }

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
    fileprivate func tickOptimized<SIMDType: SupportedSIMD>(easingFunction: inout EasingFunction<SIMDType>, range: inout ClosedRange<SIMDType>, fraction: SIMDType.SIMDType.Scalar, value: inout SIMDType) {
        value = easingFunction.solve(range, fraction: fraction)
    }

}
