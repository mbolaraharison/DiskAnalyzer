public struct ScanFolder: Sendable {
    private let scanner: DiskScanning
    public init(scanner: DiskScanning) { self.scanner = scanner }

    public func callAsFunction(_ path: String, progress: (Int) -> Void = { _ in }) -> Node? {
        scanner.scan(path, progress: progress)
    }
}

public struct TrashItem: Sendable {
    private let trasher: FileTrashing
    public init(trasher: FileTrashing) { self.trasher = trasher }

    /// Moves the item to the Trash, then drops it from the tree so sizes stay correct.
    public func callAsFunction(_ node: Node) throws {
        try trasher.trash(path: node.path)
        node.remove()
    }
}

public struct ListVolumes: Sendable {
    private let provider: VolumeProviding
    public init(provider: VolumeProviding) { self.provider = provider }

    public func callAsFunction() -> [Volume] { provider.volumes() }
}
