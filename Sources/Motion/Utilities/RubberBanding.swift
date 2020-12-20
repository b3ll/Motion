//
//  RubberBanding.swift
//  
//
//  Created by Adam Bell on 8/27/20.
//

import Foundation
import QuartzCore

/// The standard rubberbanding constant for `UIScrollView`.
public let UIScrollViewRubberBandingConstant = 0.55

/**
 Rubberbands a floating point value based on a given coefficient and range.

 - Parameters:
   - value: The floating point value to rubberband.
   - coefficient: A multiplier to decay the value when it's being rubberbanded. Defaults to `UIScrollViewRubberBandingConstant`.
   - boundsSize: The viewport dimension (i.e. the bounds along the axis of a scroll view)).
   - contentSize: The size of the content over which the value won't rubberband (i.e. the contentSize along the axis of a scroll view).

 ```
 bounds.origin.x = rubberband(bounds.origin.x - translation.x, boundsSize: bounds.size.width, contentSize: contentSize.width)
 ```

 - Note: See `CustomCustomScrollView` in the example project for more a more complete example on how to use this.
 */
public func rubberband<Value: FloatingPointInitializable>(_ value: Value, coefficient: Value = Value(UIScrollViewRubberBandingConstant), boundsSize: Value, contentSize: Value) -> Value {
    var exceededContentsPositively = false
    let x: Value
    if (value + boundsSize) > contentSize {
        x = abs(contentSize - boundsSize - value)
        exceededContentsPositively = true
    } else if value < 0.0 {
        x = -value
    } else {
        return value
    }

    // (1.0 - (1.0 / ((x * c / d) + 1.0))) * d

    // Without this, the swift type checker is super slow.
    let x1 = (x * coefficient / boundsSize) + 1.0

    let rubberBandedAmount = ((1.0 - (1.0 / x1)) * boundsSize)

    // We're beyond the range
    if exceededContentsPositively {
        return rubberBandedAmount + contentSize - boundsSize
    } else { // We're beyond the range in the opposite direction
        return -rubberBandedAmount
    }
}

// TODO: SIMD variants at some point. It's kinda tricky.
