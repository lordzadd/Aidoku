#!/usr/bin/env bash
set -euo pipefail

# Usage:
# scripts/android/build-swift-android.sh [sdk-id] [toolchain-path]
#
# sdk-id        — e.g. swift-6.2-RELEASE-android-24-0.1  (auto-detected if omitted)
# toolchain-path — path to an OSS Swift toolchain's usr dir, required when the
#                  SDK version differs from Xcode's Swift (e.g. using the 6.2 OSS
#                  toolchain with the prebuilt 6.2 SDK while Xcode has 6.2.4).
#                  e.g. /Library/Developer/Toolchains/swift-6.2-RELEASE.xctoolchain
#
# Quick-start with the prebuilt 6.2 SDK + OSS 6.2 toolchain:
#   scripts/android/build-swift-android.sh \
#     swift-6.2-RELEASE-android-24-0.1 \
#     /Library/Developer/Toolchains/swift-6.2-RELEASE.xctoolchain

SDK_ID="${1:-}"
TOOLCHAIN_PATH="${2:-}"

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

TOOLCHAIN_FLAG=()
if [[ -n "${TOOLCHAIN_PATH}" ]]; then
  TOOLCHAIN_FLAG=(--toolchain "${TOOLCHAIN_PATH}")
  echo "Using toolchain: ${TOOLCHAIN_PATH}"
fi

echo "Building Aidoku cross-platform package for Android using SDK ${SDK_ID}"
BUILD_OUTPUT="$(mktemp)"
if ! swift build --package-path "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" \
    --swift-sdk "${SDK_ID}" "${TOOLCHAIN_FLAG[@]}" -c release 2>&1 | tee "${BUILD_OUTPUT}"; then
  if grep -q "module compiled with Swift .* cannot be imported by the Swift .* compiler" "${BUILD_OUTPUT}"; then
    echo
    echo "error: Swift compiler/Android SDK mismatch."
    echo "The SDK was built with a different Swift version than your active compiler."
    echo ""
    echo "Option A — use the prebuilt 6.2 SDK with the matching 6.2 OSS toolchain:"
    echo "  1. Install: https://download.swift.org/swift-6.2-release/xcode/swift-6.2-RELEASE/swift-6.2-RELEASE-osx.pkg"
    echo "  2. Re-run:  $0 swift-6.2-RELEASE-android-24-0.1 /Library/Developer/Toolchains/swift-6.2-RELEASE.xctoolchain"
    echo ""
    echo "Option B — build a matched SDK for your current Swift:"
    swift --version | head -n 1
    echo "  scripts/android/build-sdk-local-mac.sh"
  fi
  rm -f "${BUILD_OUTPUT}"
  exit 1
fi
rm -f "${BUILD_OUTPUT}"
