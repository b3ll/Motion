//
//  BasicAnimation.swift
//  
//
//  Created by Adam Bell on 8/27/20.
//

import Foundation
import simd

public class BasicAnimation<Value: SIMDRepresentable>: Animation<Value> {

    public var fromValue: Value {
        get {
            return Value(_fromValue)
        }
        set {
            self._fromValue = newValue.simdRepresentation()
        }
    }
    internal var _fromValue: SIMDType = .zero

    var duration: CFTimeInterval = 0.3

    var easingFunction: EasingFunction<Value> = .linear

    private var accumulatedTime: CFTimeInterval = 0.0

    public func reset() {
        self.accumulatedTime = 0.0
        self._value = _fromValue
    }

    public override func hasResolved() -> Bool {
        return _value.approximatelyEqual(to: _toValue)
    }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {
        let fraction = accumulatedTime / duration

        _value = easingFunction.interpolate(_fromValue..._toValue, fraction: fraction)

        if hasResolved() {
            stop()

            self.value = toValue
            _valueChanged?(value)

            completion?()
        }

        accumulatedTime += dt
    }

}
