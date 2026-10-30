import Foundation
import DiskDomain
import DiskInfrastructure

/// `DiskAnalyzer --selftest`: real scan of a temp dir + the TrashItem use case against a fake trasher.
enum SelfTest {
    struct FakeTrasher: FileTrashing {
        func trash(path: String) throws {}
    }

    static func run() {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("da-selftest-\(UUID().uuidString)").path
        try! fm.createDirectory(atPath: dir + "/sub", withIntermediateDirectories: true)
        fm.createFile(atPath: dir + "/big", contents: Data(count: 200_000))
        fm.createFile(atPath: dir + "/sub/small", contents: Data(count: 10_000))
        try! fm.createSymbolicLink(atPath: dir + "/link", withDestinationPath: dir + "/big")
        defer { try? fm.removeItem(atPath: dir) }

        let root = ScanFolder(scanner: POSIXDiskScanner(skip: []))(dir)!
        let big = root.children.first { $0.name == "big" }!
        let sub = root.children.first { $0.name == "sub" }!
        let link = root.children.first { $0.name == "link" }!
        precondition(root.children.first === big, "children sorted by size desc")
        precondition(big.size >= 200_000)
        precondition(link.size < 200_000, "symlink must not count target size")
        precondition(sub.size >= sub.children[0].size && sub.children[0].size >= 10_000)
        var dirOwn = stat(); lstat(dir, &dirOwn)
        precondition(root.size == Int64(dirOwn.st_blocks) * 512 + root.children.reduce(0) { $0 + $1.size }, "dir size = own + children")

        let before = root.size, small = sub.children[0]
        try! TrashItem(trasher: FakeTrasher())(small)
        precondition(root.size == before - small.size && sub.children.isEmpty && small.parent == nil, "trash propagates up")
        print("selftest ok")
    }
}
