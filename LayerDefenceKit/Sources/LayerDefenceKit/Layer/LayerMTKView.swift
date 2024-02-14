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
        
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .activeAlways,
            .inVisibleRect
        ]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    @available(*, unavailable, message: "don't use this")
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getNormalizedMouseLocation(event: NSEvent) -> simd_float2 {
        let viewOriginInWindow = self.convert(NSPoint.zero, to: event.window!.contentView)
        let mouseLocationInWindow = event.locationInWindow
        
        var localMouseLocation = mouseLocationInWindow
        localMouseLocation.x -= viewOriginInWindow.x
        localMouseLocation.y -= window!.contentView!.frame.maxY - viewOriginInWindow.y
        
        let normalizedLocation = NSPoint(x: localMouseLocation.x / self.frame.maxX, y: localMouseLocation.y / self.frame.maxY)
        return simd_float2(Float(normalizedLocation.x), Float(normalizedLocation.y))
    }
    
    override public var acceptsFirstResponder: Bool { return true }
    public override func mouseDown(with event: NSEvent) {}
    public override func mouseMoved(with event: NSEvent) {
        renderer.playerUniform.normalizedMousePos = getNormalizedMouseLocation(event: event)
    }
    public override func mouseDragged(with event: NSEvent) {}
    public override func mouseUp(with event: NSEvent) {}
    public override func mouseEntered(with event: NSEvent) {}
    public override func mouseExited(with event: NSEvent) {}
    public override func keyDown(with event: NSEvent) {}
    public override func keyUp(with event: NSEvent) {}
    public override func viewWillStartLiveResize() {}
    public override func resize(withOldSuperviewSize oldSize: NSSize) {}
    public override func viewDidEndLiveResize() {}
    public override func scrollWheel(with event: NSEvent) {
        let scrolledX = Float(event.scrollingDeltaX)
        let scrolledY = Float(event.scrollingDeltaY)
        renderer.playerUniform.position += simd_float2(-scrolledX * 0.01, -scrolledY * 0.01)
    }
    public override func magnify(with event: NSEvent) {
        let scale = Float(event.magnification)
        renderer.playerUniform.fovRadius += -scale * 10
        if renderer.playerUniform.fovRadius < 5 {
            renderer.playerUniform.fovRadius = 5
        }
    }
}
