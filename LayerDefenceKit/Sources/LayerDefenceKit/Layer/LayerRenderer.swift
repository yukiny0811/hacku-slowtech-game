//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import MetalKit
import EasyMetalShader
import LayerDefenceKitCore

public class LayerRenderer: NSObject, MTKViewDelegate {
    
    var playerUniform: PlayerUniform = .init(position: .init(x: 100, y: 100), fovRadius: 10)
    
    let tileTexture = EMMetalTexture.create(
        width: 1024,
        height: 1024,
        pixelFormat: .rgba32Float,
        label: "tileTexture",
        isRenderTarget: true
    )
    
    let initLayer: MTLComputePipelineState = {
        let function = ShaderCore.library.makeFunction(name: "initLayer")!
        let computeDesc = MTLComputePipelineDescriptor()
        computeDesc.computeFunction = function
        computeDesc.maxCallStackDepth = 1
        let state = try! ShaderCore.device.makeComputePipelineState(descriptor: computeDesc, options: [], reflection: nil)
        return state
    }()
    
    let updateLayer: MTLComputePipelineState = {
        let function = ShaderCore.library.makeFunction(name: "updateLayer")!
        let computeDesc = MTLComputePipelineDescriptor()
        computeDesc.computeFunction = function
        computeDesc.maxCallStackDepth = 1
        let state = try! ShaderCore.device.makeComputePipelineState(descriptor: computeDesc, options: [], reflection: nil)
        return state
    }()
    
    let renderLayer: MTLComputePipelineState = {
        let function = ShaderCore.library.makeFunction(name: "renderLayer")!
        let computeDesc = MTLComputePipelineDescriptor()
        computeDesc.computeFunction = function
        computeDesc.maxCallStackDepth = 1
        let state = try! ShaderCore.device.makeComputePipelineState(descriptor: computeDesc, options: [], reflection: nil)
        return state
    }()
    
    public override init() {
        super.init()
        
        let dispatch = EMMetalDispatch()
        dispatch.compute { [self] encoder in
            encoder.setComputePipelineState(initLayer)
            encoder.setTexture(tileTexture, index: 0)
            let size = initLayer.createDispatchSize(width: tileTexture.width, height: tileTexture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
        }
        dispatch.commit()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    public func draw(in view: MTKView) {
        
        view.drawableSize = CGSize(
            width: view.frame.size.width,
            height: view.frame.size.height
        )
        guard let drawable = view.currentDrawable else {
            return
        }
        
        let dispatch = EMMetalDispatch()
        dispatch.render(renderTargetTexture: drawable.texture, needsClear: true) { _ in }
        dispatch.compute { [self] encoder in
            encoder.setComputePipelineState(updateLayer)
            encoder.setTexture(tileTexture, index: 0)
            var size = updateLayer.createDispatchSize(width: tileTexture.width, height: tileTexture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
            
            encoder.setComputePipelineState(renderLayer)
            encoder.setTexture(tileTexture, index: 0)
            encoder.setTexture(drawable.texture, index: 1)
            encoder.setTexture(MetalAsset.tiles, index: 2)
            encoder.setBytes([playerUniform], length: MemoryLayout<PlayerUniform>.stride, index: 0)
            size = renderLayer.createDispatchSize(width: drawable.texture.width, height: drawable.texture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
        }
        dispatch.present(drawable: drawable)
        dispatch.commit()
    }
}
