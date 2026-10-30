/// Implemented by the infrastructure layer.

public protocol DiskScanning: Sendable {
    /// Builds the tree under `path`; returns nil if it can't be read or the task was cancelled.
    func scan(_ path: String, progress: (Int) -> Void) -> Node?
}

public protocol FileTrashing: Sendable {
    func trash(path: String) throws
}

public protocol VolumeProviding: Sendable {
    func volumes() -> [Volume]
}
