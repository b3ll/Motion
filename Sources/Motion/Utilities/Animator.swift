//
//  Animator.swift
//  
//
//  Created by Adam Bell on 7/30/20.
//

import Foundation
import QuartzCore
#if canImport(UIKit)
import UIKit
#endif


/// The default Animator that executes all of Motion's animations.
public class Animator: NSObject, AnimationDriverObserver {
    private var animationDriver: AnimationDriver? {
        get {
            if let _animationDriverStore = _animationDriverStore {
                return _animationDriverStore
            }
            _animationDriverStore = SystemAnimationDriver(environment: environment)
            _animationDriverStore?.observer = self
            return _animationDriverStore
        }
        set { _animationDriverStore = newValue }
    }
    private var _animationDriverStore: AnimationDriver?
    internal var runningAnimations: NSHashTable<Animation> = .weakObjects()

    #if os(macOS)
    private let environment: AnimationEnvironment
    #else
    private let environment: AnimationEnvironment
    #endif

    internal init(environment: AnimationEnvironment) {
        self.environment = environment
    }

    #if canImport(UIKit)
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    /**
     The preferred frame rate range for animations being run.

     Defaults to the highest available refresh rate based on the connected screens (i.e. 120hz on Pro Motion displays).

     - Note: You'll also need to enable `CADisableMinimumFrameDurationOnPhone` in your Info.plist for this to take effect.
     */
    public var preferredFrameRateRange: CAFrameRateRange {
        get {
            return (animationDriver as? CoreAnimationDriver)?.preferredFrameRateRange ?? .default
        }
        set {
            (animationDriver as? CoreAnimationDriver)?.preferredFrameRateRange = newValue
        }
    }

    var preferredFramesPerSecond: Int {
        let defaultFPS = 60

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
            // `.default` doesn't have any values, so we want to default to 60 fps.
            if let preferredFrameRateRange = (animationDriver as? CoreAnimationDriver)?.preferredFrameRateRange {
                if preferredFrameRateRange == .default {
                    return defaultFPS
                } else {
                    return Int(preferredFrameRateRange.preferred ?? Float(defaultFPS))
                }
            }
            return defaultFPS
        } else {
            return animationDriver?.preferredFramesPerSecond ?? defaultFPS
        }
    }
    #else
    var preferredFramesPerSecond: Int { environment.preferredFramesPerSecond }
    #endif

    #if canImport(UIKit)
    // The shared animator that runs all of Motion's animations.
    public static let shared = Animator(environment: .default)
    #endif

    // MARK: - Animations

    internal func observe(_ animation: Animation) {
       animation.enabledDidChange = { [weak self, weak animation] (enabled) in
            guard let self = self, let animation = animation else { return }
            
            if enabled {
                let _ = self.runningAnimations.add(animation)
            } else {
                self.runningAnimations.remove(animation)
            }

           self.animationDriver?.isPaused = self.runningAnimations.count == 0
        }
    }

    internal func unobserve(_ animation: Animation) {
        runningAnimations.remove(animation)
        animationDriver?.isPaused = runningAnimations.count == 0
        animation.enabledDidChange = { _ in }
    }

    // MARK: - AnimationDriverObserver

    func tick(frame: AnimationFrame) {
        for animation in (runningAnimations.copy() as! NSHashTable<AnyObject>).objectEnumerator() {
            // This is such a hack.
            if let animation = animation as? AnimationDriverObserver {
                animation.tick(frame: frame)
            }
        }
    }

}
