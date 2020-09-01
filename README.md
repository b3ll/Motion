# Motion

```swift
let springAnimation = SpringAnimation<CGRect>()
springAnimation.configure(response: 0.30, damping: 0.99)
springAnimation.toValue = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 320.0)
springAnimation.velocity = CGRect(x: 0.0, y: 0.0, width: -200.0, height: -200.0)
springAnimation.valueChanged(disableActions: true) { newValue in
    view.bounds = newValue
}
springAnimation.start()
```
