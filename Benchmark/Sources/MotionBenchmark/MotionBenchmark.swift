//
//  MotionBenchmark.swift
//  
//
//  Created by Adam Bell on 11/24/20.
//

import Foundation
import Benchmark
import Motion
import QuartzCore

func createAndAnimateSpringAnimations<Value: SIMDRepresentable>(to toValue: Value, count: Int, state: inout BenchmarkState) {
    autoreleasepool {
        let springAnimations = (0..<count).map { (_) -> SpringAnimation<Value> in
            let springAnimation = SpringAnimation<Value>(response: 0.5, dampingRatio: 0.987)
            springAnimation.toValue = toValue
            return springAnimation
        }

        try! state.measure {
            springAnimations.forEach { springAnimation in
                let _ = springAnimation.tick(frame: .init(1.0 / 60.0))
            }
        }
    }
}

func createAndAnimateBasicAnimations<Value: SIMDRepresentable>(to toValue: Value, count: Int, state: inout BenchmarkState) {
    autoreleasepool {
        let basicAnimations = (0..<count).map { (_) -> BasicAnimation<Value> in
            let basicAnimation = BasicAnimation<Value>(easingFunction: .easeInOut)
            basicAnimation.duration = 2.0
            basicAnimation.toValue = toValue
            return basicAnimation
        }

        try! state.measure {
            basicAnimations.forEach { basicAnimation in
                let _ = basicAnimation.tick(frame: .init(1.0 / 60.0))
            }
        }
    }
}


func createAndAnimateDecayAnimations<Value: SIMDRepresentable>(velocity: Value, count: Int, state: inout BenchmarkState) {
    autoreleasepool {
        let decayAnimations = (0..<count).map { (_) -> DecayAnimation<Value> in
            let decayAnimation = DecayAnimation<Value>()
            decayAnimation.velocity = velocity
            return decayAnimation
        }

        try! state.measure {
            decayAnimations.forEach { decayAnimation in
                let _ = decayAnimation.tick(frame: .init(1.0 / 60.0))
            }
        }
    }
}

let AnimationCount = 5000
let ToValue = 320.0

// Measure execution of 5000 animations of each type serially for each supported SIMD type.
// SIMD go brrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
public func RunBenchmark() {
    let springAnimationSuite = BenchmarkSuite(name: "SIMD SpringAnimations", settings: TimeUnit(.ms)) { suite in
        suite.benchmark("Execute 5000 CGFloat SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: CGFloat(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Float SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: Float(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Double SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: Double(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGPoint SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: CGPoint(x: ToValue, y: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGSize SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: CGSize(width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Float> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD2<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Double> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD2<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGRect SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: CGRect(x: ToValue, y: ToValue, width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Float> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD4<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Double> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD4<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Float> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD8<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Double> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD8<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Float> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD16<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Double> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD16<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Float> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD32<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Double> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD32<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Float> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD64<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Double> SpringAnimations") { state in
            createAndAnimateSpringAnimations(to: SIMD64<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }
    }

    let basicAnimationSuite = BenchmarkSuite(name: "SIMD BasicAnimations", settings: TimeUnit(.ms)) { suite in
        suite.benchmark("Execute 5000 CGFloat BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: CGFloat(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Float BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: Float(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Double BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: Double(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGPoint BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: CGPoint(x: ToValue, y: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGSize BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: CGSize(width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Float> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD2<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Double> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD2<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGRect BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: CGRect(x: ToValue, y: ToValue, width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Float> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD4<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Double> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD4<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Float> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD8<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Double> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD8<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Float> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD16<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Double> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD16<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Float> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD32<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Double> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD32<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Float> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD64<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Double> BasicAnimations") { state in
            createAndAnimateBasicAnimations(to: SIMD64<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }
    }

    let decayAnimationSuite = BenchmarkSuite(name: "SIMD DecayAnimations", settings: TimeUnit(.ms)) { suite in
        suite.benchmark("Execute 5000 CGFloat DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: CGFloat(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Float DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: Float(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Double DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: Double(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGPoint DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: CGPoint(x: ToValue, y: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGSize DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: CGSize(width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Float> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD2<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Double> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD2<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGRect DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: CGRect(x: ToValue, y: ToValue, width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Float> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD4<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Double> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD4<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Float> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD8<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Double> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD8<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Float> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD16<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Double> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD16<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Float> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD32<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Double> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD32<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Float> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD64<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Double> DecayAnimations") { state in
            createAndAnimateDecayAnimations(velocity: SIMD64<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }
    }

    Benchmark.main([springAnimationSuite, basicAnimationSuite, decayAnimationSuite], settings: [TimeUnit(.ms), Iterations(20)], customDefaults: [])
}
