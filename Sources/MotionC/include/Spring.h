//
//  Spring.h
//  
//
//  Created by Adam Bell on 9/19/20.
//

#ifndef File_h
#define File_h

#include <stdio.h>
#import <simd/SIMD.h>

struct SpringC {
    double stiffness;
    double damping;
};

extern simd_double4 SolveSpring(struct SpringC *spring, double dt, simd_double4 x0, simd_double4 *velocity);

#endif /* Spring_h */
