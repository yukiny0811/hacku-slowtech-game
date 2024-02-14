//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import SwiftUI

public struct GameView: View {
    
    let layer1Renderer = LayerRenderer()
    let layer2Renderer = LayerRenderer()
    let layer3Renderer = LayerRenderer()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            LayerView(renderer: layer1Renderer)
            LayerView(renderer: layer2Renderer)
            LayerView(renderer: layer3Renderer)
        }
    }
}
