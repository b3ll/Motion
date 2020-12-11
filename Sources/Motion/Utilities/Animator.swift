//
//  Animator.swift
//  
//
//  Created by Adam Bell on 7/30/20.
//

import Combine
import Foundation
import QuartzCore
#if canImport(UIKit)
import UIKit
#endif

class Animator: NSObject, DisplayLinkObserver {

    private let displayLink: DisplayLink

    private var runningAnimationsObserver: AnyCancellable? = nil
    internal var runningAnimations: NSHashTable<Animation> = .weakObjects()

    internal var animationObservers: NSMapTable<Animation, AnyCancellable> = .weakToStrongObjects()

    internal var targetFramerate: Int {
        #if os(macOS)
        // TODO: Figure out a better way to query for the display's refresh rate.
        return 60
        #else
        let preferredFramesPerSecond = displayLink.displayLink.preferredFramesPerSecond
        if preferredFramesPerSecond == 0 {
            return UIScreen.main.maximumFramesPerSecond
        }
        return displayLink.displayLink.preferredFramesPerSecond
        #endif
    }

    internal static let shared = Animator()

    override init() {
        self.displayLink = DisplayLink()
        super.init()
        displayLink.observer = self
    }

    // MARK: - Animations

    internal func observe(_ animation: Animation) {
       let obs = animation.$enabled.sink { [weak self, weak animation] (enabled) in
            guard let animation = animation else { return }
            if enabled {
                let _ = self?.runningAnimations.add(animation)
            } else {
                self?.runningAnimations.remove(animation)
            }

            if let runningAnimations = self?.runningAnimations {
                self?.updateDisplayLinkFor(runningAnimations)
            }
        }

        animationObservers.setObject(obs, forKey: animation)
    }

    internal func unobserve(_ animation: Animation) {
        runningAnimations.remove(animation)
        animationObservers.removeObject(forKey: animation)
    }

    private func updateDisplayLinkFor(_ runningAnimations: NSHashTable<Animation>) {
        if runningAnimations.count == 0 {
            displayLink.stop()
        } else {
            displayLink.start()
        }
    }

    // MARK: - DisplayLinkObserver

    func tick(_ dt: CFTimeInterval) {
        for animation in (runningAnimations.copy() as! NSHashTable<AnyObject>).objectEnumerator() {
            // This is such a hack.
            if let animation = animation as? DisplayLinkObserver {
                animation.tick(dt)
            }
        }
    }

}
