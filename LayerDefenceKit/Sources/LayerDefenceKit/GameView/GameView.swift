//
//  File.swift
//  
//
//  Created by Yuki Kuwashima on 2024/02/15.
//

import SwiftUI

public struct GameView: View {
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Text("タイトル")
                .font(.largeTitle)
            NavigationLink("新規ゲーム") {
                GamePlayView()
            }
            NavigationLink("ロード") {
                
            }
        }
    }
}

struct GamePlayView: View {
    
    let layer1Renderer = LayerRenderer()
    
    var body: some View {
        ZStack {
            LayerView(renderer: layer1Renderer)
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            ScrollView(.horizontal) {
                LazyHStack {
                    Button("tile0") {
                        layer1Renderer.playerUniform.selectedTileType = 0
                    }
                    Button("tile1") {
                        layer1Renderer.playerUniform.selectedTileType = 1
                    }
                    Button("tile2") {
                        layer1Renderer.playerUniform.selectedTileType = 2
                    }
                }
            }
            .frame(height: 50)
            .fixedSize()
        }
    }
}
