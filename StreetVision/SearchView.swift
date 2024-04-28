//
//  ContentView.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import MapKit
import SwiftUI
import RealityKit

@MainActor
class SearchResultStore: NSObject, ObservableObject {

    static let shared = SearchResultStore()

    private override init() {

    }

    @Published private(set) var searchResult: SearchResult?

    func updateSearchResult(_ searchResult: SearchResult?) {
        self.searchResult = searchResult
    }

}

struct SearchView: View {

    @Binding var currentZoomLevel: ZoomLevel
    @State private var locationUtils = LocationUtils.shared
    @State private var position: MapCameraPosition = .automatic
    @State private var searchResults: [SearchResult] = []
    @State private var searchTerm: String = ""
    @ObservedObject private var searchResultStore = SearchResultStore.shared
    @ObservedObject private var textureResourceStore = TextureResourceStore.shared

    var body: some View {
        Form {
            Section {
                TextField("Search", text: $searchTerm)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task {
                            searchResults = (try? await locationUtils.search(with: searchTerm)) ?? []
                        }
                    }
            }
            let completions = locationUtils.completions
            if completions.isEmpty {
                ContentUnavailableView("Start a search", systemImage: "location.magnifyingglass")
            } else {
                List {
                    ForEach(completions) { completion in
                        Button {
                            didTapOnCompletion(completion)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completion.title)
                                    .font(.headline)
                                Text(completion.subTitle)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Street Vision")
        .onChange(of: searchTerm) {
            locationUtils.update(queryFragment: searchTerm)
        }
        .onChange(of: currentZoomLevel) {
            guard let searchResult = searchResultStore.searchResult else {
                return
            }
            textureResourceStore.updateTextureResource(nil)
            fetchImageAndUpdateTextureResource(searchResult: searchResult)
        }
        .onChange(of: searchResultStore.searchResult) { oldValue, newValue in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            textureResourceStore.updateTextureResource(nil)
            if let newValue {
                fetchImageAndUpdateTextureResource(searchResult: newValue)
            }
        }
    }

    private func didTapOnCompletion(_ completion: SearchCompletions) {
        Task {
            if let singleLocation = try? await locationUtils.search(with: "\(completion.title) \(completion.subTitle)").first {
                searchResultStore.updateSearchResult(singleLocation)
            }
        }
    }

    private func fetchImageAndUpdateTextureResource(searchResult: SearchResult) {
        Task {
            guard let finalImageData = await GoogleMapsAPIUtils.fetchPanoramaImageData(searchResult: searchResult, zoomLevel: currentZoomLevel) else {
                textureResourceStore.updateTextureResource(nil)
                return
            }
            do {
                let fileURL = FileUtils.cacheDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension(for: .jpeg)
                debugPrint("Writing image to URL \(fileURL)")
                try finalImageData.write(to: fileURL)
                textureResourceStore.updateTextureResource(try await TextureResource(contentsOf: fileURL))
            } catch let error {
                debugPrint("Write image error \(error.localizedDescription)")
                textureResourceStore.updateTextureResource(nil)
            }
        }
    }

}
