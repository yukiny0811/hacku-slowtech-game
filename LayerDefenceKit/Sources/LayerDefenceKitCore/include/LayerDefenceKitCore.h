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
    int isMouseDown; //bool
    int selectedTileType;
};

struct GameEntity {
    simd_float2 position;
    float collisionRadius;
    simd_int2 entityTextureIndex;
    float speed;
    int entityType;
};

#endif /* Header_h */
