#if os(macOS)

import AppKit

/**
 Protocol adopted by types that implement ``AnimationEnvironment`` by leveraging another type's implementation.

 Motion extends common AppKit interface elements so that they can be used as animation environments:

 - `NSView`/`NSViewController`
 - `NSWindow`/`NSWindowController`
 - `NSApplication`

 The AppKit types above are listed from most to least specific.
 Prefer to use the most specific environment whenever possible to ensure the best results for your animations.

 For example, if you're configuring an animation inside of a view controller, you may use the view controller itself
 as the environment parameter for your animation:

 ```swift
 override func viewDidLoad() {
     super.viewDidLoad()

     let anim = BasicAnimation<CGFloat>(environment: self)
     // ...
 }
 ```

 - Note: These extensions will crash in debug builds when attempting to start an animation before the environment can be resolved,
 such as when an animation using an `NSView` as its environment starts before the view is in a window. In the view controller example above,
 it wouldn't be safe to start the animation in `viewDidLoad`. Generally, a safe place to start an animation tied to a view or view controller
 is any time after `viewDidAppear` and before `viewDidDisappear`, which is when the view is in a window, and its window is on screen.
 */
public protocol AnimationEnvironmentProxy: AnimationEnvironment {
    var proxiedAnimationEnvironment: AnimationEnvironment { get }
}

public extension AnimationEnvironmentProxy {
    var displayID: CGDirectDisplayID? { proxiedAnimationEnvironment.displayID }
    var preferredFramesPerSecond: Int { proxiedAnimationEnvironment.preferredFramesPerSecond }
    var animator: Animator { proxiedAnimationEnvironment.animator }
}

extension NSWindow: AnimationEnvironmentProxy {
    public var proxiedAnimationEnvironment: AnimationEnvironment {
        guard let screen else {
            assertionFailure("Motion can't run an animation on window \(self) before it's on screen")
            return DefaultAnimationEnvironment.shared
        }
        return screen
    }
}

extension NSView: AnimationEnvironmentProxy {
    public var proxiedAnimationEnvironment: AnimationEnvironment {
        guard let window else {
            assertionFailure("Motion can't run an animation on view \(self) before it's in a window")
            return DefaultAnimationEnvironment.shared
        }
        return window
    }
}

extension NSViewController: AnimationEnvironmentProxy {
    public var proxiedAnimationEnvironment: AnimationEnvironment {
        guard isViewLoaded else {
            assertionFailure("Motion can't run an animation on view controller \(self) before its view has been loaded")
            return DefaultAnimationEnvironment.shared
        }
        return view
    }
}

extension NSWindowController: AnimationEnvironmentProxy {
    public var proxiedAnimationEnvironment: AnimationEnvironment {
        guard isWindowLoaded, let window else {
            assertionFailure("Motion can't run an animation on window controller \(self) before its window is available")
            return DefaultAnimationEnvironment.shared
        }
        return window
    }
}

extension NSApplication: AnimationEnvironmentProxy {
    public var proxiedAnimationEnvironment: AnimationEnvironment {
        if let keyWindow {
            return keyWindow
        } else if let mainWindow {
            return mainWindow
        } else if let visibleWindow = windows.first(where: { $0.isVisible }) {
            return visibleWindow
        } else {
            assertionFailure("Motion can't run an animation on application \(self) without any visible window")
            return DefaultAnimationEnvironment.shared
        }
    }
}

#endif
