//
//  MotionPerformanceTests.swift
//  
//
//  Created by Adam Bell on 9/12/20.
//

import XCTest

@testable import Motion
@testable import MotionC

fileprivate let targetFrameTime: CFTimeInterval = 1.0 / 60.0
fileprivate let defaultToValue: Double = 320.0

fileprivate func generateSpringAnimations<Value: SIMDRepresentable>(toValue: Value) -> [SpringAnimation<Value>] {
    let springAnimations = (0...500).map { (_) -> SpringAnimation<Value> in
        let springAnimation = SpringAnimation<Value>(initialValue: .zero)
        springAnimation.toValue = toValue
        return springAnimation
    }
    return springAnimations
}

final class MotionSpringPerformanceTests: XCTestCase {

    func testSpringExecutionDouble() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let springs = Array(repeating: Spring<SIMD2<Double>>(stiffness: 300.0, damping: 10.0), count: 500)
            let toValue = SIMD2<Double>(repeating: 64.0)

            var velocities = Array<SIMD2<Double>>(repeating: .zero, count: 500)

            startMeasuring()

            for (index, spring) in springs.enumerated() {
                let _ = spring.solve(dt: targetFrameTime, x0: toValue, velocity: &velocities[index])
            }

            stopMeasuring()
        }
    }

    func testSpringAnimationExecutionDouble() {

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let springAnimations = generateSpringAnimations(toValue: defaultToValue)

            startMeasuring()

            for springAnimation in springAnimations {
                springAnimation.tick(targetFrameTime)
                let _ = springAnimation.value
            }

            stopMeasuring()
        }
    }

    func testSpringExecutionCGRect() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let springs = Array(repeating: Spring<SIMD4<Double>>(stiffness: 300.0, damping: 10.0), count: 500)
            let toValue = SIMD4<Double>(repeating: 64.0)

            var velocities = Array<SIMD4<Double>>(repeating: .zero, count: 500)

            startMeasuring()

            for (index, spring) in springs.enumerated() {
                let _ = spring.solve(dt: targetFrameTime, x0: toValue, velocity: &velocities[index])
            }

            stopMeasuring()
        }
    }

    // Measure execution of 500 springs animating CGRects (technically 4000 springs :D)
    // haha SIMD go brrrrrrrrrr
    func testSpringAnimationExecutionCGRect() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let springAnimations = generateSpringAnimations(toValue: CGRect(x: defaultToValue, y: defaultToValue, width: defaultToValue, height: defaultToValue))

            startMeasuring()

            for springAnimation in springAnimations {
                springAnimation.tick(targetFrameTime)
                let _ = springAnimation.value
            }

            stopMeasuring()
        }
    }

    func testSpringExecutionSIMD64() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let springs = Array(repeating: Spring<SIMD64<Double>>(stiffness: 300.0, damping: 10.0), count: 500)
            let toValue = SIMD64<Double>(repeating: 64.0)

            var velocities = Array<SIMD64<Double>>(repeating: .zero, count: 500)

            startMeasuring()

            for (index, spring) in springs.enumerated() {
                let _ = spring.solve(dt: targetFrameTime, x0: toValue, velocity: &velocities[index])
            }

            stopMeasuring()
        }
    }

    func testSpringAnimationExecutionSIMD64() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let springAnimations = generateSpringAnimations(toValue: SIMD64<Double>(repeating: 320.0))

            startMeasuring()

            for springAnimation in springAnimations {
                springAnimation.tick(targetFrameTime)
                let _ = springAnimation.value
            }

            stopMeasuring()
        }
    }

    func testCSpringSIMD4() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            var springs: [SpringC] = (0...500).map { _ in return SpringC(stiffness: 300.0, damping: 10.0) }
            var velocities = Array<SIMD4<Double>>(repeating: .zero, count: 500)
            let toValue = SIMD4<Double>(repeating: Double(arc4random() % 3000))

            startMeasuring()

            for i in (0..<500) {
                let _ = SolveSpring(&springs[i], targetFrameTime, toValue, &velocities[i])
            }

            stopMeasuring()
        }
    }

    static var allTests = [
        ("testSpringExecutionDouble", testSpringExecutionDouble),
        ("testSpringAnimationExecutionDouble", testSpringAnimationExecutionDouble),
        ("testSpringExecutionCGRect", testSpringExecutionCGRect),
        ("testSpringAnimationExecutionCGRect", testSpringAnimationExecutionCGRect),
        ("testSpringExecutionSIMD64", testSpringExecutionSIMD64),
        ("testSpringAnimationExecutionSIMD64", testSpringAnimationExecutionSIMD64),
    ]

}
