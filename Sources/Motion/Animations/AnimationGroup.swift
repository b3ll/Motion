//
//  AnimationGroup.swift
//  
//
//  Created by Adam Bell on 9/1/20.
//

import Foundation

/**
 This class allows for grouping and running animations in parallel.

 - Note: I'm still debating whether or not this is needed. All animations run in parallel by default anyways, so this is just a more explicit grouping.
 It is largely untested / unfinished, and will most likely undergo a lot of changes to be useable.
 This class works assuming that all animations added to it are not started / stopped outside of this animation group, doing so is unsupported.
 */
public final class AnimationGroup: Animation {

    /// The animations that are to run as a group.
    let animations: [Animation]

    /**
     Initializes the animation group with an array of animations.

     - Parameters:
        - animations: The animations to run as a group.
     */
    init(_ animations: Animation...) {
        self.animations = animations
        super.init()
    }

    /// Returns whether or not all of the animations have resolved.
    public override func hasResolved() -> Bool {
        return animations.reduce(true) { (result, animation) -> Bool in
            return result && animation.hasResolved()
        }
    }

    /// Starts the animation group. Animating each animation in the group sequentially each frame.
    public override func start() {
        animations.forEach { $0.stop() }

        self.enabled = true
    }

    /**
     Stops the animation group.

     - Parameters:
        - resolveImmediately: Whether or not all the animations should jump to their end value without animation. Defaults to `false`.
        - postValueChanged: If `true` is supplied for `resolveImmediately`, this controls whether not `valueChanged` will be called for each animation upon changing its value.
     */
    public override func stop(resolveImmediately: Bool = false, postValueChanged: Bool = false) {
        if !resolveImmediately {
            super.stop()
        } else {
            self.enabled = false

            animations.forEach { $0.stop(resolveImmediately: resolveImmediately, postValueChanged: postValueChanged) }
            completion?()
        }
    }

    // MARK: - AnimationDriverObserver

    public override func tick(frame: AnimationFrame) {
        if frame.duration > 1.0 {
            return
        }

        animations.forEach { $0.tick(frame: frame) }

        if !hasResolved() {
            stop()
            completion?()
        }
    }

}

