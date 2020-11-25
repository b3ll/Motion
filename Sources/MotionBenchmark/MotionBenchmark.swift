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

func createAndAnimateSprings<Value: SIMDRepresentable>(to toValue: Value, count: Int, state: inout BenchmarkState) {
    let springs = Array<SpringFunction<Value>>(repeating: SpringFunction<Value>(), count: count)

    var velocities = Array<Value>(repeating: .zero, count: count)

    try! state.measure {
        for (i, spring) in springs.enumerated() {
            let _ = spring.solve(dt: 1.0 / 60.0, x0: toValue, velocity: &velocities[i])
        }
    }
}

let AnimationCount = 5000
let ToValue = 320.0

// Measure execution of 5000 springs serially for each supported SIMD type.
// SIMD go brrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
public func RunBenchmark() {
    let springSuite = BenchmarkSuite(name: "SIMD Springs", settings: TimeUnit(.ms)) { suite in
        suite.benchmark("Execute 5000 CGFloat springs") { state in
            createAndAnimateSprings(to: CGFloat(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Float springs") { state in
            createAndAnimateSprings(to: Float(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 Double springs") { state in
            createAndAnimateSprings(to: Double(ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGPoint springs") { state in
            createAndAnimateSprings(to: CGPoint(x: ToValue, y: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGSize springs") { state in
            createAndAnimateSprings(to: CGSize(width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Float> springs") { state in
            createAndAnimateSprings(to: SIMD2<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD2<Double> springs") { state in
            createAndAnimateSprings(to: SIMD2<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 CGRect springs") { state in
            createAndAnimateSprings(to: CGRect(x: ToValue, y: ToValue, width: ToValue, height: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Float> springs") { state in
            createAndAnimateSprings(to: SIMD4<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD4<Double> springs") { state in
            createAndAnimateSprings(to: SIMD4<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Float> springs") { state in
            createAndAnimateSprings(to: SIMD8<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD8<Double> springs") { state in
            createAndAnimateSprings(to: SIMD8<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Float> springs") { state in
            createAndAnimateSprings(to: SIMD16<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD16<Double> springs") { state in
            createAndAnimateSprings(to: SIMD16<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Float> springs") { state in
            createAndAnimateSprings(to: SIMD32<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD32<Double> springs") { state in
            createAndAnimateSprings(to: SIMD32<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Float> springs") { state in
            createAndAnimateSprings(to: SIMD64<Float>(repeating: Float(ToValue)), count: AnimationCount, state: &state)
        }

        suite.benchmark("Execute 5000 SIMD64<Double> springs") { state in
            createAndAnimateSprings(to: SIMD64<Double>(repeating: ToValue), count: AnimationCount, state: &state)
        }
    }

    Benchmark.main([springSuite], settings: [TimeUnit(.ms)], customDefaults: [])
}
