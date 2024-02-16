
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
#include "Generated.metal"
#include "EnemyMovement.metal"
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

inline float2 nextEntityMovement(
                                 texture2d<float, access::read> routeTexture,
                                 texture2d<float, access::read> tileTexture,
                                 GameEntity entity
) {
    return false;
}

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

kernel void initLayer(
                      texture2d<float, access::write> tileTexture [[ texture(0) ]],
                      ushort2 gid [[ thread_position_in_grid ]]
) {
    int tileType = 0;
    tileTexture.write(float4(float(tileType), 0, 0, 0), gid);
}

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

kernel void updateEntity(
                         texture2d<float, access::read_write> tileTex [[ texture(0) ]],
                         texture2d<float, access::read> routeTex [[ texture(4) ]],
                         device GameEntity* entities [[ buffer(0) ]],
                         const device GameEntity& enemyTarget [[ buffer(1) ]],
                         uint index [[thread_position_in_grid]]
) {
    if (entities[index].isDead == 1) {
        return;
    }
    
    ushort2 tileGid = floatingTilePositionToGid(entities[index].position);
    
    if (enemyDoesFollowRoute(entities[index].entityType)) {
        int thisRouteDistValue = routeTex.read(tileGid).r;
        int threshold = enemyFollowRouteThreshold(entities[index].entityType);
        if (thisRouteDistValue > threshold) {
            float2 toEnemyDir = normalize(enemyTarget.position - entities[index].position);
            entities[index].position += toEnemyDir * enemySpeed(entities[index].entityType);
        } else {
            float2 nextDirection = float2(0, 0);
            int upRouteDistValue = routeTex.read(tileGid + ushort2(0, 1)).r;
            int downRouteDistValue = routeTex.read(tileGid + ushort2(0, -1)).r;
            int rightRouteDistValue = routeTex.read(tileGid + ushort2(1, 0)).r;
            int leftRouteDistValue = routeTex.read(tileGid + ushort2(-1, 0)).r;
            if (upRouteDistValue < thisRouteDistValue) {
                nextDirection += float2(0, 1);
            }
            if (downRouteDistValue < thisRouteDistValue) {
                nextDirection += float2(0, -1);
            }
            if (rightRouteDistValue < thisRouteDistValue) {
                nextDirection += float2(1, 0);
            }
            if (leftRouteDistValue < thisRouteDistValue) {
                nextDirection += float2(-1, 0);
            }
            if (length(nextDirection) == 0) {
                float2 toEnemyDir = normalize(enemyTarget.position - entities[index].position);
                entities[index].position += toEnemyDir * enemySpeed(entities[index].entityType);
            } else {
                entities[index].position += nextDirection * enemySpeed(entities[index].entityType);
            }
        }
    } else {
        float2 toEnemyDir = normalize(enemyTarget.position - entities[index].position);
        entities[index].position += toEnemyDir * enemySpeed(entities[index].entityType);
    }
    
    float4 tileRead = tileTex.read(tileGid);
    if (tileRead.g > 0) {
        float reductionHPValue = min(tileRead.g, entities[index].remainingHP);
        tileRead.g -= reductionHPValue;
        entities[index].remainingHP -= reductionHPValue;
        tileTex.write(tileRead, tileGid);
    }
    if (entities[index].remainingHP <= 0) {
        entities[index].isDead = 1;
    }
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
