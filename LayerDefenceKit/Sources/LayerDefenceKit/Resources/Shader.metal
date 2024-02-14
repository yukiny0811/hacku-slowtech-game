
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
using namespace metal;

constant float PI = 3.14159265;

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
                        const device PlayerUniform& playerUniform [[ buffer(0) ]],
                        ushort2 gid [[ thread_position_in_grid ]] //gid in drawableTexture
) {
    float2 playerPosition = playerUniform.position;
    float playerFovRadius = playerUniform.fovRadius;
    float aspectRatio = float(drawableTexture.get_height()) / float(drawableTexture.get_width());
    float4 frame = float4(
                          playerPosition.x - playerFovRadius,
                          playerPosition.y - playerFovRadius * aspectRatio,
                          playerPosition.x + playerFovRadius,
                          playerPosition.y + playerFovRadius * aspectRatio
                          );
    
    float2 normalizedGidPosition = float2(
                                          float(gid.x) / float(drawableTexture.get_width()),
                                          float(gid.y) / float(drawableTexture.get_width())
                                          );
    ushort2 tileTextureGid = ushort2(
                                     ushort(frame.x + frame.z * normalizedGidPosition.x),
                                     ushort(frame.y + frame.w * normalizedGidPosition.y)
                                     );
    
    float4 tileTexRead = tileTexture.read(tileTextureGid);
    
    int tileType = int(tileTexRead.r);
    half4 finalColor = half4(0, 0, 0, 1);
    if (tileType == 0) {
        finalColor.r = 1;
    } else if (tileType == 1) {
        finalColor.g = 1;
    } else if (tileType == 2) {
        finalColor.b = 1;
    }
    
    drawableTexture.write(finalColor, gid);
}
