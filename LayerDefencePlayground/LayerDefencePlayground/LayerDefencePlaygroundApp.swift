//
//  LayerDefencePlaygroundApp.swift
//  LayerDefencePlayground
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import SwiftUI
@testable import LayerDefenceKit

@main
struct LayerDefencePlaygroundApp: App {
    var body: some Scene {
        WindowGroup {
            TestView()
        }
    }
}

struct TestView: View {
    let layer1Renderer = LayerRenderer()
    
    init() {}
    
    var body: some View {
        ZStack {
            LayerView(renderer: layer1Renderer)
        }
    }
}
