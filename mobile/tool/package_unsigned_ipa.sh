#!/usr/bin/env bash
#
# Packages the *unsigned* iOS app bundle produced by
#   flutter build ios --release --no-codesign
# into an unsigned .ipa.
#
# An unsigned .ipa cannot be installed as-is. It is meant to be re-signed and
# installed with a free Apple ID using Sideloadly / AltStore / 3uTools on the
# machine that owns the iPhone. Without a paid Apple Developer account this is
# the only way to get the app onto a physical device (the profile lasts 7 days).
#
# Usage (from the mobile/ directory, on macOS):
#   flutter build ios --release --no-codesign
#   bash tool/package_unsigned_ipa.sh
#
# Output: build/ios/ipa/VerifAI-unsigned.ipa

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$ROOT/build/ios/iphoneos/Runner.app"
OUT_DIR="$ROOT/build/ios/ipa"
OUT_IPA="$OUT_DIR/VerifAI-unsigned.ipa"

if [ ! -d "$APP_PATH" ]; then
  echo "error: $APP_PATH not found." >&2
  echo "Run 'flutter build ios --release --no-codesign' first." >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/Payload"
cp -R "$APP_PATH" "$WORK/Payload/"
mkdir -p "$OUT_DIR"

( cd "$WORK" && zip -qry "$OUT_IPA" Payload )

echo "Wrote $OUT_IPA"
