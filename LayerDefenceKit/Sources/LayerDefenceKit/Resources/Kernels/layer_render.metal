
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
#include "../Shared.metal"
#include "../Generated.metal"
#include "../EnemyMovement.metal"
using namespace metal;

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
    
    int2 tileIndex = getTileTextureIndex(tileType);
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
    
    if (tileType != 0) {
        float maxHPOfTile = getTileMaxHP(tileType);
        float tileHPRatio = tileTexRead.g / maxHPOfTile;
        sampled.rgb += 1.0 - tileHPRatio;
    }
    
    drawableTexture.write(sampled, gid);
}
