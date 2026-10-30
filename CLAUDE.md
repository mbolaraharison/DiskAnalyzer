## Reverse engineering with REA (rebuild to match the original)
- Capture the original once: recover sources (recover_javascript_sources / export_web_scripts),
  resources (open_bundle_resources, decode_*), flows (capture_*_scenario), traffic (HAR),
  screenshots. Then export_evidence_bundle. Never re-capture what's already exported.
- Before coding, run build_reconstruction_obligation_ledger and track gaps with record_unknown.
- Rebuild one feature slice at a time (trace_application_feature).
- Check each slice with diffs, not by eye: compare_web_screenshots, compare_web_captures,
  compare_javascript_export_shapes, compare_process_captures, compare_functions.
- Run the same scripted scenario (same data, same viewport) on both apps.
- Use detail:"summary" first, then inspect_analysis_view on parent_evidence_id. Don't re-run producers.
- Finish with evaluate_reconstruction_coverage and verify_reconstruction; label hypotheses vs observations.

## This project
Original disk-space analyzer (SwiftPM, SwiftUI, macOS 13+). Own code/UI/branding — do not copy third-party apps.

    swift build
    swift run DiskAnalyzer             # GUI
    swift run DiskAnalyzer --selftest  # scanner + use-case check
    ./bundle.sh                        # build DiskAnalyzer.app and install into /Applications

### Architecture (clean architecture, enforced by SwiftPM targets)
- `DiskDomain` — entities (`Node`, `Volume`), ports (`DiskScanning`, `FileTrashing`, `VolumeProviding`), use cases (`ScanFolder`, `TrashItem`, `ListVolumes`). No dependencies; no AppKit/SwiftUI.
- `DiskInfrastructure` — adapters implementing the ports (POSIX `lstat` scanner, FileManager trash/volumes). Depends on Domain only.
- `DiskPresentation` — `AnalyzerViewModel` + SwiftUI views. Depends on Domain only; talks to use cases, never to adapters.
- `DiskAnalyzer` (executable) — composition root wiring adapters into use cases, app icon, `--selftest`.
- New I/O → add a port in Domain, implement it in Infrastructure, inject it in `App.swift`.
