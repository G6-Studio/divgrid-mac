#!/bin/zsh
# Builds DivGrid.app and packages it as build/DivGrid-<version>.zip (+ .sha256).
# Set SIGN_IDENTITY to sign with Developer ID, and NOTARY_PROFILE (a `notarytool store-credentials`
# keychain profile) to notarize and staple.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build-app.sh
APP=build/DivGrid.app
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
ZIP="build/DivGrid-$VERSION.zip"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    [[ -n "${SIGN_IDENTITY:-}" ]] || { echo "Notarization requires SIGN_IDENTITY" >&2; exit 1; }
    ditto -c -k --keepParent "$APP" build/notarize.zip
    xcrun notarytool submit build/notarize.zip --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    rm build/notarize.zip
fi

rm -f "$ZIP" "$ZIP.sha256"
ditto -c -k --keepParent "$APP" "$ZIP"
(cd build && shasum -a 256 "$(basename "$ZIP")" > "$(basename "$ZIP").sha256")
echo "Packaged $ZIP"
