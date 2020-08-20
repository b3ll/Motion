//
//  DisplayLink.swift
//  
//
//  Created by Adam Bell on 8/20/20.
//

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
        displayLink.isPaused = true
        displayLink.add(to: .main, forMode: .common)
    }

    func start() {
        self.valid = true

        displayLink.isPaused = false
    }

    func stop() {
        self.timestamp = 0.0

        if !valid {
            return
        }

        displayLink.isPaused = true

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
