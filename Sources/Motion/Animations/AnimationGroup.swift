//
//  AnimationGroup.swift
//  
//
//  Created by Adam Bell on 9/1/20.
//

import Foundation

// This class is largely untested / unfinished.

public final class AnimationGroup: Animation {

    let animations: [Animation]

    init(_ animations: Animation...) {
        self.animations = animations
        super.init()
    }

    public override func hasResolved() -> Bool {
        return animations.reduce(true) { (result, animation) -> Bool in
            return result && animation.hasResolved()
        }
    }

    public override func start() {
        animations.forEach { $0.stop() }
    }

    public override func stop(resolveImmediately: Bool = false) {
        if !resolveImmediately {
            super.stop()
        } else {
            self.enabled = false

            animations.forEach { $0.stop(resolveImmediately: resolveImmediately) }
            completion?()
        }
    }

    // MARK: - DisplayLinkObserver

    public override func tick(_ dt: CFTimeInterval) {
        if dt > 1.0 {
            return
        }

        animations.forEach { $0.tick(dt) }

        if !hasResolved() {
            stop()
            completion?()
        }
    }

}

