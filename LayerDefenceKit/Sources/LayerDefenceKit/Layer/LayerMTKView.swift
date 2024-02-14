//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import MetalKit

public class LayerMTKView: MTKView {
    
    var renderer: LayerRenderer
    
    init(renderer: LayerRenderer) {
        self.renderer = renderer
        super.init(frame: .zero, device: ShaderCore.device)
        self.frame = .zero
        self.delegate = renderer
        self.enableSetNeedsDisplay = false
        self.isPaused = false
        self.colorPixelFormat = .bgra8Unorm
        self.framebufferOnly = false
        self.preferredFramesPerSecond = 60
        self.autoResizeDrawable = true
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.depthStencilPixelFormat = .depth32Float_stencil8
        self.sampleCount = 1
        self.clearDepth = 1.0
        self.layer?.isOpaque = false
    }
    
    @available(*, unavailable, message: "don't use this")
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
