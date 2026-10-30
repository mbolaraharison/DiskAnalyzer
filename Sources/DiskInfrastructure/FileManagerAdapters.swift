import Foundation
import DiskDomain

public struct FileManagerTrasher: FileTrashing {
    public init() {}

    public func trash(path: String) throws {
        try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
    }
}

public struct FileManagerVolumeProvider: VolumeProviding {
    public init() {}

    public func volumes() -> [Volume] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return urls.map { url in
            let v = try? url.resourceValues(forKeys: Set(keys))
            return Volume(path: url.path,
                          name: v?.volumeName ?? url.lastPathComponent,
                          totalBytes: Int64(v?.volumeTotalCapacity ?? 0),
                          freeBytes: v?.volumeAvailableCapacityForImportantUsage ?? 0)
        }
    }
}
