
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
#include "../Shared.metal"
#include "../Generated.metal"
#include "../EnemyMovement.metal"
using namespace metal;

kernel void initRouteLayer(
                           texture2d<float, access::write> routeTexture [[ texture(4) ]],
                           const device GameEntity& enemyTarget [[ buffer(1) ]],
                           ushort2 gid [[ thread_position_in_grid ]]
) {
    if (int(gid.x) == int(enemyTarget.position.x) && int(gid.y) == int(enemyTarget.position.y)) {
        routeTexture.write(float4(0, 0, 0, 0), gid);
    } else {
        routeTexture.write(float4(99999, 1, 0, 0), gid);
    }
}
