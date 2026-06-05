# Release Process

PermissionPilot has not shipped a release yet.

## Before v0.1

- Exercise the SwiftPM app bundle workflow on a clean checkout.
- Add final signing and notarization identities before distributing artifacts.
- Add artifact workflow only after a real build script exists.
- Confirm privacy and security docs match app behavior.

## App Bundle

Build a local release-style bundle:

```sh
bash scripts/build-app-bundle.sh
```

The generated bundle is `.build/app/PermissionPilot.app`. It contains the SwiftPM executable and a generated `Info.plist` with bundle identifier `io.github.tobias6483.PermissionPilot` by default.

The local bundle is unsigned unless `CODESIGN_IDENTITY` is set:

```sh
CODESIGN_IDENTITY="Developer ID Application: Example" bash scripts/build-app-bundle.sh
```

Signing and notarization are not yet finalized for public distribution. Do not attach release artifacts until the signing identity, notarization command, stapling step, and verification steps are documented and tested.

## Release Checklist

- Run required local checks.
- Run `swift build`.
- Run `swift test`.
- Run `bash scripts/build-app-bundle.sh`.
- Open `.build/app/PermissionPilot.app` and perform bundle manual QA.
- Perform manual QA on supported macOS versions.
- Manually compare app signing identity rows with `codesign -dv --verbose=4 <app>`.
- Manually compare the app's background item view with `sfltool dumpbtm` and common LaunchAgent/LaunchDaemon directories.
- Manually review `/Library/PrivilegedHelperTools` helper flags for false positives.
- Review permission-sensitive changes.
- Create release notes.
- Attach signed/notarized artifacts only after the signing process is documented.
