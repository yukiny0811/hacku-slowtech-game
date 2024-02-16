
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
#include "../Shared.metal"
#include "../Generated.metal"
#include "../EnemyMovement.metal"
using namespace metal;

kernel void updateEntity(
                         texture2d<float, access::read_write> tileTex [[ texture(0) ]],
                         texture2d<float, access::read> routeTex [[ texture(4) ]],
                         device GameEntity* entities [[ buffer(0) ]],
                         const device float4& randomFactor [[ buffer(10) ]],
                         const device GameEntity& enemyTarget [[ buffer(1) ]],
                         uint index [[thread_position_in_grid]]
) {
    if (entities[index].isDead == 1) {
        return;
    }
    if (enemyHasLifetime(entities[index].entityType)) {
        entities[index].remainingLifetime -= 1;
        if (entities[index].remainingLifetime <= 0) {
            entities[index].isDead = 1;
            return;
        }
    }
    
    ushort2 tileGid = floatingTilePositionToGid(entities[index].position);
    
    if (enemyDoesFollowRoute(entities[index].entityType)) {
        int thisRouteDistValue = routeTex.read(tileGid).r;
        int threshold = enemyFollowRouteThreshold(entities[index].entityType);
        if (thisRouteDistValue > threshold) {
            float2 toEnemyDir = normalize(enemyTarget.position - entities[index].position);
            entities[index].position += toEnemyDir * enemySpeed(entities[index].entityType);
        } else {
            
            if (enemyIsTackler(entities[index].entityType)) {
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
            } else {
                int searchRadius = enemyTargetTileDetectionRadius(entities[index].entityType);
                float2 attackTargetDir = float2(0, 0);
                for (int x = int(tileGid.x) - searchRadius; x < int(tileGid.x) + searchRadius; x++) {
                    for (int y = int(tileGid.y) - searchRadius; y < int(tileGid.y) + searchRadius; y++) {
                        float4 tempRead = tileTex.read(ushort2(x, y));
                        bool isTarget = isAttackTarget(int(tempRead.r));
                        if (isTarget) {
                            attackTargetDir = float2(float(x), float(y)) - entities[index].position;
                            break;
                        }
                    }
                }
                if (length(attackTargetDir) == 0) {
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
                } else {
                    attackTargetDir += float2(0.5, 0.5);
                    for (int i = 0; i < 100; i++) {
                        float random = rand(i * 1234 * randomFactor.x, tileGid.x * 125 * randomFactor.y, tileGid.y * 235 * randomFactor.z);
                        int randomIndex = int(random * 300000);
                        if (entities[randomIndex].isDead == 1) {
                            entities[randomIndex].position = entities[index].position;
                            entities[randomIndex].collisionRadius = 0.1;
                            entities[randomIndex].remainingHP = 1;
                            entities[randomIndex].isDead = 0;
                            entities[randomIndex].entityType = 2;
                            entities[randomIndex].direction = normalize(attackTargetDir) + (rand(i * 412 * randomFactor.y, randomFactor.z * 37, randomFactor.w * 27) - 0.5) * 0.3;
                            entities[randomIndex].remainingLifetime = 500;
                            break;
                        }
                    }
                }
            }
        }
    } else {
        entities[index].position += entities[index].direction * enemySpeed(entities[index].entityType);
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
