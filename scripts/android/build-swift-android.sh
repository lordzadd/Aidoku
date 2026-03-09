#!/usr/bin/env bash
set -euo pipefail

# Usage:
# scripts/android/build-swift-android.sh [sdk-id]
# Example SDK id might look like: android-24-arm64

SDK_ID="${1:-}"
if [[ "${SDK_ID}" == *.artifactbundle ]]; then
  SDK_ID="${SDK_ID%.artifactbundle}"
fi

if [[ -z "${SDK_ID}" ]]; then
  SDK_ID="$(swift sdk list | awk '/android/ {print $1; exit}')"
  if [[ -z "${SDK_ID}" ]]; then
    echo "error: no Android Swift SDK found. Install one with:"
    echo "  swift sdk install <android-artifactbundle-url> --checksum <sha256>"
    exit 1
  fi
  echo "Using detected Android Swift SDK: ${SDK_ID}"
fi

echo "Building Aidoku cross-platform package for Android using SDK ${SDK_ID}"
BUILD_OUTPUT="$(mktemp)"
if ! swift build --package-path "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" --swift-sdk "${SDK_ID}" -c release 2>&1 | tee "${BUILD_OUTPUT}"; then
  if rg -q "module compiled with Swift .* cannot be imported by the Swift .* compiler" "${BUILD_OUTPUT}"; then
    echo
    echo "error: Swift compiler/Android SDK mismatch."
    echo "Install an Android SDK bundle built with the same Swift patch version as:"
    swift --version | head -n 1
  fi
  rm -f "${BUILD_OUTPUT}"
  exit 1
fi
rm -f "${BUILD_OUTPUT}"
