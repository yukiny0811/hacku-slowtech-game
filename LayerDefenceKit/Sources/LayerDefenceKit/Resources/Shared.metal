

#include <metal_stdlib>
#include <simd/simd.h>
#include "../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
using namespace metal;

constant float PI = 3.14159265;

constant float tile64_fullSize = 1280.0;
constant float tile64_SingleSize = 64.0;

// tile rgba: tileType, remainingHP, nil, nil
// route rgba: routeDist, routeFlag(0 ok, 1 needs update), wallFlag(0 not wall, 1 wall), nil

inline float rand(int x, int y, int z) {
    int seed = x + y * 57 + z * 241;
    seed = (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

inline ushort2 getTilePosFromViewPosition(PlayerUniform playerUniform, int drawableTexWidth, int drawableTexHeight) {
    float2 playerPosition = playerUniform.position;
    float playerFovRadius = playerUniform.fovRadius;
    float aspectRatio = float(drawableTexHeight) / float(drawableTexWidth);
    float4 frame = float4(
                          playerPosition.x - playerFovRadius,
                          playerPosition.y - playerFovRadius * aspectRatio,
                          playerFovRadius * 2,
                          playerFovRadius * aspectRatio * 2
                          );
    
    ushort2 tileTextureGid = ushort2(
                                     ushort(frame.x + frame.z * playerUniform.normalizedMousePos.x),
                                     ushort(frame.y + frame.w * (1.0 - playerUniform.normalizedMousePos.y))
                                     );
    return tileTextureGid;
}

inline ushort2 floatingTilePositionToGid(float2 position) {
    return ushort2(int(position.x), int(position.y));
}

struct GameEntityVertIn {
    float2 position [[ attribute(0) ]];
    float collisionRadius [[ attribute(1) ]];
    float remainingHP [[ attribute(2) ]];
    int isDead [[ attribute(3) ]];
    int entityType [[ attribute(4) ]];
};

struct RasterizerData {
    float4 position [[ position ]];
    float size [[point_size]];
    int2 entityTextureIndex [[ flat ]];
    int isDead [[ flat ]];
};
