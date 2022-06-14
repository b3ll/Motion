![Motion-Logo-Dark](https://github.com/b3ll/Motion/blob/main/Resources/MotionLogo-Dark-Cropped.gif?raw=true#gh-dark-mode-only)
![Motion-Logo-Light](https://github.com/b3ll/Motion/blob/main/Resources/MotionLogo-Light-Cropped.gif?raw=true#gh-light-mode-only)

![Tests](https://github.com/b3ll/Motion/workflows/Tests/badge.svg)
![Docs](https://github.com/b3ll/Motion/workflows/Docs/badge.svg)

Motion is an animation engine for gesturally-driven user interfaces, animations, and interactions on iOS, macOS, and tvOS, and is powered by SIMD and written fully in Swift. Motion allows for easily creating physically-modeled, interruptible animations (i.e. springs, decays, etc.) that work hand-in-hand with gesture recognizers to make the most fluid and delightful interactions possible.

- [Usage](#usage)
  - [Animations](#animations)
    - [Spring Animation](#spring-animation)
    - [Decay Animation](#decay-animation)
    - [Basic Animation](#basic-animation)
- [Motion vs. Core Animation](#motion-vs-core-animation)
- [Interruptibility](#interruptibility)
- [SIMD](#simd)
- [Performance](#performance)
- [Additions](#additions)
  - [Rubberbanding](#rubberbanding)
  - [CAKeyframeAnimationEmittable](#cakeyframeanimationemittable)
  - [Action Disabling](#action-disabling)
  - [Curve Graphing](#curve-graphing)
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Swift Package Manager](#swift-package-manager)
  - [xcframework](#xcframework)
  - [Xcode Subproject](#xcode-subproject)
- [Example Project](#example-project)
- [Other Recommendations](#other-recommendations)
- [License](#license)
- [Thanks](#thanks)
- [Contact Info](#contact-info)

# Usage

API Documentation is [here](https://b3ll.github.io/Motion/documentation/motion/)

## Animations

Creating animations in Motion is relatively simple. Simply allocate the animation type that you want with the type that conforms to `SIMDRepresentable`, configure it, and call `start` to start it. For each frame the animation executes, its `onValueChanged` block will be called, and you'll be given the opportunity to assign that newly animated value to something.

By default, lots of types are already supported out of the box, including:

- `Float`
- `Double`
- `CGFloat`
- `CGPoint`
- `CGSize`
- `CGRect`
- `SIMD2<Float>`
- `SIMD2<Double>`
- … and many more.

Calling `stop` will freeze it in place, without the need to query the `presentationLayer` on `CALayer` and set values, or worry about `fillMode`, or worry about anything really.

Whenever it's done, the completion block will be called.

The animations need to be held somewhere as they will stop running if they're deallocated. Also, due to the nature of how they execute blocks, be careful not to introduce retain cycles by not using a `weak self` or `unowned` animation inside the animation `onValueChanged` or `completion` block.

Here's some examples:

### Spring Animation

```swift
let springAnimation = SpringAnimation<CGRect>()
springAnimation.configure(response: 0.30, damping: 0.64)
springAnimation.toValue = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 320.0)
springAnimation.velocity = CGRect(x: 0.0, y: 0.0, width: -200.0, height: -200.0)
springAnimation.onValueChanged(disableActions: true) { newValue in
    view.layer.bounds = newValue
}
springAnimation.completion = { [weak self] in
    // all done
    self?.animationDone()
}
springAnimation.start()
```

**Note**: Some of you may be wondering if it's a mistake that the `stiffness`, `damping`, `response`, or `dampingRatio` setters are private, however this is intentional. It's incredibly easy to mixup `damping` and `dampingRatio`, and using one over the other will lead to dramatically different results. In addition, you should only be configuring either `stiffness` and `damping` **or** `response` and `dampingRatio` as they're both two separate ways of configuring spring constants.

### Decay Animation

```swift
let decayAnimation = DecayAnimation<CGPoint>()
decayAnimation.velocity = CGPoint(x: 0.0, y: 2000.0)
decayAnimation.onValueChanged { newValue in
    view.bounds.origin = newValue
}
decayAnimation.completion = {
    // all done
}
decayAnimation.start()
```

### Basic Animation

```swift
let basicAnimation = BasicAnimation<CGFloat>(easingFunction: .easeInOut)
basicAnimation.fromValue = 100.0
basicAnimation.toValue = 200.0
basicAnimation.duration = 0.4
basicAnimation.onValueChanged { newValue in
    view.bounds.frame.x = newValue
}
basicAnimation.completion = {
    // all done
}
basicAnimation.start()
```

**Note**: All of these animations are to run and be interfaced with on the **main thread only**. There is no support for threading of any kind.

# Motion vs. Core Animation

Motion is not designed to be a general-purpose replacement for Core Animation. Core Animation animations are run in a special way, in another process, outside of your app and are designed to be smooth even when the main thread is being heavily used. Motion on the other head is all run in-process (like a game engine), and using it liberally without considering heavy stack traces, will result in poor performance and dropped frames. Motion itself is not slow (in fact it's really [fast](#performance)!), but calling methods to change view / layer properties or change layout at 60 FPS (or more) can be really taxing if not done carefully.

**tl;dr**: Treat Motion animations as you would a `UIScrollView` (since scrolling animations behave the same way). If you have too much going on in your `UIScrollView` it'll lag when it scrolls; the same applies to Motion.

Some key tips:

- Measure text / layout asychronously, and then commit those changes back to the main thread whenever possible.
- Layout a view controller fully before presenting (rather than during presenting) using `setNeedsDisplay()` and `layoutIfNeeded()`.
- Avoid expensive operations during gestures / handing off from gestures.
- If you can't optimize things any further, using [`CAKeyframeAnimationEmittable`](#cakeyframeanimationemittable) will help, and that's outlined later in this guide.

# Interruptibility

Motion is designed out of the box to make interruptible animations much easier. Interruptibility is when you have the ability to interrupt an animation in flight so you can stop, change, or restart it. Normally, with `UIView` block-based animations, or Core Animation based animations, this is really difficult to do (need to cancel the animation, figure out its current state on screen, apply that, etc.). `UIViewPropertyAnimator` works okay for this, but it relies heavily on "scrubbing" animations, which when working with physically-based animations (i.e. springs), that doesn't really make a lot of sense, since the physics are what generate the animation dynamically (vs. some predefined easing curve you can scrub).

Motion makes things like this easy, so you have to worry less about syncing up animation state with gestures, and focus more about the interactions themselves.

Here's an example of how a drag to a spring animation and then catching and redirecting that animation could look like:

Let's say you have a subview `view` inside another view (`self`).

```swift
// Create a spring animation configured with our constants.
var springAnimation: SpringAnimation<CGPoint>()
springAnimation.configure(response: 0.30, damping: 0.64)

// When you drag on the view and let go, it'll spring away from the center and then rebound back.
// At any point, you can grab the view and do it again.
func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
    switch gestureRecognizer.state: {
        case .began:
            springAnimation.stop()
        case .changed:
            view.center = gestureRecognizer.location(in: self)
            springAnimation.updateValue(to: view.center)
        case .ended:
            springAnimation.toValue = self.center
            springAnimation.velocity = gestureRecognizer.velocity(in: self)
            springAnimation.onValueChanged { newValue in
                view.center = newValue
            }
            springAnimation.start()
    }
}
```

**Note**: You can try this out in the example project (under the Dragging Demo).

# SIMD

SIMD powers a lot of how Motion works and avoids having to use more "expensive" objects like `NSValue` or `NSNumber` to animate. SIMD grants the ability to pack multiple values into a single SIMD register and then perform math on all those values simultaneously (Single Instruction Multiple Data). This means you can do neat things like animate a `CGRect` to another `CGRect` in a single super fast operation (rather than 4 separate operations: `x`, `y,`, `width`, `height`). It's not always the silver bullet, but on average, it's at least on par, and often faster than the naive implementation.

Motion exposes a protocol called `SIMDRepresentable` that allows for easy boxing and unboxing of values:

```swift
let point = CGPoint(x: 10.0, y: 10.0)
let simdPoint: SIMD2<CGFloat.NativeType> = point.simdRepresentation()
let pointBoxedAgain = CGPoint(simdPoint)
```

These conversions are relatively inexpensive, and Motion has been heavily optimized to avoid copying or boxing/unboxing them whenever it can.

For more information on SIMD, check out the [docs](https://developer.apple.com/documentation/accelerate/simd).

# Performance

Motion is pretty dang fast (especially on Apple Silicon!), leveraging some manual Swift optimization / specialization as well as SIMD it's capable of executing 5000 `SpringAnimation<SIMD64<Double>>` in **~130ms** on an iPhone 12 Pro (that's 320,000 springs at 0.4 microseconds per spring!!). For smaller types like `CGFloat`, it can do the same thing in **~1ms**.

Is it as fast as it could be? Faster than some hand-optimized C++ or C implementation? Probably not.
That being said, it's definitely fast enough for interactions on devices and rarely (if ever) will be the bottleneck. I'm also still no SIMD expert, so if anyone has some tips, I'm sure it can go faster!

**tl;dr**: SIMD go brrrrrrrrrrrrrrrrrrrrrrr

If you'd like benchmark Motion on your own device, simply run the following from within the `Benchmark` folder:

```sh
swift run -c release MotionBenchmarkRunner --time-unit ms
```

If you'd like to run the benchmark on device, just launch the `MotionEample-iOS` app in `Release` mode with the `--benchmark` launch argument.

# Additions

Motion features some great additions to aid in creating interactions in general.

## Rubberbanding

Rubberbanding is the act of making values appear to be on a rubberband (they stretch and slip based on interaction). `UIScrollView` does this when you're pulling past the `contentSize` and by using the rubberband functions in Motion you can re-create this interaction for yourself. See the "ScrollView Demo" inside the example app for more info.

## CAKeyframeAnimationEmittable

All animations in Motion conform to `CAKeyframeAnimationEmittable` and that means that for any animation you configure, you can have it automatically generate a `CAKeyframeAnimation` that mirrors what would happen if you were to animate things using `start()`. The duration, and everything else is automatically calculated by running the animation from `value` to the resolved state. The only difference is `onValueChanged` and `completion` cannot be used, and you must specify a keypath to animate. There are also some helper methods to make this even easier (like adding any animation to a `CALayer` directly).

For example:

```swift
let springAnimation = SpringAnimation<CGRect>()
springAnimation.configure(response: 0.30, damping: 0.64)
springAnimation.toValue = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 320.0)
springAnimation.velocity = CGRect(x: 0.0, y: 0.0, width: -200.0, height: -200.0)

let keyframeAnimation = springAnimation.keyframeAnimation()
keyframeAnimation.keyPath = "frame"
layer.add(keyframeAnimation, forKey: "MyAnimation")

// or

layer.add(springAnimation, forKey: "MyAnimation", keyPath: "frame")
```

**Note**: If you remove or interrupt the animation and you want it to stay in place on screen, much like all other Core Animation animations, you'll need to grab the value from the layer's `presentationLayer` and apply that to the layer (as well as worry about `fillMode`).

```swift
let frame = layer.presentationLayer()?.frame ?? layer.frame
layer.removeAnimation(forKey: "MyAnimation")
CADisableActions {
    layer.frame = frame
}
```

## Action Disabling

`CATransaction` is a really useful API but can easily break things if you forget to pair up `CATransaction.begin()` and `CATransaction.commit()` calls.

`CADisableActions()` can be very helpful to reduce errors created when working with `CATransaction` to disable implicit animations:

```swift
CADisableActions {
    layer.opacity = 0.5
}

// This is the same as calling:

CATransaction.begin()
CATransaction.setDisableActions(true)
layer.opacity = 0.5
CATransaction.commit()
```

In addition, you can also disable implicit animations in every single `onValueChanged` invocation:

```swift
let springAnimation = SpringAnimation<CGFloat>(initialValue: 0.5)
springAnimation.onValueChanged(disableActions: true) { newValue in
    layer.opacity = newValue
}
springAnimation.start()
```

## Curve Graphing

Some initial work has been done to generate graphs to visualize a lot of these animations, and you'll find that in the Graphing package. It's still heavily a work in progress, but it is pretty neat for visualizing spring / decay functions.

# Installation

## Requirements

- iOS 13+, macOS 10.15+
- Swift 5.0 or higher

Currently Motion supports Swift Package Manager, CocoaPods, Carthage, being used as an xcframework, and being used manually as an Xcode subproject. Pull requests for other dependency systems / build systems are welcome!

## Swift Package Manager

Add the following to your `Package.swift` (or add it via Xcode's GUI):

```swift
.package(url: "https://github.com/b3ll/Motion", from: "0.0.3")
```

## xcframework

A built xcframework is available for each tagged release.

## Xcode Subproject

Still working on this... (same with Carthage and Cocoapods). Pull Requests welcome!

# Example Project

There's an example project available to try animations out and see how they work. Simply open the `MotionExample-iOS.xcodeproj` from within the `Example` directory.

# Other Recommendations

This library pairs very nicely with [Decomposed](https://github.com/b3ll/Decomposed) if you wish to animate `CATransform3D` or access specific parts of it for your animations without worrying about the complex matrix math involved (i.e. `transform.translation.x`).

# License

Motion is licensed under the [BSD 2-clause license](https://github.com/b3ll/Motion/blob/master/LICENSE).

# Thanks

This project was definitely inspired by the wonderful people I've had the experience of working with over the years as well as my appreciation of thoughtfully created and highly-crafted interfaces. In addition, the work done by @timdonnelly for [Advance](https://github.com/timdonnelly/Advance) was a large inspiration for getting me started on this. I ended up writing this project as a means to further extend and just learn super in-depth all the mathematics and technical optimizations required to make a high-performance animation / interaction library. The more and more I iterated on it, the more I realized I was sharing the same mindset as I presume he did when writing Advance... brains are weird.

This project has had me really pushing the boundaries of my knowledge in terms of programming, Swift, animation, gestures, etc. and I'm really happy to be sharing it with everyone so that they may be empowered to use it too.

If you have any questions, or want to learn more, feel free to ask me anything!

# Contact Info

Feel free to follow me on twitter: [@b3ll](https://www.twitter.com/b3ll)!
