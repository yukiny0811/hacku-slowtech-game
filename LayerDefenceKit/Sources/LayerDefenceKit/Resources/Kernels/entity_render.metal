

#include <metal_stdlib>
#include <simd/simd.h>
#include "../../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
#include "../Shared.metal"
#include "../Generated.metal"
#include "../EnemyMovement.metal"
using namespace metal;

vertex RasterizerData renderEntity_vert (
                                         const GameEntityVertIn vIn [[ stage_in ]],
                                         texture2d<half, access::read> drawableTexture [[ texture(1) ]],
                                         const device PlayerUniform& playerUniform [[ buffer(1) ]]
) {
    
    float2 playerPosition = playerUniform.position;
    float playerFovRadius = playerUniform.fovRadius;
    float aspectRatio = float(drawableTexture.get_height()) / float(drawableTexture.get_width());
    float4 frame = float4(
                          playerPosition.x - playerFovRadius,
                          playerPosition.y - playerFovRadius * aspectRatio,
                          playerFovRadius * 2,
                          playerFovRadius * aspectRatio * 2
                          );
    
    float2 entityPositionInTile = vIn.position;
    float2 entityPositionOffsetInTile = entityPositionInTile - float2(frame.x, frame.y);
    float2 entityPositionNormalizedInView = float2(entityPositionOffsetInTile.x / frame.z, entityPositionOffsetInTile.y / frame.w);
    float2 entityViewportPosition = entityPositionNormalizedInView * 2 - 1.0;
    entityViewportPosition.y *= -1;
    
    RasterizerData rd;
    rd.position = float4(entityViewportPosition.x, entityViewportPosition.y, 0, 1);
    rd.size = float(drawableTexture.get_width()) / frame.z * vIn.collisionRadius;
    rd.entityTextureIndex = enemyTextureIndex(vIn.entityType);
    rd.isDead = vIn.isDead;
    return rd;
}

fragment half4 renderEntity_frag (
                                  RasterizerData rd [[stage_in]],
                                  half4 c [[color(0)]],
                                  texture2d<half, access::sample> entitiesTex [[ texture(2) ]],
                                  float2 pc [[point_coord]]
) {
    if (rd.isDead == 1) {
        return c;
    }
    
    half4 resultColor = half4(0, 0, 0, 0);
    
    float2 uv = float2(rd.entityTextureIndex.x, rd.entityTextureIndex.y) * tile64_SingleSize + pc * tile64_SingleSize;
    
    constexpr sampler textureSampler (coord::pixel, address::clamp_to_edge, filter::nearest);
    half4 entityTexRead = entitiesTex.sample(textureSampler, uv);
    
    resultColor += entityTexRead;
    
    return resultColor * resultColor.a + c * (1.0 - resultColor.a);
}
