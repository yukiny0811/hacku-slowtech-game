//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import MetalKit
import SwiftUI
import AppKit

public struct LayerView: NSViewRepresentable {
    
    let renderer: LayerRenderer
    
    public init(renderer: LayerRenderer) {
        self.renderer = renderer
    }
    
    public func makeNSView(context: Context) -> MTKView {
        let mtkView = LayerMTKView(renderer: renderer)
        return mtkView
    }
    public func updateNSView(_ nsView: MTKView, context: Context) {}
}
