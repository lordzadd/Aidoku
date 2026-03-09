#!/usr/bin/env bash
set -euo pipefail

# Usage:
# scripts/android/build-swift-android.sh [sdk-id]
# Example SDK id might look like: android-24-arm64

SDK_ID="${1:-}"

if [[ -z "${SDK_ID}" ]]; then
  echo "error: missing swift sdk id. Run 'swift sdk list' and pass the installed Android SDK id."
  exit 1
fi

echo "Building Aidoku cross-platform package for Android using SDK ${SDK_ID}"
swift build --package-path "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" --swift-sdk "${SDK_ID}" -c release
