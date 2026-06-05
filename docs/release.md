# Release Process

PermissionPilot has not shipped a release yet.

## Before v0.1

- Exercise the SwiftPM app bundle workflow on a clean checkout.
- Configure a real Developer ID signing identity before distributing artifacts.
- Run notarization and stapling manually until an automated artifact workflow is added.
- Add an artifact workflow only after signing credentials can be stored safely.
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

The build script can sign the app when `CODESIGN_IDENTITY` is set. Public distribution must use a real Developer ID Application identity:

```sh
CODESIGN_IDENTITY="Developer ID Application: Example Name (TEAMID)" \
  bash scripts/build-app-bundle.sh
```

Verify the signature:

```sh
codesign --verify --deep --strict --verbose=2 .build/app/PermissionPilot.app
spctl --assess --type execute --verbose=4 .build/app/PermissionPilot.app
codesign -dv --verbose=4 .build/app/PermissionPilot.app
```

## Notarization

Create a zip for notarization:

```sh
ditto -c -k --keepParent .build/app/PermissionPilot.app .build/app/PermissionPilot.zip
```

Submit it with a configured notarytool profile:

```sh
xcrun notarytool submit .build/app/PermissionPilot.zip \
  --keychain-profile PermissionPilotNotary \
  --wait
```

Staple and verify the accepted ticket:

```sh
xcrun stapler staple .build/app/PermissionPilot.app
xcrun stapler validate .build/app/PermissionPilot.app
spctl --assess --type execute --verbose=4 .build/app/PermissionPilot.app
```

Do not attach release artifacts until signing, notarization, stapling, and verification have all passed for the exact artifact being published.

## Release Checklist

- Run required local checks.
- Run `swift build`.
- Run `swift test`.
- Run `bash scripts/build-app-bundle.sh`.
- Run `bash scripts/smoke-test-app-bundle.sh`.
- For public release artifacts, rerun the bundle build with `CODESIGN_IDENTITY`.
- Verify the signed bundle with `codesign` and `spctl`.
- Notarize, staple, and validate the exact `.app` artifact.
- Open `.build/app/PermissionPilot.app` and perform bundle manual QA.
- Perform manual QA on supported macOS versions.
- Confirm full and filtered Markdown/JSON exports save with scope and UTC timestamp in the default filename.
- Manually compare app signing identity rows with `codesign -dv --verbose=4 <app>`.
- Manually compare the app's background item view with `sfltool dumpbtm` and common LaunchAgent/LaunchDaemon directories.
- Manually review `/Library/PrivilegedHelperTools` helper flags for false positives.
- Review permission-sensitive changes.
- Create release notes.
- Attach signed/notarized artifacts only after the signing process is documented.
