//
//  Animation.swift
//  
//
//  Created by Adam Bell on 8/19/20.
//

import Combine
import Foundation
import QuartzCore

public class Animation: DisplayLinkObserver {

    @Published public var enabled: Bool = false

    public var completion: (() -> Void)? = nil

    public init() {
        Animator.shared.observe(self)
    }

    deinit {
        Animator.shared.unobserve(self)
    }

    public func start() {
        if hasResolved() {
            return
        }

        self.enabled = true
    }

    public func stop(resolveImmediately: Bool = false) {
        self.enabled = false
    }

    public func hasResolved() -> Bool {
        fatalError("Subclasses must override this")
    }

    // MARK: - DisplayLinkObserver

    public func tick(_ dt: CFTimeInterval) {
        fatalError("Subclasses must override this")
    }

}

public class ValueAnimation<Value: SIMDRepresentable>: Animation {

    public typealias ValueChangedCallback = ((Value) -> Void)

    internal(set) public var value: Value {
        get {
            return Value(_value)
        }
        set {
            self._value = newValue.simdRepresentation()
        }
    }
    internal var _value: Value.SIMDType = .zero

    public func setValue(_ value: Value) {
        self.value = value
        _valueChanged?(value)
    }

    public var toValue: Value {
        get {
            return Value(_toValue)
        }
        set {
            self._toValue = newValue.simdRepresentation()
        }
    }
    internal var _toValue: Value.SIMDType = .zero

    /**
     This is meant to be set only by the -onValueChanged: function vs. being set directly. It should be used inside of -tick: only.
     Unfortunately Swift doesn't really have the ability to define a property as only visible to subclasses but nowhere else.
     */
    internal var _valueChanged: ValueChangedCallback? = nil

    public func onValueChanged(disableActions: Bool = false, _ valueChangedCallback: ValueChangedCallback?) {
        guard let valueChangedCallback = valueChangedCallback else { self._valueChanged = nil; return }

        if disableActions {
            self._valueChanged = { (value) in
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                valueChangedCallback(value)
                CATransaction.commit()
            }
        } else {
            self._valueChanged = valueChangedCallback
        }
    }

    public override func stop(resolveImmediately: Bool = false) {
        self.enabled = false

        if resolveImmediately {
            self._value = _toValue
            _valueChanged?(value)
            completion?()
        }
    }

}

extension ValueAnimation: Hashable, Equatable {

    public static func == (lhs: ValueAnimation, rhs: ValueAnimation) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(self).hashValue)
    }

}
