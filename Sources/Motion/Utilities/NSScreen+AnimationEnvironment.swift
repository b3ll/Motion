#if os(macOS)
import AppKit

public final class DefaultAnimationEnvironment: NSScreen {
    public static var shared: AnimationEnvironment {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            fatalError("Motion can't run because this Mac doesn't have a screen")
        }
        return screen
    }
}

@MainActor
extension NSScreen: AnimationEnvironment {
    private var environmentStorage: AnimationEnvironmentStorage { AnimationEnvironmentStorage.shared }

    public var animator: Animator { environmentStorage.animator(for: self) }

    public var displayID: CGDirectDisplayID? {
        guard let number = deviceDescription[.screenNumber] as? NSNumber else {
            assertionFailure("NSScreenNumber for \(self) is not an NSNumber")
            return nil
        }
        return number.uint32Value
    }

    public var preferredFramesPerSecond: Int {
        guard #available(macOS 12.0, *) else { return 60 }
        let fps = maximumFramesPerSecond
        guard fps > 0 else { return 60 }
        return fps
    }
}

private extension NSDeviceDescriptionKey {
    static let screenNumber = NSDeviceDescriptionKey("NSScreenNumber")
}

@MainActor
private final class AnimationEnvironmentStorage {
    static let shared = AnimationEnvironmentStorage()

    private var animatorsByDisplayID = [CGDirectDisplayID: Animator]()

    func animator(for screen: NSScreen) -> Animator {
        guard let displayID = screen.displayID else {
            fatalError("Motion failed to get the CGDirectDisplayID for screen \(screen)")
        }

        if let existingAnimator = animatorsByDisplayID[displayID] {
            return existingAnimator
        } else {
            let newAnimator = Animator(environment: screen)
            animatorsByDisplayID[displayID] = newAnimator
            return newAnimator
        }
    }
}
#endif
