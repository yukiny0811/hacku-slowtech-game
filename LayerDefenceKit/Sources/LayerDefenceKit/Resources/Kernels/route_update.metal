
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
#include "../Shared.metal"
#include "../Generated.metal"
#include "../EnemyMovement.metal"
using namespace metal;

kernel void updateRouteLayer(
                             texture2d<float, access::read_write> routeTexture [[ texture(4) ]],
                             texture2d<float, access::read> tileTexture [[ texture(1) ]],
                             const device GameEntity& enemyTarget [[ buffer(1) ]],
                             ushort2 gid [[ thread_position_in_grid ]]
) {
    
    if (gid.x == 0 || gid.x == routeTexture.get_width() - 1 || gid.y == 0 || gid.y == routeTexture.get_height() - 1) {
        return;
    }
    
    if (int(gid.x) == int(enemyTarget.position.x) && int(gid.y) == int(enemyTarget.position.y)) {
        routeTexture.write(float4(0, 0, 0, 0), gid);
        return;
    }
    
    int4 routeRead = int4(routeTexture.read(gid));
    
    int4 routeReadUp = int4(routeTexture.read(gid + ushort2(0, 1)));
    int4 routeReadDown = int4(routeTexture.read(gid + ushort2(0, -1)));
    int4 routeReadRight = int4(routeTexture.read(gid + ushort2(1, 0)));
    int4 routeReadLeft = int4(routeTexture.read(gid + ushort2(-1, 0)));
    
    if (routeRead.g == 0) {
        bool needsUpdate = true;
        if (routeRead.r - 1 == routeReadUp.r && routeReadUp.b == 0) {
            needsUpdate = false;
        }
        if (routeRead.r - 1 == routeReadDown.r && routeReadDown.b == 0) {
            needsUpdate = false;
        }
        if (routeRead.r - 1 == routeReadRight.r && routeReadRight.b == 0) {
            needsUpdate = false;
        }
        if (routeRead.r - 1 == routeReadLeft.r && routeReadLeft.b == 0) {
            needsUpdate = false;
        }
        if (needsUpdate) {
            routeRead.g = 1;
        }
    }
    if (routeRead.g == 1) { //変更が必要なときに1になる
        if (routeRead.b == 1) {
            return;
        }
        if (routeReadUp.g == 1 && routeReadDown.g == 1 && routeReadRight.g == 1 && routeReadLeft.g == 1) {
            return;
        }
        int shortestDist = 99999;
        bool updated = false;
        if (routeReadUp.g == 0 && routeReadUp.b == 0) {
            shortestDist = min(shortestDist, routeReadUp.r + 1);
            updated = true;
        }
        if (routeReadDown.g == 0 && routeReadDown.b == 0) {
            shortestDist = min(shortestDist, routeReadDown.r + 1);
            updated = true;
        }
        if (routeReadRight.g == 0 && routeReadRight.b == 0) {
            shortestDist = min(shortestDist, routeReadRight.r + 1);
            updated = true;
        }
        if (routeReadLeft.g == 0 && routeReadLeft.b == 0) {
            shortestDist = min(shortestDist, routeReadLeft.r + 1);
            updated = true;
        }
        if (updated) {
            routeRead.r = shortestDist;
            routeRead.g = 0;
        }
    }
    routeTexture.write(float4(routeRead), gid);
}
