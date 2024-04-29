//
//  ImageCombiner.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import Foundation
import UIKit

struct TileResult {

    let x: Int
    let y: Int
    let image: UIImage

}

final class ImageUtils {

    class func combine(metadata: GMapsMetadataResponse, zoomLevel: ZoomLevel, tiles: [TileResult]) -> UIImage? {
        guard !tiles.isEmpty else {
            return nil
        }
        let tileHeight = metadata.tileHeight
        let tileWidth = metadata.tileWidth
        let (maxX, maxY) = canvasSize(metadata: metadata, zoomLevel: zoomLevel)
        debugPrint("Generating image maxX \(maxX) maxY \(maxY)")
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: tileWidth * maxX, height: tileHeight * maxY))
        return renderer.image { context in
            tiles.forEach {
                $0.image.draw(at: CGPoint(x: $0.x * tileWidth, y: $0.y * tileHeight))
            }
        }
    }

    /// https://www.linkedin.com/pulse/obtaining-google-street-view-spherical-images-tutorial-william-pierce/
    static func canvasSize(metadata: GMapsMetadataResponse, zoomLevel: ZoomLevel) -> (maxX: Int, maxY: Int) {
        let imageHeight = metadata.imageHeight
        let imageWidth = metadata.imageWidth
        let tileHeight = metadata.tileHeight
        let tileWidth = metadata.tileWidth
        debugPrint("Calculating canvs size, tile x count \(Int(imageWidth / tileWidth)), tile y count \(Int(imageHeight / tileHeight))")
        let maxX = Int(Int(imageWidth / tileWidth) / Int(pow(Double(2), Double(5 - zoomLevel.rawValue))))
        let maxY = Int(Int(imageHeight / tileHeight) / Int(pow(Double(2), Double(5 - zoomLevel.rawValue))))
        return (maxX, maxY)
    }

}
