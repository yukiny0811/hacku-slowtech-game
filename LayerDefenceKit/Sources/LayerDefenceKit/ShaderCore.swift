//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import MetalKit

enum ShaderCore {
    static let device: MTLDevice = MTLCreateSystemDefaultDevice()!
    static let library: MTLLibrary = try! ShaderCore.device.makeDefaultLibrary(bundle: Bundle.module)
    static let commandQueue: MTLCommandQueue = ShaderCore.device.makeCommandQueue()!
    static let context: CIContext = CIContext(mtlCommandQueue: commandQueue)
    static let textureLoader: MTKTextureLoader = MTKTextureLoader(device: ShaderCore.device)
    static let defaultTextureLoaderOptions: [MTKTextureLoader.Option: Any] = [
        .textureUsage: NSNumber(
            value: MTLTextureUsage.shaderRead.rawValue |
            MTLTextureUsage.shaderWrite.rawValue |
            MTLTextureUsage.renderTarget.rawValue
        )
    ]
}

