//
//  DisplayLinkAnimation.swift
//  
//
//  Created by Adam Bell on 1/23/22.
//

import Foundation
import simd

/**
 This class provides the ability to do custom animations via hooking into the animation tick cycle directly.

 `toValue` is unavailable and isn't used.

 Instead `onValueChanged` is called with either the duration since the last frame (in milliseconds) as the `value` or the total time (in milliseconds) since the animation started. This can be configured via setting `valueType`.

 This animation will run indefinitely until stopped manually.
 ```
 let displayLinkAnimation = DisplayLinkAnimation<CGFloat>(initialValue: 0.0)
 displayLinkAnimation.onValueChanged { lastTimeStamp in
    // If lastTimeStamp is zero, then it's the first run of the animation.
    if lastTimeStamp.approximatelyEqual(to: 0.0) {
        // Do something on the first frame.
        view.frame.origin.x = 0.0
    } else {
        // Do something on subsequent frames.
        view.frame.origin.x += 1.0
    }
 }
 displayLinkAnimation.start()

 - Note: This class is **not** thread-safe. It is meant to be run on the **main thread** only (much like any AppKit / UIKit operations should be main threaded).
 ```
 */
public final class DisplayLinkAnimation<Value: SIMDRepresentable>: ValueAnimation<Value> where Value.SIMDType.Scalar == Value.SIMDType.SIMDType.Scalar {

    /**
     Describes how `value` is changed on each frame.
     */
    public enum ValueType {
        /// `value` is the delta from the previous frame. If it's the initial frame, value is `.zero`.
        case dt

        /// `value` is increased by the delta from the previous frame and represents the total time elapsed. It is reset upon calling stop.
        case accumulatedTime
    }

    /**
     Initializes a `DisplayLinkAnimation`.

     - Parameters:
        - valueType: The way in which `value` is changed on each frame. See `ValueType` for more details on the options available.
     */
    public init(valueType: ValueType = .dt) {
        self.valueType = valueType
        super.init()
    }

    /// Describes how the value is changed on each frame. Defaults to `.dt`.
    public var valueType: ValueType

    public override func hasResolved() -> Bool {
        return false
    }

    // MARK: - AnimationDriverObserver

    public override func tick(frame: AnimationFrame) {
        tickOptimized(Value.SIMDType(repeating: Value.SIMDType.Scalar(frame.duration)), value: &_value)

        _valueChanged?(value)

        if hasResolved() {
            stop()

            completion?()
        }
    }

    public override func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        _toValue = .zero
        super.stop(resolveImmediately: resolveImmediately, postValueChanged: postValueChanged)
    }

    // See docs in SpringAnimation.swift for why this exists.
    #if DEBUG
    internal func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType, value: inout SIMDType) {
        /* Must Be Mirrored Below */

        switch valueType {
            case .dt:
                value = dt
            case .accumulatedTime:
                value += dt
        }
    }
    #else
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
    internal func tickOptimized<SIMDType: SupportedSIMD>(_ dt: SIMDType, value: inout SIMDType) {
        /* Must Be Mirrored Above */

        switch valueType {
            case .dt:
                value = dt
            case .accumulatedTime:
                value += dt
        }
    }
    #endif

    // MARK: - Disabled API

    @available(*, unavailable, message: "Not supported in DisplayLinkAnimation.")
    public override var toValue: Value {
        get { return .zero }
        set { }
    }

    @available(*, unavailable, message: "Not supported in DisplayLinkAnimation.")
    public override var resolvingEpsilon: Value.SIMDType.EpsilonType {
        get { return .zero }
        set { }
    }

    @available(*, unavailable, message: "Not supported in DisplayLinkAnimation.")
    public override var velocity: Value {
        get { return .zero }
        set { }
    }

    @available(*, unavailable, message: "Not supported in DisplayLinkAnimation.")
    public class override var supportsVelocity: Bool {
        return false
    }
    
}
