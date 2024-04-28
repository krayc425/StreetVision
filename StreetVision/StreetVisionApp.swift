//
//  StreetVisionApp.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import SwiftUI

@main
struct StreetVisionApp: App {

    @State private var showImmersiveSpace = false
    @State private var currentZoomLevel: ZoomLevel = .four
    @State private var cacheSizeString: String = FileUtils.cacheSizeString()
    @ObservedObject private var textureResourceStore = TextureResourceStore.shared
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SearchView(currentZoomLevel: $currentZoomLevel)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                Section {
                                    ForEach(ZoomLevel.allCases) { zoomLevel in
                                        Button {
                                            currentZoomLevel = zoomLevel
                                        } label: {
                                            HStack {
                                                Text(zoomLevel.displayName)
                                                Spacer()
                                                if zoomLevel == currentZoomLevel {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } header: {
                                    Text("Zoom Level")
                                }
                                Section {
                                    Button {
                                        Task {
                                            FileUtils.clearCache()
                                        }
                                    } label: {
                                        Text("Clear cache (\(cacheSizeString))")
                                    }
                                } header: {
                                    Text("Others")
                                }
                            } label: {
                                Image(systemName: "gear")
                            }
                            .onTapGesture {
                                cacheSizeString = FileUtils.cacheSizeString()
                            }
                        }
                    }
            } detail: {
                MapView(showingImmersiveSpace: $showImmersiveSpace)
            }
            .onAppear {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return
                }
                let geometryRequest = UIWindowScene.GeometryPreferences.Vision(resizingRestrictions: .uniform)
                windowScene.requestGeometryUpdate(geometryRequest)
            }
            .onChange(of: textureResourceStore.textureResource, initial: true) { oldValue, newValue in
                if newValue != nil {
                    showImmersiveSpace = true
                }
            }
            .onChange(of: showImmersiveSpace, initial: true) { oldValue, newValue in
                Task {
                    if newValue {
                        if !oldValue {
                            await openImmersiveSpace(id: "ImmersiveSpace")
                        }
                    } else {
                        if oldValue {
                            await dismissImmersiveSpace()
                        }
                    }
                }
            }
            .onDisappear {
                showImmersiveSpace = false
            }
        }
        .defaultSize(width: 1, height: 0.75, depth: 0.0, in: .meters)
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }

}
