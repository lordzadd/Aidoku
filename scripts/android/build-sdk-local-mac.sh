#!/usr/bin/env bash
# build-sdk-local-mac.sh — Build a Swift Android SDK bundle locally on macOS.
#
# This is a macOS-native adaptation of build-swift-android-sdk.yml (the Linux
# GitHub Actions workflow). Run this instead of waiting for the slow CI builder.
#
# Prerequisites:
#   1. Xcode + Xcode Command Line Tools installed
#   2. OSS Swift toolchain matching your local Swift version installed from:
#        https://www.swift.org/install/macos/
#      e.g. swift-6.2.4-RELEASE-osx.pkg  →  installs to
#        /Library/Developer/Toolchains/swift-6.2.4-RELEASE.xctoolchain
#      (The OSS toolchain is required because Xcode's toolchain lacks `lld`.)
#   3. brew: https://brew.sh
#
# Usage:
#   scripts/android/build-sdk-local-mac.sh
#
# Override defaults with env vars, e.g.:
#   SWIFT_TAG=swift-6.2.4-RELEASE NDK_VERSION=27d \
#     scripts/android/build-sdk-local-mac.sh

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
SWIFT_TAG="${SWIFT_TAG:-swift-6.2.4-RELEASE}"
ANDROID_ARCH="${ANDROID_ARCH:-aarch64}"
NDK_VERSION="${NDK_VERSION:-27d}"
SDK_ANDROID_API_LEVEL="${SDK_ANDROID_API_LEVEL:-24}"
BUNDLE_VERSION="${BUNDLE_VERSION:-0.1}"

# ── Detect host toolchain ────────────────────────────────────────────────────
# We need a toolchain that includes `lld`. Xcode's toolchain lacks lld.
# The OSS Swift toolchain (installed as .pkg) includes it at usr/bin/lld.
OSS_TOOLCHAIN="/Library/Developer/Toolchains/${SWIFT_TAG}.xctoolchain/usr"

TOOLCHAIN=""
if [[ -d "$OSS_TOOLCHAIN" && -f "$OSS_TOOLCHAIN/bin/lld" ]]; then
  TOOLCHAIN="$OSS_TOOLCHAIN"
  echo "==> Using OSS Swift toolchain: $TOOLCHAIN"
else
  echo "error: OSS Swift toolchain with lld not found at $OSS_TOOLCHAIN"
  echo ""
  echo "Install the OSS toolchain for your Swift version from:"
  echo "  https://www.swift.org/install/macos/"
  echo ""
  echo "Download and install: ${SWIFT_TAG}-osx.pkg"
  echo "After installation, re-run this script."
  exit 1
fi

# Verify the toolchain Swift version matches SWIFT_TAG
TOOLCHAIN_VERSION=$("$TOOLCHAIN/bin/swift" --version 2>&1 | head -1)
echo "==> Toolchain: $TOOLCHAIN_VERSION"
"$TOOLCHAIN/bin/swift" --version

# ── Install brew dependencies ────────────────────────────────────────────────
echo "==> Checking build tool dependencies..."
MISSING_BREW_PKGS=()
for pkg in cmake ninja patchelf tree jq; do
  if ! command -v "$pkg" &>/dev/null; then
    MISSING_BREW_PKGS+=("$pkg")
  fi
