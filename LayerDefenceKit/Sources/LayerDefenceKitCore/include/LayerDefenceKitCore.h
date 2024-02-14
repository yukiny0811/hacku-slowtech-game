//
//  Header.h
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

#ifndef Header_h
#define Header_h

#include <simd/simd.h>

struct PlayerUniform {
    simd_float2 position;
    float fovRadius;
    simd_float2 normalizedMousePos;
};

#endif /* Header_h */
