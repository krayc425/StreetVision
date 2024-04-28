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

    func updateSearchResult(_ searchResult: SearchResult) {
        self.searchResult = searchResult
    }

}

struct SearchView: View {

    private let utils = GoogleMapsAPIUtils()
    @Binding var currentZoomLevel: ZoomLevel
    @State private var locationService = LocationUtils()
    @State private var position: MapCameraPosition = .automatic
    @State private var searchResults: [SearchResult] = []
    @State private var searchTerm: String = ""
    @ObservedObject private var searchResultStore = SearchResultStore.shared
    @ObservedObject private var textureResourceStore = TextureResourceStore.shared

    var body: some View {
        List {
            TextField("Search", text: $searchTerm)
                .autocorrectionDisabled()
                .onSubmit {
                    Task {
                        searchResults = (try? await locationService.search(with: searchTerm)) ?? []
                    }
                }
            let completions = locationService.completions
            if completions.isEmpty {
                ContentUnavailableView("Start a search", systemImage: "location.magnifyingglass")
            } else {
                ForEach(completions) { completion in
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        .navigationTitle("Street Vision")
        .onChange(of: searchTerm) {
            locationService.update(queryFragment: searchTerm)
        }
        .onChange(of: currentZoomLevel) {
            guard let searchResult = searchResultStore.searchResult else {
                return
            }
            fetchImageAndUpdateTextureResource(searchResult: searchResult)
        }
        .onChange(of: searchResultStore.searchResult) { oldValue, newValue in
            guard let newValue else {
                return
            }
            fetchImageAndUpdateTextureResource(searchResult: newValue)
        }
    }

    private func didTapOnCompletion(_ completion: SearchCompletions) {
        Task {
            if let singleLocation = try? await locationService.search(with: "\(completion.title) \(completion.subTitle)").first {
                searchResultStore.updateSearchResult(singleLocation)
            }
        }
    }

    private func fetchImageAndUpdateTextureResource(searchResult: SearchResult) {
        Task {
            guard let finalImageData = await utils.fetchPanoramaImageData(searchResult: searchResult, zoomLevel: currentZoomLevel) else {
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
