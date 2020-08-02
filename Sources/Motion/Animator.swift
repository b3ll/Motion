//
//  File.swift
//  
//
//  Created by Adam Bell on 7/30/20.
//

import Combine
import Foundation
import QuartzCore

public protocol DisplayLinkObserver {

    func tick(_ dt: CFTimeInterval)

}

internal class DisplayLink: NSObject {

    var displayLink: CADisplayLink!

    var observer: DisplayLinkObserver!

    var timestamp: CFTimeInterval?

    var valid: Bool = false

    override init() {
        super.init()
        self.displayLink = CADisplayLink(target: self, selector: #selector(tick))
    }

    func start() {
        displayLink.add(to: .main, forMode: .common)

        self.valid = true
    }

    func stop() {
        self.timestamp = 0.0

        if !valid {
            return
        }

        displayLink.invalidate()
        self.displayLink = CADisplayLink(target: self, selector: #selector(tick))

        self.valid = false
    }

    @objc private func tick() {
        let dt: CFTimeInterval
        if let timestamp = timestamp {
            dt = displayLink.timestamp - timestamp
        } else {
            dt = displayLink.duration
        }
        observer?.tick(dt)
        self.timestamp = displayLink.timestamp
    }

}

// Subclassing NSObject gives Hashable conformance
//private class AnyAnimation: NSObject, DisplayLinkObserver {
//
//    private let tickClosure: (_ dt: CFTimeInterval) -> Void
//
//    init<T: Animation<U>, U: SIMDRepresentable>(_ animation: T) {
//        self.tickClosure = animation.tick
//    }
//
//    // MARK: - DisplayLinkObserver
//
//    func tick(_ dt: CFTimeInterval) {
//        tickClosure(dt)
//    }
//
//}

class Animator: NSObject, DisplayLinkObserver {

    private let displayLink: DisplayLink

    private var runningAnimations: Set<Animation> = []
    private var cancellables: NSMapTable<Animation, AnyCancellable> = NSMapTable.weakToStrongObjects()

    static let shared = Animator()

    override init() {
        self.displayLink = DisplayLink()
        super.init()
        displayLink.observer = self
    }

    // MARK: - Animations

    internal func configure(_ animation: Animation) {
       let obs = animation.$enabled.sink { [weak self] (enabled) in
            if enabled {
                self?.runningAnimations.insert(animation)
            } else {
                self?.runningAnimations.remove(animation)
            }

            self?.updateDisplayLink()
        }

        cancellables.setObject(obs, forKey: animation)
    }

    internal func unconfigure(_ animation: Animation) {
        runningAnimations.remove(animation)
        cancellables.removeObject(forKey: animation)
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
