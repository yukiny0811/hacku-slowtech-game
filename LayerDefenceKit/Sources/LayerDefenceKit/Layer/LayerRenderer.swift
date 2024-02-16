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
        remainingHP: 10000,
        isDead: 0,
        entityType: 0
    )
    
    let tileTexture = EMMetalTexture.create(
        width: 1024,
        height: 1024,
        pixelFormat: .rgba32Float,
        label: "tileTexture",
        isRenderTarget: true
    )
    
    let routeTexture = EMMetalTexture.create(
        width: 1024,
        height: 1024,
        pixelFormat: .rgba32Float,
        label: "routeTexture",
        isRenderTarget: false
    )
    
    let initRouteLayer: MTLComputePipelineState = {
        let function = ShaderCore.library.makeFunction(name: "initRouteLayer")!
        let computeDesc = MTLComputePipelineDescriptor()
        computeDesc.computeFunction = function
        computeDesc.maxCallStackDepth = 1
        let state = try! ShaderCore.device.makeComputePipelineState(descriptor: computeDesc, options: [], reflection: nil)
        return state
    }()
    
    let updateRouteLayer: MTLComputePipelineState = {
        let function = ShaderCore.library.makeFunction(name: "updateRouteLayer")!
        let computeDesc = MTLComputePipelineDescriptor()
        computeDesc.computeFunction = function
        computeDesc.maxCallStackDepth = 1
        let state = try! ShaderCore.device.makeComputePipelineState(descriptor: computeDesc, options: [], reflection: nil)
        return state
    }()
    
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
        dispatch.compute { [self] encoder in
            encoder.setComputePipelineState(initRouteLayer)
            encoder.setTexture(routeTexture, index: 4)
            encoder.setBytes([enemyTarget], length: MemoryLayout<GameEntity>.stride, index: 1)
            let size = initLayer.createDispatchSize(width: routeTexture.width, height: routeTexture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
        }
        dispatch.commit()
        
        for _ in 0...300000 {
            entities.append(
                GameEntity(
                    position: .random(in: 1...1000),
                    collisionRadius: Float.random(in: 0.3...1),
                    remainingHP: Float.random(in: 0.5...1),
                    isDead: 0,
                    entityType: 1
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
            encoder.setTexture(routeTexture, index: 4)
            encoder.setBytes([playerUniform], length: MemoryLayout<PlayerUniform>.stride, index: 0)
            
            encoder.setComputePipelineState(updateLayer)
            var size = updateLayer.createDispatchSize(width: tileTexture.width, height: tileTexture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
            
            encoder.setComputePipelineState(renderLayer)
            size = renderLayer.createDispatchSize(width: drawable.texture.width, height: drawable.texture.height)
            encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
        }
        dispatch.compute { [self] encoder in
            encoder.setTexture(routeTexture, index: 4)
            encoder.setTexture(tileTexture, index: 1)
            encoder.setBytes([enemyTarget], length: MemoryLayout<GameEntity>.stride, index: 1)
            encoder.setComputePipelineState(updateRouteLayer)
            let size = renderLayer.createDispatchSize(width: routeTexture.width, height: routeTexture.height)
            for _ in 0...10 {
                encoder.dispatchThreadgroups(size.threadGroupCount, threadsPerThreadgroup: size.threadsPerThreadGroup)
            }
        }
        dispatch.compute { [self] encoder in
            encoder.setComputePipelineState(updateEntity)
            encoder.setTexture(tileTexture, index: 0)
            encoder.setTexture(routeTexture, index: 4)
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
        vertexDescriptor.attributes[2].format = .float
        vertexDescriptor.attributes[2].offset = 12
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[3].format = .int
        vertexDescriptor.attributes[3].offset = 16
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[4].format = .int
        vertexDescriptor.attributes[4].offset = 20
        vertexDescriptor.attributes[4].bufferIndex = 0
        
        print(MemoryLayout<GameEntity>.stride)
        vertexDescriptor.layouts[0].stride = MemoryLayout<GameEntity>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        return vertexDescriptor
    }
}
