//
//  GoogleMapsAPIUtils.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import Foundation
import UIKit

enum ZoomLevel: Int, Identifiable, CaseIterable {

//    case zero = 0
    case one = 1
    case two
    case three
    case four
    case five

    var id: Int {
        return rawValue
    }

    var displayName: String {
        return rawValue.formatted(.number)
    }

}

/// https://developers.google.com/maps/documentation/tile/session_tokens
struct GMapsSessionResponse: Decodable {
    let session: String
    let expiry: String
    let tileWidth: Int
    let tileHeight: Int
    let imageFormat: String
}

struct GMapsPanoIDsResponse: Decodable {
    let panoIds: [String]
}

struct GMapsMetadataResponse: Decodable {
    let imageHeight: Int
    let imageWidth: Int
    let tileHeight: Int
    let tileWidth: Int
    let date: String
    let copyright: String
}

enum GMapsAPIUtilsError: Error {
    case invalidURLComponents
    case invalidURL
    case invalidPanoID
}

final class GoogleMapsAPIUtils {

    func fetchSessionToken() async -> GMapsSessionResponse? {
        do {
            guard var components = URLComponents(string: "https://tile.googleapis.com/v1/createSession") else {
                throw GMapsAPIUtilsError.invalidURLComponents
            }
            components.queryItems = [
                URLQueryItem(name: "key", value: GoogleMapsAPIKey.apiKey)
            ]
            guard let url = components.url else {
                throw GMapsAPIUtilsError.invalidURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = [
                "mapType": "streetview",
                "language": "en-US",
                "region": "US"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(GMapsSessionResponse.self, from: data)
        } catch let error {
            debugPrint("URL Request Error \(error.localizedDescription)")
            return nil
        }
    }

    func fetchPanoIDs(latitude: Double, longitude: Double, session: GMapsSessionResponse) async -> GMapsPanoIDsResponse? {
        debugPrint("Fetching panoIDs with session ID \(session.session)")
        do {
            guard var components = URLComponents(string: "https://tile.googleapis.com/v1/streetview/panoIds") else {
                throw GMapsAPIUtilsError.invalidURLComponents
            }
            components.queryItems = [
                URLQueryItem(name: "key", value: GoogleMapsAPIKey.apiKey),
                URLQueryItem(name: "session", value: session.session)
            ]
            guard let url = components.url else {
                throw GMapsAPIUtilsError.invalidURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = [
                "locations": [
                    "lat": latitude,
                    "lng": longitude,
                ]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(GMapsPanoIDsResponse.self, from: data)
        } catch let error {
            debugPrint("URL Request Error \(error.localizedDescription)")
            return nil
        }
    }

    func fetchMetadata(session: GMapsSessionResponse, panoIDs: GMapsPanoIDsResponse) async -> GMapsMetadataResponse? {
        do {
            guard let firstPanoID = panoIDs.panoIds.first, !firstPanoID.isEmpty else {
                throw GMapsAPIUtilsError.invalidPanoID
            }
            debugPrint("Fetching metadata with session ID \(session.session) for panoID \(firstPanoID)")
            guard var components = URLComponents(string: "https://tile.googleapis.com/v1/streetview/metadata") else {
                throw GMapsAPIUtilsError.invalidURLComponents
            }
            components.queryItems = [
                URLQueryItem(name: "key", value: GoogleMapsAPIKey.apiKey),
                URLQueryItem(name: "session", value: session.session),
                URLQueryItem(name: "panoId", value: firstPanoID)
            ]
            guard let url = components.url else {
                throw GMapsAPIUtilsError.invalidURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(GMapsMetadataResponse.self, from: data)
        } catch let error {
            debugPrint("URL Request Error \(error.localizedDescription)")
            return nil
        }
    }

    func fetchTiles(metadata: GMapsMetadataResponse, session: GMapsSessionResponse, panoIDs: GMapsPanoIDsResponse, zoomLevel: ZoomLevel) async -> [TileResult] {
        let imageHeight = metadata.imageHeight
        let imageWidth = metadata.imageWidth
        let tileHeight = metadata.tileHeight
        let tileWidth = metadata.tileWidth
        debugPrint("Tile x count \(Int(imageWidth / tileWidth))")
        debugPrint("Tile y count \(Int(imageHeight / tileHeight))")
//        let maxX = zoomLevel == .zero ? 0 : Int(Int(imageWidth / tileWidth) / Int(pow(Double(2), Double(ZoomLevel.five.rawValue - zoomLevel.rawValue))))
//        let maxY = zoomLevel == .zero ? 0 : Int(Int(imageHeight / tileHeight) / Int(pow(Double(2), Double(ZoomLevel.five.rawValue - zoomLevel.rawValue))))
        let maxX = min(Int(imageWidth / tileWidth), Int(pow(Double(2), Double(zoomLevel.rawValue))))
        let maxY = min(Int(imageHeight / tileHeight), Int(pow(Double(2), Double(zoomLevel.rawValue))))
        debugPrint("Fetching tiles with maxX \(maxX) maxY \(maxY)")
        do {
            guard let firstPanoID = panoIDs.panoIds.first else {
                throw GMapsAPIUtilsError.invalidPanoID
            }
            return try await withThrowingTaskGroup(of: Optional<TileResult>.self, returning: [TileResult].self) { group in
                for x in 0..<maxX {
                    for y in 0..<maxY {
                        group.addTask {
                            debugPrint("Fetching tile for x: \(x) y: \(y) level: \(zoomLevel.rawValue)")
                            guard var components = URLComponents(string: "https://tile.googleapis.com/v1/streetview/tiles/\(zoomLevel.rawValue)/\(x)/\(y)") else {
                                throw GMapsAPIUtilsError.invalidURLComponents
                            }
                            components.queryItems = [
                                URLQueryItem(name: "key", value: GoogleMapsAPIKey.apiKey),
                                URLQueryItem(name: "session", value: session.session),
                                URLQueryItem(name: "panoId", value: firstPanoID)
                            ]
                            guard let url = components.url else {
                                throw GMapsAPIUtilsError.invalidURL
                            }
                            var request = URLRequest(url: url)
                            request.httpMethod = "GET"
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            let (data, _) = try await URLSession.shared.data(for: request)
                            debugPrint("Fetched tile for x: \(x) y: \(y) level: \(zoomLevel.rawValue) data: \(data)")
                            if let image = UIImage(data: data) {
                                return TileResult(x: x, y: y, image: image)
                            } else {
                                return nil
                            }
                        }
                    }
                }
                var results: [TileResult] = []
                for try await result in group {
                    if let result {
                        results.append(result)
                    }
                }
                return results
            }
        } catch let error {
            debugPrint("Failed to load tiles \(error.localizedDescription)")
            return []
        }
    }

}
