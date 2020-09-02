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
    @Published internal var runningAnimations: Set<AnyHashable /* Animation<Value> */> = []

    internal var animationObservers: NSMapTable<AnyObject, AnyCancellable> = .weakToStrongObjects()

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
       let obs = animation.$enabled.sink { [weak self, weak animation] (enabled) in
            guard let animation = animation else { return }
            if enabled {
                let _ = self?.runningAnimations.insert(animation)
            } else {
                self?.runningAnimations.remove(animation)
            }
        }

        animationObservers.setObject(obs, forKey: animation)
    }

    internal func unobserve<T: Animation<V>, V: SIMDRepresentable>(_ animation: T) {
        runningAnimations.remove(animation)
        animationObservers.removeObject(forKey: animation)
    }

    private func updateDisplayLinkFor(_ runningAnimations: Set<AnyHashable /* Animation<Value> */>) {
        if runningAnimations.isEmpty {
            displayLink.stop()
        } else {
            displayLink.start()
        }
    }

    // MARK: - DisplayLinkObserver

    func tick(_ dt: CFTimeInterval) {
        for animation in runningAnimations {
            // This is such a hack.
            if let animation = animation as? DisplayLinkObserver {
                animation.tick(dt)
            }
        }
    }

}
