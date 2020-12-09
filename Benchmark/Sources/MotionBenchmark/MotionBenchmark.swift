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

func createAndAnimateSpringFunctions<Value: SIMDRepresentable>(to toValue: Value, count: Int, state: inout BenchmarkState) {
    let springFunctions = Array<SpringFunction<Value>>(repeating: SpringFunction(response: 0.5, dampingRatio: 0.987), count: count)

    var velocities = Array<Value>(repeating: .zero, count: count)

    try! state.measure {
        for (i, springFunction) in springFunctions.enumerated() {
            let _ = springFunction.solve(dt: 1.0 / 60.0, x0: toValue, velocity: &velocities[i])
        }
    }
}

func createAndAnimateEasingFunctions<Value: SIMDRepresentable>(to toValue: Value, count: Int, state: inout BenchmarkState) {
    let easingFunctions = Array<EasingFunction<Value>>(repeating: EasingFunction<Value>.easeInOut, count: count)

    let range = Value.zero...toValue

    try! state.measure {
        for (_, easingFunction) in easingFunctions.enumerated() {
            let _ = easingFunction.solveInterpolatedValue(range, fraction: 0.25)
        }
    }
}


func createAndAnimateDecayFunctions<Value: SIMDRepresentable>(velocity: Value, count: Int, state: inout BenchmarkState) {
    let decayFunctions = Array<DecayFunction<Value>>(repeating: DecayFunction<Value>(), count: count)

    var velocities = Array<Value>(repeating: velocity, count: count)

    try! state.measure {
        for (i, decayFunction) in decayFunctions.enumerated() {
            let _ = decayFunction.solve(dt: 1.0 / 60.0, x0: .zero, velocity: &velocities[i])
        }
    }
}

let AnimationCount = 5000
let ToValue = 320.0

// Measure execution of 5000 springs serially for each supported SIMD type.
// SIMD go brrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
public func RunBenchmark() {
    let springFunctionSuite = BenchmarkSuite(name: "SIMD SpringFunctions", settings: TimeUnit(.ms)) { suite in
        suite.benchmark("Execute 5000 CGFloat SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: CGFloat(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Float SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: Float(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Double SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: Double(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGPoint SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: CGPoint(x: ToValue, y: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGSize SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: CGSize(width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Float> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD2<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Double> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD2<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGRect SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: CGRect(x: ToValue, y: ToValue, width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Float> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD4<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Double> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD4<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Float> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD8<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Double> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD8<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Float> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD16<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Double> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD16<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Float> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD32<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Double> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD32<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Float> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD64<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Double> SpringFunctions") { state in
            createAndAnimateSpringFunctions(to: SIMD64<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }
    }

    let easingFunctionSuite = BenchmarkSuite(name: "SIMD EasingFunctions", settings: TimeUnit(.ms)) { suite in
        suite.benchmark("Execute 5000 CGFloat EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: CGFloat(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Float EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: Float(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Double EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: Double(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGPoint EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: CGPoint(x: ToValue, y: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGSize EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: CGSize(width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Float> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD2<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Double> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD2<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGRect EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: CGRect(x: ToValue, y: ToValue, width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Float> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD4<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Double> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD4<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Float> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD8<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Double> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD8<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Float> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD16<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Double> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD16<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Float> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD32<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Double> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD32<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Float> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD64<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Double> EasingFunctions") { state in
            createAndAnimateEasingFunctions(to: SIMD64<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }
    }

    let decayFunctionSuite = BenchmarkSuite(name: "SIMD DecayFunctions", settings: TimeUnit(.ms)) { suite in
        suite.benchmark("Execute 5000 CGFloat DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: CGFloat(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Float DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: Float(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Double DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: Double(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGPoint DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: CGPoint(x: ToValue, y: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGSize DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: CGSize(width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Float> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD2<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Double> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD2<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGRect DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: CGRect(x: ToValue, y: ToValue, width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Float> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD4<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Double> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD4<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Float> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD8<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Double> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD8<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Float> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD16<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Double> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD16<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Float> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD32<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Double> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD32<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Float> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD64<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Double> DecayFunctions") { state in
            createAndAnimateDecayFunctions(velocity: SIMD64<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }
    }


    Benchmark.main([springFunctionSuite, easingFunctionSuite, decayFunctionSuite], settings: [TimeUnit(.ms)], customDefaults: [])
}
