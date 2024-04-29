//
//  MapView.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import MapKit
import SwiftUI

enum TilesLoadingStatus: Equatable {

    case success
    case loading
    case failed
    case none

}

struct MapView: View {

    @Binding var showingImmersiveSpace: Bool
    @Binding var tilesLoadingStatus: TilesLoadingStatus
    @State private var cameraPosition: MapCameraPosition = .automatic
    @ObservedObject private var searchResultStore = SearchResultStore.shared

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let searchResult = searchResultStore.searchResult {
                    Marker(searchResult.title, coordinate: searchResult.location)
                }
            }
            .onTapGesture { screenCoordinate in
                let selectedLocation = proxy.convert(screenCoordinate, from: .local)
                if let selectedLocation {
                    debugPrint("Selected \(selectedLocation.latitude), \(selectedLocation.longitude)")
                    searchResultStore.updateSearchResult(SearchResult(
                        title: "\(selectedLocation.latitude), \(selectedLocation.longitude)",
                        location: selectedLocation))
                }
            }
        }
        .overlay(alignment: .bottom) {
            Group {
                switch tilesLoadingStatus {
                    case .success:
                        Button {
                            showingImmersiveSpace.toggle()
                        } label: {
                            HStack {
                                Image(systemName: showingImmersiveSpace ? "visionpro.slash" : "visionpro")
                                Text(showingImmersiveSpace ? "Close Immersive Space" : "Open Immersive Space")
                            }
                        }
                    case .loading:
                        ProgressView()
                            .padding()
                            .background(.background)
                            .clipShape(Circle())
                    case .none:
                        EmptyView()
                    case .failed:
                        Text("No street view available")
                            .font(.headline)
                            .padding()
                            .background(.background)
                            .clipShape(Capsule())
                }
            }
            .padding()
        }
        .onChange(of: searchResultStore.searchResult) { oldValue, newValue in
            if let newValue {
                cameraPosition = .region(MKCoordinateRegion(center: newValue.location, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
            } else {
                cameraPosition = .automatic
            }
        }
    }

}
