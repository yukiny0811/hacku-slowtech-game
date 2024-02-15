//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import MetalKit

enum MetalAsset {
    static let textureLoader = MTKTextureLoader(device: ShaderCore.device)
    static let tiles: MTLTexture = try! textureLoader.newTexture(
        name: "tiles",
        scaleFactor: 1,
        bundle: .module
    )
    static let entities: MTLTexture = try! textureLoader.newTexture(
        name: "entities",
        scaleFactor: 1,
        bundle: .module
    )
}
