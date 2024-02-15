
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
using namespace metal;

constant float PI = 3.14159265;

constant float tile64_fullSize = 1280.0;
constant float tile64_SingleSize = 64.0;

inline float rand(int x, int y, int z) {
    int seed = x + y * 57 + z * 241;
    seed = (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

kernel void initLayer(
                      texture2d<float, access::write> tileTexture [[ texture(0) ]],
                      ushort2 gid [[ thread_position_in_grid ]]
) {
    int tileType = int(rand(int(gid.x * 358), int(gid.y * 123), 149) * 3);
    tileTexture.write(float4(float(tileType), 0, 0, 0), gid);
}

kernel void updateLayer(
                        texture2d<float, access::read_write> tileTexture [[ texture(0) ]],
                        ushort2 gid [[ thread_position_in_grid ]]
) {

}

kernel void renderLayer(
                        texture2d<float, access::read> tileTexture [[ texture(0) ]],
                        texture2d<half, access::write> drawableTexture [[ texture(1) ]],
                        texture2d<half, access::sample> tiles [[ texture(2) ]],
                        const device PlayerUniform& playerUniform [[ buffer(0) ]],
                        ushort2 gid [[ thread_position_in_grid ]] //gid in drawableTexture
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
    
    float2 normalizedGidPosition = float2(
                                          float(gid.x) / float(drawableTexture.get_width()),
                                          float(gid.y) / float(drawableTexture.get_height())
                                          );
    ushort2 tileTextureGid = ushort2(
                                     ushort(frame.x + frame.z * normalizedGidPosition.x),
                                     ushort(frame.y + frame.w * normalizedGidPosition.y)
                                     );
    
    float2 tilePixelPos = float2(frame.x + frame.z * normalizedGidPosition.x, frame.y + frame.w * normalizedGidPosition.y);
    float2 tilePixelOrigin = float2(int2(tilePixelPos));
    float2 tileUV = (tilePixelPos - tilePixelOrigin) / 1.0;
    
    constexpr sampler textureSampler (coord::pixel, address::clamp_to_edge, filter::nearest);
    
    float4 tileTexRead = tileTexture.read(tileTextureGid);
    int tileType = int(tileTexRead.r);
    
    int2 tileIndex = int2(0, 0);
    if (tileType == 0) {
        tileIndex = int2(0, 0);
    } else if (tileType == 1) {
        tileIndex = int2(1, 0);
    } else if (tileType == 2) {
        tileIndex = int2(2, 0);
    }
    half4 sampled = tiles.sample(
                                       textureSampler,
                                       float2(
                                              tile64_SingleSize * float(tileIndex.x) + tileUV.x * tile64_SingleSize,
                                              tile64_SingleSize * float(tileIndex.y) + tileUV.y * tile64_SingleSize
                                              )
                                       );
    
    float2 playerNormalizedMousePos = playerUniform.normalizedMousePos;
    ushort2 tileTextureGid_mousePos = ushort2(
                                     ushort(frame.x + frame.z * playerNormalizedMousePos.x),
                                     ushort(frame.y + frame.w * (1.0 - playerNormalizedMousePos.y))
                                     );
    
    if (tileTextureGid.x == tileTextureGid_mousePos.x && tileTextureGid.y == tileTextureGid_mousePos.y) {
        sampled += half4(0.2, 0.2, 0.2, 0);
    }
    
    drawableTexture.write(sampled, gid);
}

struct GameEntityVertIn {
    float2 position [[ attribute(0) ]];
    float collisionRadius [[ attribute(1) ]];
    int2 entityTextureIndex [[ attribute(2) ]];
};

struct RasterizerData {
    float4 position [[ position ]];
    float size [[point_size]];
    int2 entityTextureIndex [[ flat ]];
};

kernel void updateEntity(
                         device GameEntity* entities [[ buffer(0) ]],
                         const device GameEntity& enemyTarget [[ buffer(1) ]],
                         uint index [[thread_position_in_grid]]
) {
    float2 toEnemyDir = normalize(enemyTarget.position - entities[index].position);
    entities[index].position += toEnemyDir * 0.1;
}

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
    rd.entityTextureIndex = vIn.entityTextureIndex;
    return rd;
}

fragment half4 renderEntity_frag (
                                  RasterizerData rd [[stage_in]],
                                  half4 c [[color(0)]],
                                  texture2d<half, access::sample> entitiesTex [[ texture(2) ]],
                                  float2 pc [[point_coord]]
) {
    half4 resultColor = half4(0, 0, 0, 0);
    
    float2 uv = float2(rd.entityTextureIndex.x, rd.entityTextureIndex.y) * tile64_SingleSize + pc * tile64_SingleSize;
    
    constexpr sampler textureSampler (coord::pixel, address::clamp_to_edge, filter::nearest);
    half4 entityTexRead = entitiesTex.sample(textureSampler, uv);
    
    resultColor += entityTexRead;
    
    return resultColor * resultColor.a + c * (1.0 - resultColor.a);
}
