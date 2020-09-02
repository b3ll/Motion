//
//  Animation.swift
//  
//
//  Created by Adam Bell on 8/19/20.
//

import Combine
import Foundation
import QuartzCore

public class Animation<Value: SIMDRepresentable>: DisplayLinkObserver {

    internal typealias SIMDType = Value.SIMDType
    internal typealias Scalar = Value.SIMDType.Scalar

    public typealias ValueChangedCallback = ((Value) -> Void)

    @Published public var enabled: Bool = false

    public var value: Value {
        get {
            return Value(_value)
        }
        set {
            self._value = newValue.simdRepresentation()
        }
    }
    internal var _value: SIMDType = .zero

    public var toValue: Value {
        get {
            return Value(_toValue)
        }
        set {
            self._toValue = newValue.simdRepresentation()
        }
    }
    internal var _toValue: SIMDType = .zero

    /**
     This is meant to be set only by the -valueChanged: function vs. being set directly. It should be used inside of -tick: only.
     Unfortunately Swift doesn't really have the ability to define a property as only visible to subclasses but nowhere else.
     */
    public var _valueChanged: ValueChangedCallback? = nil

    public func valueChanged(disableActions: Bool = false, _ valueChangedCallback: ValueChangedCallback?) {
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

    public var completion: ((_ completedSuccessfully: Bool) -> Void)? = nil

    public init() {
        Animator.shared.observe(self)
    }

    deinit {
        Animator.shared.unobserve(self)
    }

    public func start() {
        self.enabled = true
    }

    public func stop() {
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

extension Animation: Hashable, Equatable {

    public static func == (lhs: Animation, rhs: Animation) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(self).hashValue)
    }

}

class AnyAnimation: Hashable, Equatable, DisplayLinkObserver {

    internal let wrapped: AnyObject
    internal let tick: (_ dt: CFTimeInterval) -> Void
    internal let hasResolved: () -> Bool

    internal let enabled: Published<Bool>.Publisher

    init<T: Animation<V>, V: SIMDRepresentable>(_ animation: T) {
        self.wrapped = animation
        self.tick = animation.tick
        self.enabled = animation.$enabled
        self.hasResolved = animation.hasResolved
    }

    // MARK: - Equatable

    public static func == (lhs: AnyAnimation, rhs: AnyAnimation) -> Bool {
        return ObjectIdentifier(lhs.wrapped) == ObjectIdentifier(rhs.wrapped)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(ObjectIdentifier(wrapped).hashValue)
    }

    // MARK: - DisplayLinkObserver

    func tick(_ dt: CFTimeInterval) {
        tick(dt)
    }

}
