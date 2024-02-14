//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import MetalKit
import EasyMetalShader

public class LayerRenderer: NSObject, MTKViewDelegate {
    
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
        dispatch.commit()
    }
}
