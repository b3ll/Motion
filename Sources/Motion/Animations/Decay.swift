//
//  File.swift
//  
//
//  Created by Adam Bell on 9/16/20.
//

import Foundation
import RealModule
import simd

public let UIKitDecayConstant: Double = 0.998

public struct Decay<SIMDType: SupportedSIMD> {

    public var decayConstant: SIMDType.Scalar {
        didSet {
            updateConstants()
        }
    }

    private(set) public var one_ln_decayConstant_1000: SIMDType.Scalar = 0.0

    init(decayConstant: SIMDType.Scalar = SIMDType.Scalar(UIKitDecayConstant)) {
        self.decayConstant = decayConstant
        // Explicitly update constants.
        updateConstants()
    }

    private mutating func updateConstants() {
        self.one_ln_decayConstant_1000 = 1.0 / (SIMDType.Scalar.log(decayConstant) * 1000.0)
    }

    @inlinable public func solve(dt: SIMDType.Scalar, x0: SIMDType, velocity: inout SIMDType) -> SIMDType {
        let d_1000_dt = SIMDType.Scalar.pow(decayConstant, 1000.0 * dt)

        // Analytic decay equation with constants extracted out.
        let x = x0 + velocity * ((d_1000_dt - 1.0) * one_ln_decayConstant_1000)

        // Velocity is the derivative of the above equation
        velocity = velocity * d_1000_dt

        return x
    }

}
