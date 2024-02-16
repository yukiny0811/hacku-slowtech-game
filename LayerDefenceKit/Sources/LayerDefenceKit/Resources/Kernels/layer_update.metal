
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
#include "../Shared.metal"
#include "../Generated.metal"
#include "../EnemyMovement.metal"
using namespace metal;

kernel void updateLayer(
                        texture2d<float, access::read_write> tileTexture [[ texture(0) ]],
                        texture2d<float, access::read_write> routeTexture [[ texture(4) ]],
                        texture2d<half, access::read> drawableTexture [[ texture(1) ]],
                        const device PlayerUniform& playerUniform [[ buffer(0) ]],
                        ushort2 gid [[ thread_position_in_grid ]]
) {
    float4 tileRead = tileTexture.read(gid);
    if (tileRead.g <= 0 && tileRead.r != 0) {
        tileTexture.write(float4(0, 0, 0, 0), gid);
        routeTexture.write(float4(99999, 1, 0, 0), gid);
    }
    
    if (playerUniform.isMouseDown == 1) {
        int selectedTileType = playerUniform.selectedTileType;
        ushort2 writeGid = getTilePosFromViewPosition(playerUniform, drawableTexture.get_width(), drawableTexture.get_height());
        if (gid.x == writeGid.x && gid.y == writeGid.y) {
            tileTexture.write(float4(float(selectedTileType), getTileMaxHP(selectedTileType), 0, 0), gid);
            bool isWall = isTileWall(selectedTileType);
            routeTexture.write(float4(99999, 0, isWall ? 1 : 0, 0), gid);
        }
    }
}
