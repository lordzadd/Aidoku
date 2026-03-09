# Android Swift Runtime Scaffold

This directory contains scaffolding for a pure Swift Android path.

## Current state
- `AidokuCore`, `AidokuAndroidAdapters`, and `AidokuBootstrap` compile in SwiftPM.
- Android app UI/runtime parity is **not yet implemented** in this scaffold.

## Toolchain prerequisites
1. Install Swift Android SDK(s) (`swift sdk install ...`).
2. Confirm with `swift sdk list`.
3. Build via `scripts/android/build-swift-android.sh [sdk-id]`.

## Verified command

```bash
swift sdk install \
  https://github.com/finagolfin/swift-android-sdk/releases/download/6.2/swift-6.2-RELEASE-android-24-0.1.artifactbundle.tar.gz \
  --checksum c26ebfd4e32c0ca1beabcc45729b62042da57ee76d7d043f63f2235da90dc491
```

## Known blocker

If your local Swift compiler patch version does not match the Android SDK bundle's Swift patch version, the build fails when importing Foundation.  
Current build script detects this and reports it explicitly.

## Next implementation steps
- Bind Swift module outputs into an Android packaging/runtime host.
- Add Swift-driven Android UI stack and navigation.
- Integrate persistence, tracker OAuth flows, and WASM source execution.
