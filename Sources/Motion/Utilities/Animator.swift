//
//  Animator.swift
//  
//
//  Created by Adam Bell on 7/30/20.
//

import Combine
import Foundation
import QuartzCore

class Animator: NSObject, DisplayLinkObserver {

    private let displayLink: DisplayLink

    var runningAnimationsObserver: AnyCancellable? = nil
    @Published private var runningAnimations: Set<AnyAnimation> = []

    private var animationObservers: NSMapTable<AnyAnimation, AnyCancellable> = .weakToStrongObjects()

    static let shared = Animator()

    override init() {
        self.displayLink = DisplayLink()
        super.init()
        displayLink.observer = self

        self.runningAnimationsObserver = $runningAnimations.sink { [weak self] (runningAnimations) in
            self?.updateDisplayLinkFor(runningAnimations)
        }
    }

    // MARK: - Animations

    internal func observe<T: Animation<V>, V: SIMDRepresentable>(_ animation: T) {
       let obs = animation.$enabled.sink { [weak self] (enabled) in
            if enabled {
                self?.runningAnimations.insert(AnyAnimation(animation))
            } else {
                self?.runningAnimations.remove(AnyAnimation(animation))
            }
        }

        animationObservers.setObject(obs, forKey: AnyAnimation(animation))
    }

    internal func unobserve<T: Animation<V>, V: SIMDRepresentable>(_ animation: T) {
        let anim = AnyAnimation(animation)
        runningAnimations.remove(anim)
        animationObservers.removeObject(forKey: anim)
    }

    private func updateDisplayLinkFor(_ runningAnimations: Set<AnyAnimation>) {
        if runningAnimations.isEmpty {
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
