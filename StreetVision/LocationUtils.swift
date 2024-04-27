//
//  LocationService.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import MapKit
import SwiftUI

struct SearchCompletions: Identifiable {

    let id = UUID()
    let title: String
    let subTitle: String

}

struct SearchResult: Identifiable, Hashable, Equatable {

    let id = UUID()
    let title: String
    let location: CLLocationCoordinate2D

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id && lhs.location.latitude == rhs.location.latitude && lhs.location.longitude == rhs.location.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(location.latitude)
        hasher.combine(location.longitude)
    }

}

class LocationUtils: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {

    private let completer: MKLocalSearchCompleter
    @Published var completions = [SearchCompletions]()

    override init() {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        self.completer = completer
        super.init()
        completer.delegate = self
    }

    func update(queryFragment: String) {
        completer.queryFragment = queryFragment
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map {
            SearchCompletions(title: $0.title, subTitle: $0.subtitle)
        }
    }

    func search(with query: String, coordinate: CLLocationCoordinate2D? = nil) async throws -> [SearchResult] {
        let mapKitRequest = MKLocalSearch.Request()
        mapKitRequest.naturalLanguageQuery = query
        mapKitRequest.resultTypes = [.address, .pointOfInterest]
        if let coordinate {
            mapKitRequest.region = MKCoordinateRegion(MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize(width: 1, height: 1)))
        }
        let search = MKLocalSearch(request: mapKitRequest)
        let response = try await search.start()
        return response.mapItems.compactMap { mapItem in
            guard let location = mapItem.placemark.location?.coordinate else {
                return nil
            }
            return SearchResult(title: query, location: location)
        }
    }

}
