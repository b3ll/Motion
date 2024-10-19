import Foundation

#if os(macOS)
import AppKit
import CoreGraphics
#else
public typealias CGDirectDisplayID = UInt32
#endif

/**
 Adopted by types that can provide an ``Animator``  to drive Motion animations in a given environment.

 - Note: The animation environment is only relevant for native Mac apps.
 On iOS, you don't have to specify an animation environment and using ``AnimationEnvironment/default`` will always work.
 */
public protocol AnimationEnvironment: AnyObject {
    /// The ``Animator`` type to be used for animations in this environment.
    @MainActor var animator: Animator { get }

    #if os(macOS)
    /// Identifier for the CoreGraphics display represented by this environment.
    @MainActor var displayID: CGDirectDisplayID? { get }

    /// The preferred FPS for animations running in this environment.
    @MainActor var preferredFramesPerSecond: Int { get }
    #endif
}

public protocol AsyncAnimationEnvironment: AnimationEnvironment {
    /// The ``Animator`` type to be used for animations in this environment.
    nonisolated var animator: Animator { get }

    #if os(macOS)
    /// Identifier for the CoreGraphics display represented by this environment.
    nonisolated var displayID: CGDirectDisplayID? { get }

    /// The preferred FPS for animations running in this environment.
    nonisolated var preferredFramesPerSecond: Int { get }
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

// MARK: - iOS Stubs

#if canImport(UIKit)
public extension AnimationEnvironment {
    @MainActor var animator: Animator { Animator.shared }
}

public final class DefaultAnimationEnvironment: AnimationEnvironment, Sendable {
    public static let shared = DefaultAnimationEnvironment()
}
#endif
