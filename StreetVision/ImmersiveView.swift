//
//  ImmersiveView.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import RealityKit
import SwiftUI

@MainActor
class TextureResourceStore: NSObject, ObservableObject {

    static let shared = TextureResourceStore()

    private override init() {

    }

    @Published private(set) var textureResource: TextureResource?

    func updateTextureResource(_ textureResource: TextureResource?) {
        self.textureResource = textureResource
    }
}

struct ImmersiveView: View {

    @State private var textureResource: TextureResource? = TextureResourceStore.shared.textureResource
    @ObservedObject private var searchResultStore = SearchResultStore.shared
    @ObservedObject private var textureResourceStore = TextureResourceStore.shared

    var body: some View {
        Group {
            if let textureResource {
                RealityView { content in
                    let rootEntity = Entity()
                    var material = UnlitMaterial()
                    material.color = UnlitMaterial.BaseColor(texture: MaterialParameters.Texture(textureResource))
                    rootEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))
                    rootEntity.scale = SIMD3<Float>(x: 1, y: 1, z: -1)
                    content.add(rootEntity)
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: searchResultStore.searchResult, initial: true) { oldValue, newValue in
            self.textureResource = nil
        }
        .onChange(of: textureResourceStore.textureResource, initial: true) { oldValue, newValue in
            self.textureResource = newValue
        }
    }

}
