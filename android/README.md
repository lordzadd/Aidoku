# Android Swift Runtime Scaffold

This directory contains scaffolding for a pure Swift Android path.

## Current state
- `AidokuCore`, `AidokuAndroidAdapters`, and `AidokuBootstrap` compile in SwiftPM.
- Android app UI/runtime parity is **not yet implemented** in this scaffold.

## Toolchain prerequisites
1. Install Swift Android SDK(s) (`swift sdk install ...`).
2. Confirm with `swift sdk list`.
3. Build via `scripts/android/build-swift-android.sh <sdk-id>`.

## Next implementation steps
- Bind Swift module outputs into an Android packaging/runtime host.
- Add Swift-driven Android UI stack and navigation.
- Integrate persistence, tracker OAuth flows, and WASM source execution.
