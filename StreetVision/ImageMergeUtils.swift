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

final class ImageMergeUtils {

    class func combine(metadata: GMapsMetadataResponse, zoomLevel: ZoomLevel, tiles: [TileResult]) -> UIImage {
        let tileHeight = metadata.tileHeight
        let tileWidth = metadata.tileWidth
        let maxX = tiles.map { $0.x }.max()!
        let maxY = tiles.map { $0.y }.max()!
        debugPrint("Generating image maxX \(maxX) maxY \(maxY)")
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: tileWidth * maxX, height: tileHeight * maxY))
        return renderer.image { context in
            tiles.forEach {
                $0.image.draw(at: CGPoint(x: $0.x * tileWidth, y: $0.y * tileHeight))
            }
        }
    }

}