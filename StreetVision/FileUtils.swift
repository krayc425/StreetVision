//
//  FileUtils.swift
//  StreetVision
//
//  Created by Kuixi Song on 4/27/24.
//

import Foundation
import UniformTypeIdentifiers

final class FileUtils {

    static let cacheDirectoryURL = FileManager.default.temporaryDirectory

    static func cacheSizeString() -> String {
        return cacheDirectoryURL.folderSize().formatted(.byteCount(style: .file))
    }

    static func clearCache() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: cacheDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in fileURLs where fileURL.pathExtension.lowercased() == UTType.jpeg.preferredFilenameExtension?.lowercased() {
                debugPrint("Removing cache for \(fileURL.path())")
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch let error {
            debugPrint("Remove cache file error \(error.localizedDescription)")
        }
    }

}

/// https://gist.github.com/goocarlos/16c13397ec69f32679d3
struct URLFileAttribute {

    private(set) var fileSize: UInt? = nil
    private(set) var creationDate: Date? = nil
    private(set) var modificationDate: Date? = nil

    init(url: URL) {
        let path = url.path
        guard let dictionary: [FileAttributeKey: Any] = try? FileManager.default
            .attributesOfItem(atPath: path) else {
            return
        }

        if dictionary.keys.contains(FileAttributeKey.size),
           let value = dictionary[FileAttributeKey.size] as? UInt {
            self.fileSize = value
        }

        if dictionary.keys.contains(FileAttributeKey.creationDate),
           let value = dictionary[FileAttributeKey.creationDate] as? Date {
            self.creationDate = value
        }

        if dictionary.keys.contains(FileAttributeKey.modificationDate),
           let value = dictionary[FileAttributeKey.modificationDate] as? Date {
            self.modificationDate = value
        }
    }

}

extension URL {

    public func directoryContents() -> [URL] {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
            return directoryContents
        } catch let error {
            print("Error: \(error)")
            return []
        }
    }

    public func folderSize() -> UInt {
        let contents = self.directoryContents()
        var totalSize: UInt = 0
        contents.forEach { url in
            let size = url.fileSize()
            totalSize += size
        }
        return totalSize
    }

    public func fileSize() -> UInt {
        let attributes = URLFileAttribute(url: self)
        return attributes.fileSize ?? 0
    }

}
