//
//  SpringAnimation.swift
//
//
//  Created by Adam Bell on 7/12/20.
//

import QuartzCore

public class Animation: DisplayLinkObserver {

    @Published public var enabled: Bool = false

    public var completion: ((_ completedSuccessfully: Bool) -> Void)? = nil

    public init() {
        Animator.shared.configure(self)
    }

    deinit {
        Animator.shared.unconfigure(self)
    }

    public func start() {
        fatalError("Subclasses must implement this")
    }

    public func stop() {
        fatalError("Subclasses must implement this")
    }

    // MARK: - DisplayLinkObserver

    public func tick(_ dt: CFTimeInterval) {
        fatalError("Subclasses must implement this")
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

public class SpringAnimation<Value: SIMDRepresentable>: Animation {

    private typealias SIMDType = Value.SIMDType
    private typealias Scalar = Value.SIMDType.Scalar

    public var value: Value {
        get {
            return Value(_value)
        }
        set {
            self._value = newValue.simdRepresentation()
        }
    }
    private var _value: SIMDType = .zero

    public var toValue: Value {
        get {
            return Value(_toValue)
        }
        set {
            self._toValue = newValue.simdRepresentation()
        }
    }
    private var _toValue: SIMDType = .zero

    public var velocity: Value {
        get {
            return Value(_velocity)
        }
        set {
            self._velocity = newValue.simdRepresentation()
        }
    }
    private var _velocity: SIMDType = .zero

    public var valueChanged: ((Value) -> Void)? = nil

    public var friction: Double = 10.0
    public var stiffness: Double = 300.0

    public init(_ initialValue: Value = .zero) {
        super.init()
        self.value = initialValue
    }

    public func configure(response: Double, damping: Double) {
        let stiffness = pow(2 * .pi / response, 2)
        let friction = 4 * .pi * damping / response

        self.stiffness = stiffness
        self.friction = friction
    }

    public var hasConverged: Bool {
        return _value.approximatelyEqual(to: _toValue)
    }

    override public func start() {
        self.enabled = true
    }

    override public func stop() {
        self.enabled = false
        self.velocity = .zero
    }

    // MARK: - DisplayLinkObserver

    override public func tick(_ dt: CFTimeInterval) {
        if dt > 1.0 {
            return
        }

        let frictionForce = _velocity * Scalar(friction)
        let springForce = (_toValue - _value) * Scalar(stiffness)

        let force = springForce - frictionForce

        self._velocity += force * Scalar(dt)
        self._value += _velocity * Scalar(dt)

        valueChanged?(value)

        if hasConverged && _velocity.approximatelyEqual(to: .zero) {
            // done
            self.value = toValue
            self.stop()

            valueChanged?(value)
            completion?(true)
        }

    }

}

