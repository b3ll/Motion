# Motion

![Tests](https://github.com/b3ll/Motion/workflows/Tests/badge.svg)
![Docs](https://github.com/b3ll/Motion/workflows/Docs/badge.svg)

Motion is an animation engine for gesturally-driven user interfaces, animations, and interactions on iOS, macOS, and tvOS, and is powered by SIMD and written fully in Swift. Motion allows for easily creating physically-modeled, interruptible animations (i.e. springs, decays, etc.) that work hand-in-hand with gesture recognizers to make the most fluid and delightful interactions possible.

Documentation is here: https://b3ll.github.io/Motion

- [Motion](#motion)
- [Usage](#usage)
    - [Spring Animation](#spring-animation)
    - [Decay Animation](#decay-animation)
    - [Basic Animation](#basic-animation)
- [Interruptibility](#interruptibility)
- [SIMD](#simd)
- [Performance](#performance)
  - [CAKeyframeAnimationEmittable](#cakeyframeanimationemittable)

# Usage

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

# Interruptibility

Interruptibility is when you have the ability to interrupt an animation in flight so you can stop, change, or restart it. Normally, with `UIView` block-based animations, or Core Animation based animations, this is really difficult to do (need to cancel the animation, figure out its current state on screen, apply that, etc.). `UIViewPropertyAnimator` works okay for this, but it relies heavily on "scrubbing" animations, which when working with physically-based animations (i.e. springs), that doesn't really make a lot of sense, since the physics are what generate the animation dynamically (vs. some predefined easing curve you can scrub).

Motion supports interruptible animations out of the box, which makes gesturally-driven interactions trivial.

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

**Note**: This example is in the example project.

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

Motion is pretty dang fast, leveraging some manual Swift optimization / specialization as well as SIMD it's capable of executing 5000 `SpringAnimation<SIMD64<Double>>` in **~150ms** (that's 320,000 springs!!). For smaller types like `CGFloat`, it can do the same thing in **~0.08ms**.

Is it as fast as it could be? Faster than some C++ or C implementation? No idea.
That being said, it's definitely fast enough for interactions on devices and rarely (if ever) will be the bottleneck.

In short: SIMD go brrrrrrrrrrrrrrrrrrrrrrr

If you'd like benchmark Motion on your own device, simply run the following from within the `Benchmark` folder:

```bash
swift run -c release MotionBenchmarkRunner --time-unit ms
```

That being said, these animations are run on the **main thread only**. There is no support for threading of any kind. In addition, becuase these animations are run on the main thread (and not out of process, like Core Animation) if your layout or view drawing is too slow, you **will** drop frames. This is expected and that's because the animations here behave like `UIScrollView` animations (if you have too much going on in your `UIScrollView` it'll lag when it scrolls).

Some key tips:

- Measure text / layout asychronously whenever possible.
- Layout a view controller fully before presenting (rather than during presenting) using `setNeedsDisplay()` and `layoutIfNeeded()`.
- Avoid expensive operations during gestures / handing off from gestures.
- If you can't optimize things any further, using `CAKeyframeAnimation` will help, and that's outlined in the next section.

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
