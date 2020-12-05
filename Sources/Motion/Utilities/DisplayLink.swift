//
//  DisplayLink.swift
//  
//
//  Created by Adam Bell on 8/20/20.
//

import Foundation
import QuartzCore

#if targetEnvironment(simulator)
// lol, calling private C-functions from Swift is definitely something
// We also don't want to be doing this dlopen at 60+fps so we just cache the function pointer.
internal var SimulatorSlowAnimationsCoefficient_: (@convention(c) () -> Float) = {
    let handle = dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_NOW)
    let symbol = dlsym(handle, "UIAnimationDragCoefficient")
    let function = unsafeBitCast(symbol, to: (@convention(c) () -> Float).self)
    dlclose(handle)
    return function
}()

internal func SimulatorSlowAnimationsCoefficient() -> Float {
    return SimulatorSlowAnimationsCoefficient_()
}
#endif

public protocol DisplayLinkObserver: class {

    func tick(_ dt: CFTimeInterval)

}

/**
 This class wraps CADisplayLink or CVDisplayLink (depending on platform) to provide a means to execute animations by supplying them with V-Synced display ticks.
 */
internal class DisplayLink: NSObject {

    #if os(macOS)
    var displayLink: CVDisplayLink! = nil
    #else
    var displayLink: CADisplayLink! = nil
    #endif

    var lastFrameTimestamp: CFTimeInterval? = nil

    weak var observer: DisplayLinkObserver?

    var valid: Bool = false

    override init() {
        super.init()
        #if os(macOS)
        var error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if error != kCVReturnSuccess {
            fatalError()
        }
        // CVDisplayLink is literally zero fun. I'll probably just end up switching this to CADisplayLink (eventhough it's private on macOS, it exists).
        error = CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, currentTime, outputTime, _, _, userInfo) -> CVReturn in
            if let userInfo = userInfo {
                let slef = Unmanaged<DisplayLink>.fromOpaque(userInfo).takeUnretainedValue()
                let dt = CFTimeInterval(outputTime.pointee.videoTime - currentTime.pointee.videoTime) / CFTimeInterval(outputTime.pointee.videoTimeScale)
                DispatchQueue.main.async {
                    slef.tick(dt)
                }
            }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        if error != kCVReturnSuccess {
            fatalError()
        }
        // This is wrong, but I don't currently know of a nicer way to handle which display this should be animating on (if you have one display that's not at the same hz, this'll be updated with different timing).
        error = CVDisplayLinkSetCurrentCGDisplay(displayLink, CGMainDisplayID())
        #else
        self.displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.isPaused = true
        displayLink.add(to: .main, forMode: .common)
        #endif
    }

    deinit {
        displayLink.isPaused = true
    }

    func start() {
        self.valid = true

        displayLink.isPaused = false
    }

    func stop() {
        #if os(macOS)
        #else
        self.lastFrameTimestamp = 0.0
        #endif

        if !valid {
            return
        }

        displayLink.isPaused = true

        self.valid = false
    }

    #if os(macOS)
    private func tick(_ dt: CFTimeInterval) {
        guard dt > 0.0 else {
            observer?.tick(0.016)
            return
        }

        observer?.tick(dt)
    }
    #else
    @objc private func tick() {
        let currentTime = CACurrentMediaTime()
        #if targetEnvironment(simulator)
        var dt: CFTimeInterval
        #else
        let dt: CFTimeInterval
        #endif
        if let lastFrameTimestamp = lastFrameTimestamp, lastFrameTimestamp > 0.0 {
            dt = currentTime - lastFrameTimestamp
        } else {
            dt = displayLink.duration
        }

        #if targetEnvironment(simulator)
            dt /= Double(SimulatorSlowAnimationsCoefficient())
        #endif

        self.lastFrameTimestamp = CACurrentMediaTime()
        observer?.tick(dt)
    }
    #endif

}

#if os(macOS)

extension CVDisplayLink {

    var isPaused: Bool {
        get {
            return !CVDisplayLinkIsRunning(self)
        }
        set {
            if newValue != isPaused {
                if newValue {
                    CVDisplayLinkStop(self)
                } else {
                    CVDisplayLinkStart(self)
                }
            }
        }
    }

}

#endif
