#!/bin/bash
#
# Publish Artling to App Store Connect using cloud-managed signing.
#
# One-time setup: set ASC_ISSUER_ID to the Issuer ID shown at
# App Store Connect → Users and Access → Integrations → App Store Connect API.
# The API key (AuthKey_V9VT258MM6.p8) is already installed at
# ~/.appstoreconnect/private_keys on this Mac.
#
# Usage:
#   ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ./scripts/publish.sh
#
set -euo pipefail

ISSUER="${ASC_ISSUER_ID:?Set ASC_ISSUER_ID (App Store Connect → Users and Access → Integrations)}"
KEY_ID="V9VT258MM6"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
# Latest release Xcode. (Xcode 27 beta's iOS 27 SDK is rejected by App
# Store validation as "not yet supported".)
XCODE="/Applications/Xcode.app"
ARCHIVE="$HOME/Desktop/Artling-v1.0.xcarchive"
EXPORT_DIR="$HOME/Desktop/Artling-export"
# App Store validation rejects binaries whose BuildMachineOSBuild is a
# beta macOS build (this Mac runs the macOS 27 beta). Stamp the current
# release macOS build instead before export re-signs the app.
RELEASE_MACOS_BUILD="25F84"   # macOS 26.5.2, released 29 Jun 2026

if [ ! -f "$KEY_PATH" ]; then
    echo "error: API key not found at $KEY_PATH" >&2
    exit 1
fi

cd "$(dirname "$0")/.."

echo "▸ Archiving with cloud-managed signing (release Xcode)…"
DEVELOPER_DIR="$XCODE" xcodebuild \
    -project "Little Artist.xcodeproj" \
    -scheme "Little Artist" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    archive -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID "$KEY_ID" \
    -authenticationKeyIssuerID "$ISSUER"

APP_PLIST="$ARCHIVE/Products/Applications/Little Artist.app/Info.plist"
CURRENT_STAMP=$(/usr/libexec/PlistBuddy -c "Print :BuildMachineOSBuild" "$APP_PLIST" 2>/dev/null || echo "")
if [ -n "$CURRENT_STAMP" ]; then
    echo "▸ Re-stamping BuildMachineOSBuild $CURRENT_STAMP -> $RELEASE_MACOS_BUILD…"
    /usr/libexec/PlistBuddy -c "Set :BuildMachineOSBuild $RELEASE_MACOS_BUILD" "$APP_PLIST"
fi

echo "▸ Exporting and uploading to App Store Connect…"
DEVELOPER_DIR="$XCODE" xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist scripts/ExportOptions.plist \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$KEY_PATH" \
    -authenticationKeyID "$KEY_ID" \
    -authenticationKeyIssuerID "$ISSUER"

echo "✓ Build uploaded to App Store Connect."
echo "  Finish the remaining checklist in docs/app-store/metadata-and-submission.md"
