import Foundation

/// A file or directory in a scanned tree. Directory size = own blocks + children.
public final class Node: Identifiable, @unchecked Sendable {
    public let path: String
    public let isDir: Bool
    public private(set) var size: Int64
    public private(set) var children: [Node] = []
    public private(set) weak var parent: Node?

    public init(path: String, isDir: Bool, size: Int64) {
        self.path = path; self.isDir = isDir; self.size = size
    }

    public var name: String { path == "/" ? "/" : (path as NSString).lastPathComponent }

    public func add(_ child: Node) {
        child.parent = self
        size += child.size
        children.append(child)
    }

    public func sortChildrenBySize() {
        children.sort { $0.size > $1.size }
    }

    /// Detaches this node and subtracts its size from every ancestor.
    public func remove() {
        guard let parent else { return }
        parent.children.removeAll { $0 === self }
        var n: Node? = parent
        while let p = n { p.size -= size; n = p.parent }
        self.parent = nil
    }
}

public struct Volume: Hashable, Sendable {
    public let path: String
    public let name: String
    public let totalBytes: Int64
    public let freeBytes: Int64

    public init(path: String, name: String, totalBytes: Int64, freeBytes: Int64) {
        self.path = path; self.name = name; self.totalBytes = totalBytes; self.freeBytes = freeBytes
    }
}
