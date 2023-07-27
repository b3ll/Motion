/// A timer object that drives animations.
protocol AnimationDriver {
    
    /// A Boolean value that indicates whether the system suspends the display link’s
    /// notifications to the target.
    var isPaused: Bool { get set }

    /// The preferred frame rate for the display link callback.
    var preferredFramesPerSecond: Int { get }
    
    var observer: AnimationDriverObserver? { get set }
}

protocol AnimationDriverObserver: AnyObject {
    func tick(frame: AnimationFrame)
}

#if canImport(UIKit)
import UIKit

typealias SystemAnimationDriver = CoreAnimationDriver

final class CoreAnimationDriver: AnimationDriver {
        
    private var displayLink: CADisplayLink!

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    public var preferredFrameRateRange: CAFrameRateRange {
        get {
            return displayLink.preferredFrameRateRange
        }
        set {
            displayLink.preferredFrameRateRange = newValue
        }
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
    internal static var defaultPreferredFrameRateRange: CAFrameRateRange {
        // Find the first connected scene that's a UIWindowScene and is active, then find the highest supported refresh rate.
        let connectedScenes = UIApplication.shared.connectedScenes
        let windowScene = connectedScenes.first { ($0 as? UIWindowScene)?.activationState == .foregroundActive } as? UIWindowScene
        let maxFPS = Float(windowScene?.windows.map { $0.screen.maximumFramesPerSecond }.max() ?? 60)

        /**
         If we've got a high refresh display, we can use 80 as a minimum.
         https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro

         - Note: We choose 80 as a minimum to be considered high refresh rate, since some devices will erronously report 61fps as a maximum (see: https://github.com/b3ll/Motion/issues/25)
         */
        let adjustedMinFPS: Float = maxFPS > 80.0 ? 80.0 : 60.0

        return CAFrameRateRange(minimum: adjustedMinFPS, maximum: maxFPS, preferred: maxFPS)
    }

    init?(environment: AnimationEnvironment) {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink.add(to: .main, forMode: .common)
        if #available(iOS 15.0, tvOS 15.0, *) {
            displayLink.preferredFrameRateRange = Self.defaultPreferredFrameRateRange
        }
    }
    
    deinit {
        isPaused = true
        displayLink.invalidate()
    }


    var isPaused: Bool = true {
        didSet {
            guard oldValue != isPaused else {
                return
            }
            
            displayLink.isPaused = isPaused
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
    
    weak var observer: AnimationDriverObserver?
    
    @objc func tick() {
        observer?.tick(frame: AnimationFrame(
            timestamp: displayLink.timestamp,
            targetTimestamp: displayLink.targetTimestamp
        ))
    }

}

#endif

#if os(macOS)
import Cocoa

typealias SystemAnimationDriver = CoreVideoDriver

final class CoreVideoDriver: AnimationDriver {

    private var displaylink: CVDisplayLink!
    private var nextFrame: Synchronized<AnimationFrame?> = .init(data: nil)

    let preferredFramesPerSecond: Int

    init?(environment: AnimationEnvironment) {
        self.preferredFramesPerSecond = environment.preferredFramesPerSecond
        var displayLinkRef: CVDisplayLink? = nil
        var successLink: CVReturn

        if let displayID = environment.displayID {
            successLink = CVDisplayLinkCreateWithCGDisplay(displayID, &displayLinkRef)
        } else {
            // Should this be a precondition instead? 🤔
            assertionFailure("CoreVideoDriver needs environment to provide a valid CGDirectDisplayID")
            successLink = CVDisplayLinkCreateWithActiveCGDisplays(&displayLinkRef)
        }

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
    
    weak var observer: AnimationDriverObserver?

    var isPaused: Bool = false {
        didSet {
            let code: CVReturn

            if isPaused {
                guard CVDisplayLinkIsRunning(displaylink) else { return }
                code = CVDisplayLinkStop(displaylink)
            } else {
                guard !CVDisplayLinkIsRunning(displaylink) else { return }
                code = CVDisplayLinkStart(displaylink)
            }

            assert(code == kCVReturnSuccess, "Failed to start/stop display link with error code \(code)")
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
