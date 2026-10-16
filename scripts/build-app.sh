#!/bin/zsh
# Builds a native arm64 DivGrid.app into ./build (ad-hoc signed).
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release --arch arm64
APP=build/DivGrid.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --arch arm64 --show-bin-path)/DivGrid" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/Info.plist"
# With SIGN_IDENTITY (e.g. "Developer ID Application: G6 Studio LLC (TEAMID)") the app is signed with the
# hardened runtime, as notarization requires. Otherwise it is signed ad hoc with a stable designated
# requirement so the Accessibility grant survives rebuilds.
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
else
    codesign --force --sign - -r='designated => identifier "studio.g6.divgrid"' "$APP"
fi
echo "Built $APP"
