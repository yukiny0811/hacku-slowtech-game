
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
using namespace metal;

inline int2 enemyTextureIndex(int type) {
    if (type == 0) {
        return int2(10, 10);
    } else if (type == 1) {
        return int2(0, 0);
    }
    return int2(10, 10);
}

inline bool enemyDoesFollowRoute(int type) {
    if (type == 0) {
        return false;
    } else if (type == 1) {
        return true;
    }
    return false;
}

inline int enemyFollowRouteThreshold(int type) {
    if (type == 0) {
        return 0;
    } else if (type == 1) {
        return 100;
    }
    return 0;
}

inline float enemySpeed(int type) {
    if (type == 0) {
        return 0;
    } else if (type == 1) {
        return 0.07;
    }
    return 0;
}
