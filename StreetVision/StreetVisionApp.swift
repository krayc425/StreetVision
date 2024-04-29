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
    @State private var tilesLoadingStatus: TilesLoadingStatus = .none
    @State private var currentZoomLevel: ZoomLevel = .three
    @State private var cacheSizeString: String = FileUtils.cacheSizeString()
    @ObservedObject private var textureResourceStore = TextureResourceStore.shared
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SearchView(currentZoomLevel: $currentZoomLevel, tilesLoadingStatus: $tilesLoadingStatus)
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
                MapView(showingImmersiveSpace: $showImmersiveSpace, tilesLoadingStatus: $tilesLoadingStatus)
            }
            .onAppear {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    return
                }
                let geometryRequest = UIWindowScene.GeometryPreferences.Vision(resizingRestrictions: .uniform)
                windowScene.requestGeometryUpdate(geometryRequest)
            }
            .onChange(of: textureResourceStore.textureResource, initial: true) { oldValue, newValue in
                showImmersiveSpace = newValue != nil
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
