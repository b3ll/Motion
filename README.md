# Motion

![Tests](https://github.com/b3ll/Motion/workflows/Tests/badge.svg)
![Docs](https://github.com/b3ll/Motion/workflows/Docs/badge.svg)

Motion is an animation engine for gesturally-driven user interfaces, animations, and interactions on iOS, macOS, and tvOS, and is powered by SIMD and written fully in Swift. Motion allows for easily creating physically-modeled, interruptible animations (i.e. springs, decays, etc.) that work hand-in-hand with gesture recognizers to make the most fluid and delightful interactions possible.

Documentation is here: https://b3ll.github.io/Motion

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
