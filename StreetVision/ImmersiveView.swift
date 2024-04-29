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
                    let angle = Angle.degrees(textureResourceModel.heading)
                    let rotation = simd_quatf(angle: Float(angle.radians), axis: SIMD3<Float>(0, 1, 0))
                    rootEntity.transform.rotation = rotation
                    content.add(rootEntity)
//                    for link in textureResourceModel.links {
//                        let box = ModelEntity(mesh: .generateBox(size: 0.5), materials: [UnlitMaterial(color: .red)])
//                        box.position.x = 0.25 * Float(counter)
//                        let angle = Angle.degrees(link.heading)
//                        box.transform.translation += SIMD3<Float>(5.0 * sin(Float(angle.radians)), 0.0,-5.0 * cos(Float(angle.radians)))
//                        = SIMD3<Float>(x: 5.0, y: 0.0, z: 0.0)
//                        box.orientation = simd_quatf(angle: radians, axis: SIMD3(x: 0, y: 1, z: 0))
//                        box.name = "box_\(counter)"
//                        box.name = "arrow"
//                        box.components.set(HoverEffectComponent())
//                        rootEntity.addChild(box)
//                        let linkEntity = Entity()
//                        linkEntity.scale = SIMD3<Float>(x: 1, y: 1, z: 1)
//                        linkEntity.components.set(ModelComponent(mesh: .generateBox(size: 5.0), materials: [UnlitMaterial(color: .red)]))
//                        rootEntity.addChild(linkEntity)
//                    }
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