done
if [[ ${#MISSING_BREW_PKGS[@]} -gt 0 ]]; then
  echo "==> Installing via brew: ${MISSING_BREW_PKGS[*]}"
  brew install "${MISSING_BREW_PKGS[@]}"
fi

# ── Download macOS NDK ────────────────────────────────────────────────────────
ANDROID_NDK_HOME="$HOME/android-ndk-r${NDK_VERSION}"
if [[ ! -d "$ANDROID_NDK_HOME" ]]; then
  echo "==> Downloading Android NDK r${NDK_VERSION} for macOS..."
  NDK_ZIP="/tmp/android-ndk-r${NDK_VERSION}-darwin.zip"
  # Retry up to 3 times
  for attempt in 1 2 3; do
    if curl -fL --retry 3 --retry-delay 5 --connect-timeout 60 \
        "https://dl.google.com/android/repository/android-ndk-r${NDK_VERSION}-darwin.zip" \
        -o "$NDK_ZIP"; then
      break
    fi
    echo "Download attempt $attempt failed, retrying..."
    sleep 5
  done
  echo "==> Extracting NDK..."
  unzip -q "$NDK_ZIP" -d "$HOME"
  rm "$NDK_ZIP"
fi
echo "==> Android NDK: $ANDROID_NDK_HOME"

# On macOS, NDK prebuilt tools are under darwin-x86_64 (runs via Rosetta 2 on Apple Silicon)
NDK_PREBUILT="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64"
if [[ ! -d "$NDK_PREBUILT" ]]; then
  echo "error: NDK prebuilt dir not found at $NDK_PREBUILT"
  echo "Check the NDK download or set NDK_VERSION correctly."
  exit 1
fi

# ── Clone sdk-config (finagolfin/swift-android-sdk) ──────────────────────────
BUILD_TMPDIR="$(mktemp -d)"
trap 'echo "==> Cleaning up $BUILD_TMPDIR"; rm -rf "$BUILD_TMPDIR"' EXIT
SDK_CONFIG_DIR="$BUILD_TMPDIR/sdk-config"
echo "==> Cloning swift-android-sdk config into $SDK_CONFIG_DIR..."
git clone --depth 1 https://github.com/finagolfin/swift-android-sdk.git "$SDK_CONFIG_DIR"

# ── Build ────────────────────────────────────────────────────────────────────
cd "$SDK_CONFIG_DIR"
echo "==> Fetching Swift source repos and Termux packages..."
# Do NOT set BUILD_SWIFT_PM — the script checks `!= nil`, so any value
# (including "0") enables extraSwiftRepos and triggers the SwiftPM-for-Android
# cross-compile which fails with "missing required module 'SwiftAndroid'".
# Core SDK only needs stdlib, Foundation, libdispatch, XCTest.
ANDROID_ARCH="$ANDROID_ARCH" SWIFT_TAG="$SWIFT_TAG" \
  "$TOOLCHAIN/bin/swift" get-packages-and-swift-source.swift

echo "==> Applying patches..."
# Only apply the core Android support patch. The CI patches (swift-android-ci,
# swift-android-ci-prebuilt, swift-android-ci-release, swift-android-spawn)
# exclusively patch extraSwiftRepos (llbuild, swiftpm, sourcekit-lsp, etc.)
# which are not cloned for a core SDK build.
git apply -C1 swift-android.patch

# Patch execinfo.h — macOS NDK path uses darwin-x86_64
perl -pi -e 's%33%24%' \
  "$NDK_PREBUILT/sysroot/usr/include/execinfo.h"

VERSION="$(echo "$SWIFT_TAG" | cut -f1,2 -d-)-release"
SDK_DIR="$VERSION-android-${SDK_ANDROID_API_LEVEL}-sdk"
ROOT="android-${NDK_VERSION}-sysroot"
SYSROOT="$SDK_DIR/$ROOT"

mkdir "$SDK_DIR"

# Remove any stale swift libs from NDK sysroot, copy fresh sysroot
rm -rf "$NDK_PREBUILT/sysroot/usr/lib/swift"
cp -a "$NDK_PREBUILT/sysroot" "$SYSROOT"

SDK_NAME="$(ls | grep "swift-release-android-${ANDROID_ARCH}" | head -n1)"
SDK="$(pwd)/$SDK_NAME"

cp "$SYSROOT/usr/include/execinfo.h" "$SDK_NAME/usr/include"
perl -pi -e 's%33%24%' "$SDK_NAME/usr/include/execinfo.h"

# NDK r27's spawn.h guards posix_spawnattr_* behind #if __ANDROID_API__ >= 28.
# Foundation/Process.swift uses posix_spawnattr_destroy unconditionally, causing
# "cannot find in scope" errors at API 24. Replace with libandroid-spawn's spawn.h.
cp "$SDK_NAME/usr/include/spawn.h" "$NDK_PREBUILT/sysroot/usr/include/spawn.h"
cp "$SDK_NAME/usr/include/spawn.h" "$SYSROOT/usr/include/spawn.h"

echo "==> Building Swift stdlib for Android (this takes 1-3 hours)..."
./swift/utils/build-script -RA \
  --skip-build-cmark \
  --build-llvm=0 \
  --android \
  --android-ndk "$ANDROID_NDK_HOME" \
  --android-arch "$ANDROID_ARCH" \
  --android-api-level "$SDK_ANDROID_API_LEVEL" \
  --native-swift-tools-path="$TOOLCHAIN/bin" \
  --native-clang-tools-path="$TOOLCHAIN/bin" \
  --cross-compile-hosts="android-$ANDROID_ARCH" \
  --cross-compile-deps-path="$SDK" \
  --skip-local-build \
  --build-swift-static-stdlib \
  --xctest \
  --install-swift \
  --install-libdispatch \
  --install-foundation \
  --install-xctest \
  --install-destdir="$SDK" \
  --swift-install-components='compiler;clang-resource-dir-symlink;license;stdlib;sdk-overlay' \
  --cross-compile-append-host-target-to-destdir=False \
  --cross-compile-build-swift-tools=False \
  -p "--foundation-cmake-options=-DCMAKE_SHARED_LINKER_FLAGS=''"

echo "==> Post-processing SDK libraries..."
pushd "$SDK_NAME/usr"
  patchelf --set-rpath '$ORIGIN' lib/swift/android/lib[dFXs]*.so
  rm -r bin \
    lib/libsqlite3.so lib/lib{curses,ncurses}.so lib/terminfo \
    share/{tabset,terminfo} 2>/dev/null || true
  mv include/curl include/execinfo.h include/libxml2 include/spawn.h .
  rm -r include/*
  mv curl execinfo.h libxml2 spawn.h include/
  cp -r ../../swift/lib/ClangImporter/SwiftBridging/{module.modulemap,swift} include/

  TRIPLE="${ANDROID_ARCH}-linux-android"
  mkdir -p "lib/${TRIPLE}"
  mv lib/lib[a-z]*.so lib/pkgconfig lib/swift/android/lib*.{a,so} "lib/${TRIPLE}" 2>/dev/null || true

  mv lib/swift_static "lib/swift_static-${ANDROID_ARCH}"
  mv lib/libandroid-spawn.a "lib/swift_static-${ANDROID_ARCH}/android"
  rm -rf "lib/swift" "lib/swift_static-${ANDROID_ARCH}/clang"
popd

rsync -ar "${SDK_NAME}/" "$SYSROOT"

mkdir -p "$SYSROOT/usr/lib/swift/clang/lib"
cp -r "$TOOLCHAIN/lib/clang"/*/include "$SYSROOT/usr/lib/swift/clang"
mv "$SYSROOT/linux" "$SYSROOT/usr/lib/swift/clang/lib"
ln -s "../swift/clang" "$SYSROOT/usr/lib/swift_static-${ANDROID_ARCH}/clang"

cd "$SYSROOT"
git apply ../../libc++-stdlib.h.patch
cd ../..

# ── Package artifact bundle ───────────────────────────────────────────────────
BUNDLE="${SWIFT_TAG}-android-${SDK_ANDROID_API_LEVEL}-${BUNDLE_VERSION}"
BUNDLE_DIR="$BUNDLE.artifactbundle"
mkdir "$BUNDLE_DIR"
mv "$SDK_DIR" "$BUNDLE_DIR"

cat > "$BUNDLE_DIR/info.json" << JSON
{
  "schemaVersion": "1.0",
  "artifacts": {
    "${BUNDLE}": {
      "variants": [{ "path": "${SDK_DIR}" }],
      "version": "${BUNDLE_VERSION}",
      "type": "swiftSDK"
    }
  }
}
JSON

cat > "$BUNDLE_DIR/$SDK_DIR/swift-sdk.json" << JSON
{
  "schemaVersion": "4.0",
  "targetTriples": {
JSON

LAST_API=35
for api in $(seq "$SDK_ANDROID_API_LEVEL" "$LAST_API"); do
  if [[ "$api" == "$LAST_API" ]]; then
    TRAILING_COMMA=""
  else
    TRAILING_COMMA=","
  fi
  cat >> "$BUNDLE_DIR/$SDK_DIR/swift-sdk.json" << JSON
    "${ANDROID_ARCH}-unknown-linux-android${api}": {
      "sdkRootPath": "${ROOT}",
      "swiftResourcesPath": "${ROOT}/usr/lib/swift",
      "swiftStaticResourcesPath": "${ROOT}/usr/lib/swift_static-${ANDROID_ARCH}",
      "toolsetPaths": ["swift-toolset.json"]
    }${TRAILING_COMMA}
JSON
done

cat >> "$BUNDLE_DIR/$SDK_DIR/swift-sdk.json" << JSON
  }
}
JSON

cat > "$BUNDLE_DIR/$SDK_DIR/swift-toolset.json" << JSON
{
  "cCompiler": { "extraCLIOptions": ["-fPIC"] },
  "swiftCompiler": { "extraCLIOptions": ["-Xclang-linker", "-fuse-ld=lld"] },
  "schemaVersion": "1.0"
}
JSON

cat > "$BUNDLE_DIR/$SYSROOT/SDKSettings.json" << JSON
{
  "DisplayName": "Android NDK ${NDK_VERSION} sysroot with ${VERSION} runtime libraries for API ${SDK_ANDROID_API_LEVEL}",
  "Version": "27.3.13750724",
  "VersionMap": {},
  "CanonicalName": "${VERSION}-android${SDK_ANDROID_API_LEVEL}"
}
JSON

echo "==> Bundle layout:"
tree "$BUNDLE_DIR" 2>/dev/null || find "$BUNDLE_DIR" -maxdepth 3 | sort

BUNDLE_TAR="$HOME/${BUNDLE_DIR}.tar.gz"
BUNDLE_SHA="$HOME/${BUNDLE_DIR}.sha256"

echo "==> Creating tarball at $BUNDLE_TAR..."
tar czf "$BUNDLE_TAR" "$BUNDLE_DIR"

# shasum -a 256 is macOS-native; sha256sum is Linux-only
if command -v sha256sum &>/dev/null; then
  sha256sum "$BUNDLE_TAR" | tee "$BUNDLE_SHA"
else
  shasum -a 256 "$BUNDLE_TAR" | tee "$BUNDLE_SHA"
fi

echo ""
echo "==> Build complete!"
echo "    Bundle:   $BUNDLE_TAR"
echo "    Checksum: $BUNDLE_SHA"
echo ""
echo "==> Install with:"
echo "    swift sdk install '$BUNDLE_TAR'"
echo ""
echo "==> Then build Aidoku for Android with:"
echo "    scripts/android/build-swift-android.sh"
