#!/bin/sh
# Builds DiskAnalyzer.app (universal release binary + Info.plist + AppIcon.icns) and DiskAnalyzer.dmg,
# then installs the app into /Applications.
# Usage: ./bundle.sh [--no-install]   (CI uses --no-install)
set -e
cd "$(dirname "$0")"
ARCHS="--arch arm64 --arch x86_64"
swift build -c release $ARCHS
BIN="$(swift build -c release $ARCHS --show-bin-path)/DiskAnalyzer"

APP=DiskAnalyzer.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/"

SET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$SET"
"$BIN" --write-icon "$SET/icon_512x512@2x.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$SET/icon_512x512@2x.png" --out "$SET/icon_${s}x${s}.png" >/dev/null
  [ $s = 512 ] || sips -z $((s*2)) $((s*2)) "$SET/icon_512x512@2x.png" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>DiskAnalyzer</string>
  <key>CFBundleIdentifier</key><string>local.diskanalyzer</string>
  <key>CFBundleName</key><string>Disk Analyzer</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF
codesign --force --sign - "$APP"   # ad-hoc signature (no Developer ID); required to launch on Apple Silicon
echo "Built $PWD/$APP"

# Drag-to-install disk image: the app next to a shortcut to /Applications.
STAGE="$(mktemp -d)"
ditto "$APP" "$STAGE/$APP"
ln -s /Applications "$STAGE/Applications"
hdiutil create -quiet -volname "Disk Analyzer" -srcfolder "$STAGE" -ov -format UDZO DiskAnalyzer.dmg
echo "Built $PWD/DiskAnalyzer.dmg"
[ "$1" = "--no-install" ] && exit 0

DEST="/Applications/$APP"
pkill -f "$DEST/Contents/MacOS/" || true   # quit a running copy before replacing it
rm -rf "$DEST"
ditto "$APP" "$DEST"
touch "$DEST"   # nudge Finder to refresh the icon
echo "Installed $DEST"
