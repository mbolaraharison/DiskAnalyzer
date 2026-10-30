import SwiftUI
import AppKit
import DiskDomain
import DiskInfrastructure
import DiskPresentation

@main
enum Main {
    static func main() {
        let args = CommandLine.arguments
        if args.contains("--selftest") { SelfTest.run(); return }
        if let i = args.firstIndex(of: "--write-icon"), i + 1 < args.count { writeIconPNG(to: args[i + 1]); return }
        DiskAnalyzerApp.main()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// Composition root: the only place that knows which adapters back the domain ports.
struct DiskAnalyzerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AnalyzerViewModel(
        scanFolder: ScanFolder(scanner: POSIXDiskScanner()),
        trashItem: TrashItem(trasher: FileManagerTrasher()),
        listVolumes: ListVolumes(provider: FileManagerVolumeProvider())
    )

    var body: some Scene {
        WindowGroup("Disk Analyzer") {
            ContentView().environmentObject(model)
                .frame(minWidth: 900, minHeight: 560)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.applicationIconImage = appIcon()
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
    }
}
