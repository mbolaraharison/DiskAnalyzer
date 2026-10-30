import SwiftUI
import AppKit
import DiskDomain

public struct ContentView: View {
    @EnvironmentObject var model: AnalyzerViewModel

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List {
                Section("Volumes") {
                    ForEach(model.volumes, id: \.self) { v in
                        Button { model.scan(v.path) } label: { VolumeRow(volume: v) }.buttonStyle(.plain)
                    }
                }
                Button("Choose Folder…") {
                    let p = NSOpenPanel()
                    p.canChooseDirectories = true; p.canChooseFiles = false
                    if p.runModal() == .OK, let u = p.url { model.scan(u.path) }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        } detail: {
            if let path = model.scanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning \(path)")
                    Text("\(model.filesScanned) items").monospacedDigit().foregroundStyle(.secondary)
                    Button("Cancel") { model.cancel() }
                }
            } else if let cur = model.current {
                BrowserView(node: cur).id(model.version)
            } else {
                Text("Pick a volume or folder to scan").foregroundStyle(.secondary)
            }
        }
        .alert("Couldn't move to Trash", isPresented: .constant(model.errorMessage != nil)) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

struct VolumeRow: View {
    let volume: Volume
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(volume.name, systemImage: "internaldrive")
            if volume.totalBytes > 0 {
                ProgressView(value: Double(volume.totalBytes - volume.freeBytes), total: Double(volume.totalBytes))
                Text("\(formatSize(volume.freeBytes)) free of \(formatSize(volume.totalBytes))").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BrowserView: View {
    @EnvironmentObject var model: AnalyzerViewModel
    let node: Node
    @State private var selection = Set<Node.ID>()
    @State private var pendingTrash: [Node] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { model.goUp() } label: { Image(systemName: "chevron.left") }
                    .disabled(node.parent == nil)
                Text(node.path).lineLimit(1).truncationMode(.head)
                Spacer()
                Text(formatSize(node.size)).monospacedDigit()
            }
            .padding(8)
            Divider()
            HSplitView {
                Sunburst(root: node, onSelect: open, onBack: model.goUp)
                    .padding()
                    .frame(minWidth: 360)
                fileTable.frame(minWidth: 380)
            }
        }
        .confirmationDialog("Move \(pendingTrash.count) item(s) to Trash?", isPresented: .constant(!pendingTrash.isEmpty)) {
            Button("Move to Trash", role: .destructive) { model.trash(pendingTrash); pendingTrash = [] }
            Button("Cancel", role: .cancel) { pendingTrash = [] }
        } message: {
            Text(pendingTrash.map(\.name).joined(separator: ", ") + " — " + formatSize(pendingTrash.reduce(0) { $0 + $1.size }))
        }
    }

    private var fileTable: some View {
        Table(node.children, selection: $selection) {
            TableColumn("Name") { n in
                Label(n.name, systemImage: n.isDir ? "folder" : "doc")
            }
            TableColumn("Size") { n in Text(formatSize(n.size)).monospacedDigit() }.width(90)
            TableColumn("%") { n in
                ProgressView(value: node.size > 0 ? Double(n.size) / Double(node.size) : 0)
            }.width(80)
        }
        .contextMenu(forSelectionType: Node.ID.self) { ids in
            let items = node.children.filter { ids.contains($0.id) }
            Button("Reveal in Finder") { reveal(items) }
            Button("Move to Trash…") { pendingTrash = items }
        } primaryAction: { ids in
            if let n = node.children.first(where: { ids.contains($0.id) }) { open(n) }
        }
    }

    private func open(_ n: Node) {
        if n.isDir { model.current = n } else { reveal([n]) }
    }

    private func reveal(_ nodes: [Node]) {
        NSWorkspace.shared.activateFileViewerSelecting(nodes.map { URL(fileURLWithPath: $0.path) })
    }
}

func formatSize(_ b: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: b, countStyle: .file)
}
