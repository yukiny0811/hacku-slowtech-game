//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import SwiftUI

public struct GameView: View {
    
    let layer1Renderer = LayerRenderer()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            LayerView(renderer: layer1Renderer)
        }
    }
}
