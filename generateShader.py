import json

with open ("game.json") as f:
	d = json.load(f)
 
iterationCount = 0

# generate tile

iterationCount = 0
tileString = "inline float getTileMaxHP(int type) { if (false) {}"
for tile in d["tiles"]:
    tileString += "else if (type == " + str(iterationCount) + ") { return " + str(tile["maxHP"]) + "; }"
    iterationCount += 1
tileString += "return 0.0;}"

iterationCount = 0
tileIndexString = "inline int2 getTileTextureIndex(int type) { if (false) {}"
for tile in d["tiles"]:
    tileIndexString += "else if (type == " + str(iterationCount) + ") { return int2(" + str(tile["tileImageIndexX"]) + "," + str(tile["tileImageIndexY"]) + ");}"
    iterationCount += 1
tileIndexString += "return int2(0, 0);}"

iterationCount = 0
isWallString = "inline bool isTileWall(int type) { if (false) {}"
for tile in d["tiles"]:
    isWallString += "else if (type == " + str(iterationCount) + ") { return "
    if tile["isWall"] == 0:
        isWallString += "false"
    else:
        isWallString += "true"
    isWallString += ";}"
    iterationCount += 1
isWallString += "return false;}"

# write to metal file

finalString = ""
finalString += "#include <metal_stdlib>\n"
finalString += "#include <simd/simd.h>\n"
finalString += '#include "../../LayerDefenceKitCore/include/LayerDefenceKitCore.h"\n'
finalString += "using namespace metal;\n"
finalString += tileString
finalString += tileIndexString
finalString += isWallString
with open("LayerDefenceKit/Sources/LayerDefenceKit/Resources/Generated.metal", "w") as f:
    f.write(finalString)
