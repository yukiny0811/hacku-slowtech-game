
#include <metal_stdlib>
#include <simd/simd.h>
#include "../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"
using namespace metal;

// type
// 0 mainTarget(self)
// 1 tackler
// 2 bullet
// 3 shooter

inline int2 enemyTextureIndex(int type) {
    if (type == 0) {
        return int2(10, 10);
    } else if (type == 1) {
        return int2(0, 0);
    } else if (type == 2) {
        return int2(0, 0);
    } else if (type == 3) {
        return int2(0, 0);
    }
    return int2(10, 10);
}

inline bool enemyDoesFollowRoute(int type) {
    if (type == 0) {
        return false;
    } else if (type == 1) {
        return true;
    } else if (type == 2) {
        return false;
    } else if (type == 3) {
        return true;
    }
    return false;
}

inline int enemyFollowRouteThreshold(int type) {
    if (type == 0) {
        return 0;
    } else if (type == 1) {
        return 100;
    } else if (type == 2) {
        return 0;
    } else if (type == 3) {
        return 100;
    }
    return 0;
}

inline float enemySpeed(int type) {
    if (type == 0) {
        return 0;
    } else if (type == 1) {
        return 0.07;
    } else if (type == 2) {
        return 0.2;
    } else if (type == 3) {
        return 0.04;
    }
    return 0;
}

inline bool enemyIsTackler(int type) {
    if (type == 0) {
        return false;
    } else if (type == 1) {
        return true;
    } else if (type == 2) {
        return true;
    } else if (type == 3) {
        return false;
    }
    return false;
}

inline int enemyTargetTileDetectionRadius(int type) {
    if (type == 0) {
        return 0;
    } else if (type == 1) {
        return 0;
    } else if (type == 2) {
        return 0;
    } else if (type == 3) {
        return 5;
    }
    return false;
}

inline bool enemyHasLifetime(int type) {
    if (type == 0) {
        return false;
    } else if (type == 1) {
        return false;
    } else if (type == 2) {
        return true;
    } else if (type == 3) {
        return false;
    }
    return false;
}
