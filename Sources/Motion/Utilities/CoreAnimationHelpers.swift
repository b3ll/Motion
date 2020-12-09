//
//  CoreAnimationHelpers.swift
//  
//
//  Created by Adam Bell on 12/8/20.
//

import Foundation
import QuartzCore

/**
 Helper method to disable all implicitly created animations inside the supplied block.

 - Parameters:
    - block: The block that, when run, will have a new `CATransaction` created for it and will disable actions, which will be committed after the block completes.
 */
public func CADisableActions(_ block: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    block()

    CATransaction.commit()
}

public extension CALayer {

    /**
     Adds a supported animation conforming to `CAKeyframeAnimationEmittable` to a given `CALayer`.

     This method generates a pre-configured `CAKeyframeAnimation` from the supplied animation and adds it to the supplied layer, animating the given key path.

     - Parameters:
        - animation: An animation that conforms to `CAKeyframeAnimationEmittable`.
        - key: The key to be associated with the generated `CAKeyframeAnimation` when added to the layer.
        - keyPath: The key path to animate. The key path is relative to the layer.
     */
    func add(_ animation: CAKeyframeAnimationEmittable, forKey key: String, keyPath: String) {
        if keyPath.isEmpty {
            assertionFailure("The keyPath must not be nil.")
            return
        }
        
        let keyframeAnimation = animation.keyframeAnimation(forFramerate: nil)
        keyframeAnimation.keyPath = keyPath
        add(keyframeAnimation, forKey: key)
    }

}
