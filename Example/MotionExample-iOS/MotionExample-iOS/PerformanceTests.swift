//
//  PerformanceTests.swift
//  MotionExample-iOS
//
//  Created by Adam Bell on 9/12/20.
//

import CoreGraphics
import Foundation
import Motion
import os.signpost

let log = OSLog(
    subsystem: "ca.adambell.motiontests.app",
    category: .pointsOfInterest
)

@inline(never) func testSpringAnimationExecutionCGRect() {
    let targetFrameTime: CFTimeInterval = 1.0 / 60.0

    // Measure execution of 500 springs animating CGRects (technically 4000 springs :D)
    // SIMD go brrrrrrrrrr

    for _ in (0...10) {
        let springs = (0...500).map { (_) -> SpringAnimation<CGRect> in
            let springAnimation = SpringAnimation<CGRect>(initialValue: .zero)
            springAnimation.toValue = CGRect(x: 320.0, y: 320.0, width: 320.0, height: 320.0)
            return springAnimation
        }

        let start = CFAbsoluteTimeGetCurrent()

        let signpostID = OSSignpostID(log: log)

        os_signpost(.begin, log: log, name: "Springs CGRect", signpostID: signpostID)

        for springAnimation in springs {
            springAnimation.tick(targetFrameTime)
            let _ = springAnimation.value
        }

        os_signpost(.end, log: log, name: "Springs CGRect", signpostID: signpostID)

        let time = CFAbsoluteTimeGetCurrent() - start

        print(time)
    }

    print("done")
}

@inline(never) func testSpringAnimationExecutionDouble() {
    let targetFrameTime: CFTimeInterval = 1.0 / 60.0

    for _ in (0...10) {
        let springs = (0...500).map { (_) -> SpringAnimation<Double> in
            let springAnimation = SpringAnimation<Double>(initialValue: 0.0)
            springAnimation.toValue = 320.0
            return springAnimation
        }

        let start = CFAbsoluteTimeGetCurrent()

        let signpostID = OSSignpostID(log: log)

        os_signpost(.begin, log: log, name: "Springs Double", signpostID: signpostID)

        for springAnimation in springs {
            springAnimation.tick(targetFrameTime)
            let _ = springAnimation.value
        }

        os_signpost(.end, log: log, name: "Springs Double", signpostID: signpostID)

        let time = CFAbsoluteTimeGetCurrent() - start

        print(time)
    }

    print("done")
}

@inline(never) func testSpringExecutionSIMD64() {
    let targetFrameTime: CFTimeInterval = 1.0 / 60.0

    for _ in (0...10) {
        let springs = Array<SpringFunction<SIMD64<Double>>>(repeating: SpringFunction<SIMD64<Double>>(), count: 500)

        let toValue = SIMD64<Double>(repeating: 320.0)

        var velocities = Array<SIMD64<Double>>(repeating: .zero, count: 500)

        let start = CFAbsoluteTimeGetCurrent()

        let signpostID = OSSignpostID(log: log)

        os_signpost(.begin, log: log, name: "Springs SIMD64", signpostID: signpostID)

        for (i, spring) in springs.enumerated() {
            let _ = spring.solve(dt: targetFrameTime, x0: toValue, velocity: &velocities[i])
        }

        os_signpost(.end, log: log, name: "Springs SIMD64", signpostID: signpostID)

        let time = CFAbsoluteTimeGetCurrent() - start

        print(time)
    }

    print("done")
}

@inline(never) func testSpringAnimationExecutionSIMD64() {
    let targetFrameTime: CFTimeInterval = 1.0 / 60.0

    for _ in (0...10) {
        let springs = (0...500).map { (_) -> SpringAnimation<SIMD64<Double>> in
            let springAnimation = SpringAnimation<SIMD64<Double>>(initialValue: .zero)
            springAnimation.toValue = SIMD64<Double>(repeating: 320.0)
            return springAnimation
        }

        let start = CFAbsoluteTimeGetCurrent()

        let signpostID = OSSignpostID(log: log)

        os_signpost(.begin, log: log, name: "Spring Animations SIMD64", signpostID: signpostID)

        for springAnimation in springs {
            springAnimation.tick(targetFrameTime)
            let _ = springAnimation.value
        }

        os_signpost(.end, log: log, name: "Spring Animations SIMD64", signpostID: signpostID)

        let time = CFAbsoluteTimeGetCurrent() - start

        print(time)
    }

    print("done")
}
