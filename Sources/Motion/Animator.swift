//
//  File.swift
//  
//
//  Created by Adam Bell on 7/30/20.
//

import Combine
import Foundation
import QuartzCore

class Animator: NSObject, DisplayLinkObserver {

    private let displayLink: DisplayLink

    private var runningAnimations: Set<AnyAnimation> = []
    private var cancellables: NSMapTable<AnyAnimation, AnyCancellable> = NSMapTable.weakToStrongObjects()

    static let shared = Animator()

    override init() {
        self.displayLink = DisplayLink()
        super.init()
        displayLink.observer = self
    }

    // MARK: - Animations

    internal func configure<T: Animation<V>, V: SIMDRepresentable>(_ animation: T) {
       let obs = animation.$enabled.sink { [weak self] (enabled) in
            if enabled {
                self?.runningAnimations.insert(AnyAnimation(animation))
            } else {
                self?.runningAnimations.remove(AnyAnimation(animation))
            }

            self?.updateDisplayLink()
        }

        cancellables.setObject(obs, forKey: AnyAnimation(animation))
    }

    internal func unconfigure<T: Animation<V>, V: SIMDRepresentable>(_ animation: T) {
        let anim = AnyAnimation(animation)
        runningAnimations.remove(anim)
        cancellables.removeObject(forKey: anim)
    }

    private func updateDisplayLink() {
        if runningAnimations.count == 0 {
            displayLink.stop()
        } else {
            displayLink.start()
        }
    }

    // MARK: - DisplayLinkObserver

    func tick(_ dt: CFTimeInterval) {
        for animation in runningAnimations {
            animation.tick(dt)
        }
    }

}
