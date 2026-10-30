import Foundation
import DiskDomain

@MainActor
public final class AnalyzerViewModel: ObservableObject {
    @Published var volumes: [Volume] = []
    @Published var current: Node?
    @Published var scanning: String?
    @Published var filesScanned = 0
    @Published var errorMessage: String?
    @Published var version = 0          // bumped when the tree mutates in place

    private let scanFolder: ScanFolder
    private let trashItem: TrashItem
    private let listVolumes: ListVolumes
    private var task: Task<Void, Never>?

    public init(scanFolder: ScanFolder, trashItem: TrashItem, listVolumes: ListVolumes) {
        self.scanFolder = scanFolder
        self.trashItem = trashItem
        self.listVolumes = listVolumes
        volumes = listVolumes()
    }

    func scan(_ path: String) {
        task?.cancel()
        scanning = path; filesScanned = 0; current = nil
        let scanFolder = self.scanFolder
        task = Task {
            let node = await Task.detached(priority: .userInitiated) {
                scanFolder(path) { n in Task { @MainActor in self.filesScanned = n } }
            }.value
            guard !Task.isCancelled else { return }
            current = node; scanning = nil
        }
    }

    func cancel() { task?.cancel(); scanning = nil }

    func goUp() { if let p = current?.parent { current = p } }

    func trash(_ nodes: [Node]) {
        for n in nodes {
            do { try trashItem(n) } catch { errorMessage = error.localizedDescription }
        }
        version += 1
        volumes = listVolumes()   // free space changed
    }
}
