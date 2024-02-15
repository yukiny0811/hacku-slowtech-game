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
    
    var playerUniform: PlayerUniform = .init(
        position: .init(x: 512, y: 512),
        fovRadius: 10,
        normalizedMousePos: .zero,
        isMouseDown: 0,
        selectedTileType: 0
    )
    
    var entities: [GameEntity] = []
    var entitiesBuf: MTLBuffer!
    
    var enemyTarget = GameEntity(
        position: .init(x: 512, y: 512),
        collisionRadius: 3,
        entityTextureIndex: .one,
        speed: 0,
        entityType: 1
    )
    
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
    
    let updateEntity: MTLComputePipelineState = {
        let function = ShaderCore.library.makeFunction(name: "updateEntity")!
        let computeDesc = MTLComputePipelineDescriptor()
        computeDesc.computeFunction = function
        computeDesc.maxCallStackDepth = 1
        let state = try! ShaderCore.device.makeComputePipelineState(descriptor: computeDesc, options: [], reflection: nil)
        return state
    }()
    
    let renderEntity: MTLRenderPipelineState = {
        let vertFunc = ShaderCore.library.makeFunction(name: "renderEntity_vert")!
        let fragFunc = ShaderCore.library.makeFunction(name: "renderEntity_frag")!
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertFunc
        desc.fragmentFunction = fragFunc
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        desc.colorAttachments[0].isBlendingEnabled = true
        let vertDesc = createVertexDescriptor()
        desc.vertexDescriptor = vertDesc
        let state = try! ShaderCore.device.makeRenderPipelineState(descriptor: desc)
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
        
        for _ in 0...300000 {
            entities.append(
                GameEntity(
                    position: .random(in: 1...1000),
                    collisionRadius: Float.random(in: 0.3...1),
                    entityTextureIndex: .zero,
                    speed: Float.random(in: 0.1...0.5),
                    entityType: 2
                )
            )
        }
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
        
        if entitiesBuf == nil {
            entitiesBuf = ShaderCore.device.makeBuffer(bytes: entities, length: MemoryLayout<GameEntity>.stride * entities.count)!
        } else {
            entitiesBuf.contents().copyMemory(from: entities, byteCount: MemoryLayout<GameEntity>.stride * entities.count)
        }
        
        let dispatch = EMMetalDispatch()
        dispatch.render(renderTargetTexture: drawable.texture, needsClear: true) { _ in }
        dispatch.compute { [self] encoder in
            
            encoder.setTexture(tileTexture, index: 0)
            encoder.setTexture(drawable.texture, index: 1)
            encoder.setTexture(MetalAsset.tiles, index: 2)
            encoder.setBytes([playerUniform], length: MemoryLayout<PlayerUniform>.stride, index: 0)
            
            encoder.setComputePipelineState(updateLayer)
            var size = updateLayer.createDispatchSize(width: tileTexture.width, height: tileTexture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
            
            encoder.setComputePipelineState(renderLayer)
            size = renderLayer.createDispatchSize(width: drawable.texture.width, height: drawable.texture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
        }
        dispatch.compute { [self] encoder in
            encoder.setComputePipelineState(updateEntity)
            encoder.setBuffer(entitiesBuf, offset: 0, index: 0)
            encoder.setBytes([enemyTarget], length: MemoryLayout<GameEntity>.stride, index: 1)
            encoder.dispatchThreads(
                MTLSize(width: entities.count, height: 1, depth: 1),
                threadsPerThreadgroup: MTLSize(width: updateEntity.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            )
        }
        dispatch.render(renderTargetTexture: drawable.texture, needsClear: false) { [self] encoder in
            encoder.setRenderPipelineState(renderEntity)
            encoder.setVertexBuffer(entitiesBuf, offset: 0, index: 0)
            encoder.setVertexBytes([playerUniform], length: MemoryLayout<PlayerUniform>.stride, index: 1)
            encoder.setVertexTexture(drawable.texture, index: 1)
            encoder.setFragmentTexture(MetalAsset.entities, index: 2)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: entities.count)
        }
        dispatch.present(drawable: drawable)
        dispatch.commit()
        
        let entitiesPointer = entitiesBuf.contents().assumingMemoryBound(to: GameEntity.self)
        entities = Array(UnsafeBufferPointer(start: entitiesPointer, count: entities.count))
    }
    
    static func createVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float
        vertexDescriptor.attributes[1].offset = 8
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .int2
        vertexDescriptor.attributes[2].offset = 16
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<GameEntity>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        return vertexDescriptor
    }
}
