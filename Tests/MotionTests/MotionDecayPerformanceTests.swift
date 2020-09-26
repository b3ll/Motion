//
//  MotionDecayPerformanceTests.swift
//  
//
//  Created by Adam Bell on 9/16/20.
//

import XCTest

@testable import Motion

fileprivate let targetFrameTime: CFTimeInterval = 1.0 / 60.0
fileprivate let defaultVelocity: Double = 2000.0

fileprivate func generateDecayAnimations<Value: SIMDRepresentable>(velocity: Value) -> [DecayAnimation<Value>] {
    let decayAnimations = (0...500).map { (_) -> DecayAnimation<Value> in
        let decayAnimation = DecayAnimation<Value>(initialValue: .zero)
        decayAnimation.velocity = velocity
        return decayAnimation
    }
    return decayAnimations
}

final class MotionDecayPerformanceTests: XCTestCase {

    func testDecayExecutionDouble() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let decays = Array(repeating: DecayFunction<SIMD2<Double>>(), count: 500)

            var velocities = Array<SIMD2<Double>>(repeating: .zero, count: 500)

            startMeasuring()

            for (index, decay) in decays.enumerated() {
                let _ = decay.solve(dt: targetFrameTime, x0: SIMD2<Double>.zero, velocity: &velocities[index])
            }

            stopMeasuring()
        }
    }

    func testDecayAnimationExecutionDouble() {

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let decayAnimations: [DecayAnimation<Double>] = generateDecayAnimations(velocity: defaultVelocity)

            startMeasuring()

            for decayAnimation in decayAnimations {
                decayAnimation.tick(targetFrameTime)
                let _ = decayAnimation.value
            }

            stopMeasuring()
        }
    }

    func testDecayExecutionCGRect() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let decays = Array(repeating: DecayFunction<SIMD4<Double>>(), count: 500)

            var velocities = Array<SIMD4<Double>>(repeating: .zero, count: 500)

            startMeasuring()

            for (index, decay) in decays.enumerated() {
                let _ = decay.solve(dt: targetFrameTime, x0: SIMD4<Double>.zero, velocity: &velocities[index])
            }

            stopMeasuring()
        }
    }

    func testDecayAnimationExecutionCGRect() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let decayAnimations: [DecayAnimation<CGRect>] = generateDecayAnimations(velocity: CGRect(x: defaultVelocity, y: defaultVelocity, width: defaultVelocity, height: defaultVelocity))

            startMeasuring()

            for decayAnimation in decayAnimations {
                decayAnimation.tick(targetFrameTime)
                let _ = decayAnimation.value
            }

            stopMeasuring()
        }
    }

    func testDecayExecutionSIMD64() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let decays = Array(repeating: DecayFunction<SIMD64<Double>>(), count: 500)

            var velocities = Array<SIMD64<Double>>(repeating: .zero, count: 500)

            startMeasuring()

            for (index, decay) in decays.enumerated() {
                let _ = decay.solve(dt: targetFrameTime, x0: SIMD64<Double>.zero, velocity: &velocities[index])
            }

            stopMeasuring()
        }
    }

    func testDecayAnimationExecutionSIMD64() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let decayAnimations: [DecayAnimation<SIMD64<Double>>] = generateDecayAnimations(velocity: SIMD64<Double>(repeating: defaultVelocity))

            startMeasuring()

            for decayAnimation in decayAnimations {
                decayAnimation.tick(targetFrameTime)
                let _ = decayAnimation.value
            }

            stopMeasuring()
        }
    }

    static var allTests = [
        ("testDecayExecutionDouble", testDecayExecutionDouble),
        ("testDecayAnimationExecutionDouble", testDecayAnimationExecutionDouble),
        ("testDecayExecutionCGRect", testDecayExecutionCGRect),
        ("testDecayAnimationExecutionCGRect", testDecayAnimationExecutionCGRect),
        ("testDecayExecutionSIMD64", testDecayExecutionSIMD64),
        ("testDecayAnimationExecutionSIMD64", testDecayAnimationExecutionSIMD64),
    ]

}
