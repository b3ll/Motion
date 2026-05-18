import Foundation

#if os(macOS)
import AppKit
import CoreGraphics
#else
import UIKit
public typealias CGDirectDisplayID = UInt32
#endif

/**
 Adopted by types that can provide an ``Animator``  to drive Motion animations in a given environment.

 - Note: On macOS, passing a specific environment is required to get the correct frame rate for the target display.
 On iOS, you can usually use ``AnimationEnvironment/default``. However, if the animation runs on a display other
 than the phone's main screen (e.g. CarPlay, external display), you should pass the owning `UIView` / `UIWindow` /
 `UIScreen` as the environment so the underlying display link is driven by that screen's vsync. A display link
 attached to a sleeping screen will not tick — notably, `UIScreen.main`'s display link pauses when the phone is
 locked, which freezes animations on a still-awake CarPlay display.
 */
public protocol AnimationEnvironment: AnyObject {
    /// The ``Animator`` type to be used for animations in this environment.
    var animator: Animator { get }

    #if os(macOS)
    /// Identifier for the CoreGraphics display represented by this environment.
    var displayID: CGDirectDisplayID? { get }

    /// The preferred FPS for animations running in this environment.
    var preferredFramesPerSecond: Int { get }
    #else
    /// The `UIScreen` the animation will render on, if known. Used to create a display link bound to that
    /// screen rather than `UIScreen.main`. Returning `nil` falls back to the main-screen display link.
    var animationScreen: UIScreen? { get }
    #endif
}

public extension AnimationEnvironment where Self == DefaultAnimationEnvironment {
    /**
     The default animation environment for the current device.

     On iOS, this will be the shared animator.

     On macOS, this will be the environment representing the main screen (`NSScreen.main`).

     - Warning: On macOS, you should always provide the most specific animation environment available
     when initializing an animation, such as the `NSView` where the animation will be rendered.
     Failing to do so may result in animations that don't use the optimal frame rate for the Mac's screen,
     or assertion failures in debug builds when an environment can't be inferred automatically.
     - SeeAlso: To learn more about environment specificity on macOS, see the documentation for ``AnimationEnvironmentProxy``.
    */
    static var `default`: AnimationEnvironment { DefaultAnimationEnvironment.shared }
}

// MARK: - iOS

#if canImport(UIKit)
public extension AnimationEnvironment {
    /// Default animator resolution: if the environment is tied to a specific `UIScreen`, return the per-screen
    /// animator so the underlying display link targets that screen. Otherwise fall back to the shared animator
    /// (which uses the main-screen display link).
    var animator: Animator {
        if let animationScreen {
            AnimationEnvironmentStorage.shared.animator(for: animationScreen)
        } else {
            Animator.shared
        }
    }

    var animationScreen: UIScreen? { nil }
}

public final class DefaultAnimationEnvironment: AnimationEnvironment {
    public static let shared = DefaultAnimationEnvironment()
    public var animationScreen: UIScreen? { nil }
}

private final class AnimationEnvironmentStorage {
    static let shared = AnimationEnvironmentStorage()

    private var animatorsByScreen = [ObjectIdentifier: Animator]()

    func animator(for screen: UIScreen) -> Animator {
        let key = ObjectIdentifier(screen)
        if let existing = animatorsByScreen[key] {
            return existing
        }
        let new = Animator(environment: screen)
        animatorsByScreen[key] = new
        return new
    }
}
#endif
