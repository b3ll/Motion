# ``Motion``

![Motion-Logo](Motion-Logo-Rendered)

## Overview

Creating animations in Motion is relatively simple. Simply allocate the animation type that you want with the type that conforms to ``SIMDRepresentable``, configure it, and call ``Animation/start()`` to start it. For each frame the animation executes, its ``ValueAnimation/onValueChanged(disableActions:_:)`` block will be called, and you'll be given the opportunity to assign that newly animated value to something.

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

Calling ``Animation/stop(resolveImmediately:postValueChanged:)`` will freeze it in place, without the need to query the `presentationLayer` on `CALayer` and set values, or worry about `fillMode`, or worry about anything really.

Whenever it's done, the completion block will be called.

The animations need to be held somewhere as they will stop running if they're deallocated. Also, due to the nature of how they execute blocks, be careful not to introduce retain cycles by not using a `weak self` or `unowned` animation inside the animation ``ValueAnimation/onValueChanged(disableActions:_:)`` or ``Animation/completion`` block.

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

> Note: Some of you may be wondering if it's a mistake that the ``SpringAnimation/stiffness``, ``SpringAnimation/damping``, ``SpringAnimation/response``, or ``SpringAnimation/dampingRatio`` setters are private, however this is intentional. It's incredibly easy to mixup ``SpringAnimation/damping`` and ``SpringAnimation/dampingRatio``, and using one over the other will lead to dramatically different results. In addition, you should only be configuring either ``SpringAnimation/stiffness`` and ``SpringAnimation/damping`` **or** ``SpringAnimation/response`` and ``SpringAnimation/dampingRatio`` as they're both two separate ways of configuring spring constants.

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

> Note: All of these animations are to run and be interfaced with on the **main thread only**. There is no support for threading of any kind.

## Motion vs. Core Animation

Motion is not designed to be a general-purpose replacement for Core Animation. Core Animation animations are run in a special way, in another process, outside of your app and are designed to be smooth even when the main thread is being heavily used. Motion on the other head is all run in-process (like a game engine), and using it liberally without considering heavy stack traces, will result in poor performance and dropped frames. Motion itself is not slow (in fact it's really **fast**!), but calling methods to change view / layer properties or change layout at 60 FPS (or more) can be really taxing if not done carefully.

> Tip: Treat Motion animations as you would a `UIScrollView` (since scrolling animations behave the same way). If you have too much going on in your `UIScrollView` it'll lag when it scrolls; the same applies to Motion.

Some key tips:

- Measure text / layout asychronously, and then commit those changes back to the main thread whenever possible.
- Layout a view controller fully before presenting (rather than during presenting) using `setNeedsDisplay()` and `layoutIfNeeded()`.
- Avoid expensive operations during gestures / handing off from gestures.
- If you can't optimize things any further, using ``CAKeyframeAnimationEmittable`` to generate a keyframe animation.

## SIMD

SIMD powers a lot of how Motion works and avoids having to use more "expensive" objects like `NSValue` or `NSNumber` to animate. SIMD grants the ability to pack multiple values into a single SIMD register and then perform math on all those values simultaneously (Single Instruction Multiple Data). This means you can do neat things like animate a `CGRect` to another `CGRect` in a single super fast operation (rather than 4 separate operations: `x`, `y,`, `width`, `height`). It's not always the silver bullet, but on average, it's at least on par, and often faster than the naive implementation.

Motion exposes a protocol called ``SIMDRepresentable`` that allows for easy boxing and unboxing of values:

```swift
let point = CGPoint(x: 10.0, y: 10.0)
let simdPoint: SIMD2<CGFloat.NativeType> = point.simdRepresentation()
let pointBoxedAgain = CGPoint(simdPoint)
```

These conversions are relatively inexpensive, and Motion has been heavily optimized to avoid copying or boxing/unboxing them whenever it can.

For more information on SIMD, check out the [docs](https://developer.apple.com/documentation/accelerate/simd).

## Additions

Motion features some great additions to aid in creating interactions in general.

### Rubberbanding

Rubberbanding is the act of making values appear to be on a rubberband (they stretch and slip based on interaction). `UIScrollView` does this when you're pulling past the `contentSize` and by using the rubberband functions in Motion you can re-create this interaction for yourself. See the "ScrollView Demo" inside the example app for more info.

### CAKeyframeAnimationEmittable

All animations in Motion conform to ``CAKeyframeAnimationEmittable`` and that means that for any animation you configure, you can have it automatically generate a `CAKeyframeAnimation` that mirrors what would happen if you were to animate things using ``Animation/start()``. The duration, and everything else is automatically calculated by running the animation from ``ValueAnimation/value`` to the resolved state. The only difference is ``ValueAnimation/onValueChanged(disableActions:_:)`` and ``Animation/completion`` cannot be used, and you must specify a keypath to animate. There are also some helper methods to make this even easier (like adding any animation to a `CALayer` directly).

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

> Note: If you remove or interrupt the animation and you want it to stay in place on screen, much like all other Core Animation animations, you'll need to grab the value from the layer's `presentationLayer` and apply that to the layer (as well as worry about `fillMode`).

```swift
let frame = layer.presentationLayer()?.frame ?? layer.frame
layer.removeAnimation(forKey: "MyAnimation")
CADisableActions {
    layer.frame = frame
}
```

### Action Disabling

`CATransaction` is a really useful API but can easily break things if you forget to pair up `CATransaction.begin()` and `CATransaction.commit()` calls.

``CADisableActions(_:)`` can be very helpful to reduce errors created when working with `CATransaction` to disable implicit animations:

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

In addition, you can also disable implicit animations in every single ``ValueAnimation/onValueChanged(disableActions:_:)`` invocation:

```swift
let springAnimation = SpringAnimation<CGFloat>(initialValue: 0.5)
springAnimation.onValueChanged(disableActions: true) { newValue in
    layer.opacity = newValue
}
springAnimation.start()
```

## Other Recommendations

This library pairs very nicely with [Decomposed](https://github.com/b3ll/Decomposed) if you wish to animate `CATransform3D` or access specific parts of it for your animations without worrying about the complex matrix math involved (i.e. `transform.translation.x`).

## License

Motion is licensed under the [BSD 2-clause license](https://github.com/b3ll/Motion/blob/master/LICENSE).

## Contact Info

Feel free to follow me on twitter: [@b3ll](https://www.twitter.com/b3ll)!
