//
//  MapView.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import MapKit
import SwiftUI

struct MapView: View {

    @Binding var showingImmersiveSpace: Bool
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
        .overlay(alignment: .bottomTrailing) {
            Button {
                searchResultStore.updateSearchResult(nil)
            } label: {
                Text("Reset")
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if searchResultStore.searchResult != nil {
                Button {
                    showingImmersiveSpace.toggle()
                } label: {
                    HStack {
                        Image(systemName: showingImmersiveSpace ? "visionpro.slash" : "visionpro")
                        Text(showingImmersiveSpace ? "Close Immersive Space" : "Open Immersive Space")
                    }
                }
                .padding()
            }
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
