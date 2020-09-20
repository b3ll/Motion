//
//  Spring.c
//  
//
//  Created by Adam Bell on 9/19/20.
//

#include "Spring.h"

simd_double4 SolveSpring(struct SpringC *spring, double dt, simd_double4 x0, simd_double4 *velocity) {
    const double stiffness = spring->stiffness;
    const double damping = spring->damping;

    const double w0 = sqrt(stiffness);
    const double dampingRatio = damping / (2.0 * w0);
    const double wD = w0 * sqrt(1.0 - dampingRatio * dampingRatio);

    simd_double4 x;
    if (dampingRatio < 1.0) {
        const double decayEnvelope = -dampingRatio * w0 * dt;
        const double sin_wD_dt = sin(wD * dt);
        const double cos_wD_dt = cos(wD * dt);

        const simd_double4 velocity_x0_dampingRatio_w0 = (*velocity + x0) * (dampingRatio * w0);

        const simd_double4 A = x0;
        const simd_double4 B = velocity_x0_dampingRatio_w0 / wD;

        x = decayEnvelope * (A * cos_wD_dt + B * sin_wD_dt);

        const simd_double4 d_x = velocity_x0_dampingRatio_w0 * cos_wD_dt - x0 * (wD * sin_wD_dt);
        *velocity = -(dampingRatio * w0 * x - decayEnvelope * d_x);
    }

    return x;
};
