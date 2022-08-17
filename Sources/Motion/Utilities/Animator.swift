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

class Animator: NSObject, AnimationDriverObserver {
    private var animationDriver: AnimationDriver? {
        get {
            if let _animationDriverStore = _animationDriverStore {
                return _animationDriverStore
            }
            _animationDriverStore = SystemAnimationDriver()
            _animationDriverStore?.observer = self
            return _animationDriverStore
        }
        set { _animationDriverStore = newValue }
    }
    private var _animationDriverStore: AnimationDriver?
    internal var runningAnimations: NSHashTable<Animation> = .weakObjects()

    var preferredFramesPerSecond: Int {
        animationDriver?.preferredFramesPerSecond ?? 60
    }

    internal static let shared = Animator()

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
