#!/usr/bin/env bash
# Builds build/Fishtank-<version>.dmg: exports the .app with Godot, then wraps it in a
# drag-to-Applications disk image.
#
#   tools/release/build_macos.sh
#
# The app is ad-hoc signed only. It runs on the Mac that built it; other Macs will show an
# "unidentified developer" warning until we sign with a Developer ID and notarize.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-godot}"
VERSION="$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$ROOT/project.godot")"
NAME="Fishtank"
OUT="$ROOT/build"
APP="$OUT/macos/$NAME.app"
DMG="$OUT/$NAME-$VERSION.dmg"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "==> Building native menu-bar agent"
"$ROOT/native/macos_agent/build.sh"

echo "==> Exporting $NAME $VERSION"
rm -rf "$OUT/macos" && mkdir -p "$OUT/macos"
"$GODOT" --headless --path "$ROOT" --export-release "macOS" "$APP"

echo "==> Verifying signature"
codesign --verify --deep --strict "$APP"
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist"

echo "==> Building $DMG"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -quiet -volname "$NAME $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
hdiutil verify -quiet "$DMG"

echo "==> Done: $DMG ($(du -h "$DMG" | cut -f1))"
