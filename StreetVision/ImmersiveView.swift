//
//  ImmersiveView.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import RealityKit
import SwiftUI

struct TextureResourceModel: Equatable {

    let textureResource: TextureResource
    let heading: Double
    let links: [GMapsMetadataResponse.Links]

    static func == (_ lhs: TextureResourceModel, _ rhs: TextureResourceModel) -> Bool {
        return lhs.textureResource == rhs.textureResource && lhs.heading == rhs.heading
    }

}

@MainActor
class TextureResourceStore: NSObject, ObservableObject {

    static let shared = TextureResourceStore()

    private override init() {

    }

    @Published private(set) var textureResource: TextureResourceModel?

    func updateTextureResource(_ textureResource: TextureResourceModel?) {
        self.textureResource = textureResource
    }
}

struct ImmersiveView: View {

    @State private var textureResourceModel: TextureResourceModel? = TextureResourceStore.shared.textureResource
    @ObservedObject private var searchResultStore = SearchResultStore.shared
    @ObservedObject private var textureResourceStore = TextureResourceStore.shared

    var body: some View {
        Group {
            if let textureResourceModel {
                RealityView { content in
                    let rootEntity = Entity()
                    var material = UnlitMaterial()
                    material.color = UnlitMaterial.BaseColor(texture: MaterialParameters.Texture(textureResourceModel.textureResource))
                    rootEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 1E3), materials: [material]))
                    rootEntity.scale = SIMD3<Float>(x: 1, y: 1, z: -1)
                    rootEntity.orientation = simd_quatf(angle: -Float.pi / 2.0, axis: SIMD3<Float>(0, 1, 0))
                    content.add(rootEntity)
                    for link in textureResourceModel.links {
                        let box = ModelEntity(mesh: .generateBox(size: 0.5), materials: [UnlitMaterial(color: .red)])
                        let angle = Angle.degrees(link.heading)
                        box.position.x = 5.0 * sin(Float(angle.radians) - Float.pi / 2.0)
                        box.position.z = 5.0 * cos(Float(angle.radians) - Float.pi / 2.0)
                        box.components.set(InputTargetComponent())
                        box.orientation = simd_quatf(angle: Float(angle.radians) - Float.pi / 2.0, axis: SIMD3<Float>(0, 1, 0))
                        rootEntity.addChild(box, preservingWorldTransform: true)
                    }
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: searchResultStore.searchResult, initial: true) { oldValue, newValue in
            self.textureResourceModel = nil
        }
        .onChange(of: textureResourceStore.textureResource, initial: true) { oldValue, newValue in
            self.textureResourceModel = newValue
        }
    }

}
