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
# Xcode 27 (iOS 27 SDK) — App Store validation rejected the stable
# Xcode 26.6 / iOS 26.5 SDK build with ITMS-90111 ("submissions must use
# the latest Xcode and SDK Release Candidates"), so the newest toolchain
# is required. This also ships the Apple Intelligence features enabled
# (FoundationModels stays weak-linked for iOS 26.x devices).
XCODE="/Applications/Xcode-beta.app"
ARCHIVE="$HOME/Desktop/Artling-v1.0.xcarchive"
EXPORT_DIR="$HOME/Desktop/Artling-export"

if [ ! -f "$KEY_PATH" ]; then
    echo "error: API key not found at $KEY_PATH" >&2
    exit 1
fi

cd "$(dirname "$0")/.."

echo "▸ Archiving with cloud-managed signing (stable Xcode)…"
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
echo "  (IAPs, CloudKit production schema deploy, screenshots, submit for review)."
