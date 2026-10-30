import Foundation
import DiskDomain

public struct POSIXDiskScanner: DiskScanning {
    private let skip: Set<String>?

    /// `skip` = directories not to descend into; nil means every other mount point.
    public init(skip: Set<String>? = nil) { self.skip = skip }

    /// Other mount points are skipped so "/" isn't counted twice (its data lives on
    /// /System/Volumes/Data, reached through firmlinks like /Users).
    static func mountPoints() -> Set<String> {
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) ?? []
        return Set(urls.map(\.path) + ["/dev"])
    }

    // ponytail: hard links are counted once per link; dedupe by inode if totals look inflated.
    public func scan(_ root: String, progress: (Int) -> Void) -> Node? {
        let skip = self.skip ?? Self.mountPoints()
        var count = 0
        func visit(_ path: String) -> Node? {
            if Task.isCancelled { return nil }
            var st = stat()
            guard lstat(path, &st) == 0 else { return nil }
            let isDir = (st.st_mode & S_IFMT) == S_IFDIR
            let node = Node(path: path, isDir: isDir, size: Int64(st.st_blocks) * 512)
            count += 1
            if count % 5000 == 0 { progress(count) }
            guard isDir, path == root || !skip.contains(path),
                  let names = try? FileManager.default.contentsOfDirectory(atPath: path) else { return node }
            for name in names {
                guard let child = visit(path == "/" ? "/" + name : path + "/" + name) else { continue }
                node.add(child)
            }
            node.sortChildrenBySize()
            return node
        }
        let node = visit(root)
        progress(count)
        return node
    }
}
