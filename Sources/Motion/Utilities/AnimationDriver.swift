/// A timer object that drives animations.
protocol AnimationDriver {
    
    /// A Boolean value that indicates whether the system suspends the display link’s
    /// notifications to the target.
    var isPaused: Bool { get set }

    /// The preferred frame rate for the display link callback.
    var preferredFramesPerSecond: Int { get }
    
    var observer: AnimationDriverObserver? { get set }
}

protocol AnimationDriverObserver {
    func tick(frame: AnimationFrame)
}

#if canImport(UIKit)
import UIKit

typealias SystemAnimationDriver = CoreAnimationDriver

final class CoreAnimationDriver: AnimationDriver {
        
    private var displayLink: CADisplayLink!

    init?() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.add(to: .main, forMode: .common)
    }
    
    deinit {
        isPaused = true
        displayLink.invalidate()
    }

    var isPaused: Bool {
        get {
            displayLink.isPaused
        }
        set {
            displayLink.isPaused = newValue
        }
    }
    
    var preferredFramesPerSecond: Int {
        let fps = displayLink.preferredFramesPerSecond
        if fps == 0 {
            return UIScreen.main.maximumFramesPerSecond
        } else {
            return fps
        }
    }
    
    var observer: AnimationDriverObserver?
    
    @objc func tick() {
        observer?.tick(frame: AnimationFrame(
            timestamp: displayLink.timestamp,
            targetTimestamp: displayLink.targetTimestamp
        ))
    }

}

#endif

#if canImport(Cocoa)
import Cocoa
import Combine

typealias SystemAnimationDriver = CoreVideoDriver

final class CoreVideoDriver: AnimationDriver {

    private var displaylink: CVDisplayLink!
    private var nextFrame: Synchronized<AnimationFrame?> = Synchronized(data: nil)

    init?() {
        var displayLinkRef: CVDisplayLink? = nil
        var successLink = CVDisplayLinkCreateWithActiveCGDisplays(&displayLinkRef)
        
        if let displaylink = displayLinkRef {
            successLink = CVDisplayLinkSetOutputCallback(displaylink, { (displaylink, currentTime, outputTime, _, _, context) -> CVReturn in
                if let context = context {
                    let timer = Unmanaged<CoreVideoDriver>.fromOpaque(context)
                    timer.takeUnretainedValue().addFrame(.init(
                        timestamp: currentTime.pointee.timeInterval,
                        targetTimestamp: outputTime.pointee.timeInterval
                    ))
                }
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())
            
            guard successLink == kCVReturnSuccess else {
                NSLog("Failed to create timer with active display")
                return nil
            }
            
            successLink = CVDisplayLinkSetCurrentCGDisplay(displaylink, CGMainDisplayID())
            
            guard successLink == kCVReturnSuccess else {
                NSLog("Failed to connect to display")
                return nil
            }
            
            self.displaylink = displaylink
        } else {
            NSLog("Failed to create timer with active display")
            return nil
        }
        
        isPaused = false
    }

    deinit {
        isPaused = true
    }

    let preferredFramesPerSecond: Int = 60
    
    var observer: AnimationDriverObserver?

    var isPaused: Bool {
        get {
            !CVDisplayLinkIsRunning(displaylink)
        }
        
        set {
            if newValue != isPaused {
                if !newValue {
                    CVDisplayLinkStart(displaylink)
                } else {
                    CVDisplayLinkStop(displaylink)
                    nextFrame.value = nil
                }
            }
        }
    }
    
    func addFrame(_ frame: AnimationFrame) {
        nextFrame.with { existing in
            if existing != nil {
                existing!.targetTimestamp = frame.targetTimestamp
            } else {
                existing = frame
                DispatchQueue.main.async { [weak self] in
                    self?.tick()
                }
            }
        }
    }
    
    func takeFrame() -> AnimationFrame? {
        nextFrame.with { frame -> AnimationFrame? in
            let result = frame
            frame = nil
            return result
        }
    }
    
    func tick() {
        guard let frame = takeFrame() else {
            return
        }
        observer?.tick(frame: frame)
    }
    
}

extension CVTimeStamp {
    
    fileprivate var timeInterval: TimeInterval {
        return TimeInterval(videoTime) / TimeInterval(self.videoTimeScale)
    }

}

#endif

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
