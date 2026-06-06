# Release Process

PermissionPilot's current downloadable alpha plan is an unsigned `.app.zip` prerelease with a SHA-256 checksum, matching the early artifact model used by sibling projects before Developer ID distribution is ready.

Signed and notarized DMG artifacts are not attached until the Developer ID distribution workflow is complete.

## Artifact Policy

- Source-only prereleases are allowed while app packaging is not ready.
- Unsigned `.app.zip` prereleases are allowed for early technical testing when release notes clearly state that the artifact is unsigned, not notarized, and may trigger Gatekeeper warnings.
- Signed and notarized DMG releases require the full Developer ID workflow.
- Include SHA-256 checksums for every attached app artifact.
- Confirm no exported local permission reports, app inventories, private logs, local-only planning notes, or unsigned rehearsal bundles outside the intended artifact are attached.
- Confirm privacy and security docs match app behavior.

## Before Signed v0.1 DMG Artifacts

- Exercise the SwiftPM app bundle workflow on a clean checkout.
- Configure a real Developer ID signing identity before distributing artifacts.
- Run notarization and stapling manually until an automated artifact workflow is added.
- Add an artifact workflow only after signing credentials can be stored safely.
- Keep signed DMG GitHub Release drafts artifact-free until the exact signed and notarized artifact is ready.

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

Do not attach signed/notarized DMG artifacts until signing, notarization, stapling, and verification have all passed for the exact artifact being published.

## GitHub Release Draft

Create GitHub Releases only from a reviewed, merged, and tagged commit on the default branch. Do not create a public release from an unmerged feature branch.

Recommended unsigned app artifact prerelease flow, using `v0.1.0-alpha.4` as an alpha example:

```sh
git switch main
git pull --ff-only
VERSION=0.1.0 BUILD_NUMBER=4 bash scripts/build-app-bundle.sh
mkdir -p dist/artifacts
ditto -c -k --keepParent .build/app/PermissionPilot.app dist/artifacts/PermissionPilot.app.zip
shasum -a 256 dist/artifacts/PermissionPilot.app.zip > dist/artifacts/PermissionPilot.app.zip.sha256
git tag -a v0.1.0-alpha.4 -m "PermissionPilot v0.1.0-alpha.4"
git push origin v0.1.0-alpha.4
gh release create v0.1.0-alpha.4 --prerelease --title "PermissionPilot v0.1.0-alpha.4" --notes-file docs/v0.1-release-notes.md dist/artifacts/PermissionPilot.app.zip dist/artifacts/PermissionPilot.app.zip.sha256
```

For unsigned app artifact prereleases:

- Attach only the intended `.app.zip` and matching `.sha256`.
- Make the unsigned and not-notarized status explicit in GitHub release notes.
- Confirm the checksum file validates the uploaded zip before publishing.
- Make the prerelease status explicit in GitHub.

Before publishing any signed release with app artifacts:

- Confirm `docs/v0.1-release-notes.md` matches the exact tagged commit.
- Attach only signed, notarized, stapled, and verified artifacts.
- Include checksums for attached artifacts.
- Confirm no exported local permission reports, app inventories, private logs, local-only planning notes, or unsigned rehearsal bundles are attached.
- Publish only after the release checklist is complete.

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
- Confirm permission/sidebar rows, installed app rows, and background item rows are selectable.
- Confirm the grouped permission sidebar shows audited TCC-backed categories, global/system categories, and scan summary destinations.
- Confirm scan summary `background items` and `potentially stale` rows open the background item workflow in the content column.
- Confirm user and system TCC database evidence is reported without exporting private rows.
- Confirm global Privacy & Security categories are marked not app-scoped rather than presented as app grants.
- Confirm Full Disk Access guidance uses one prominent System Settings action.
- Enable Developer Mode in app Settings and manually test Link QA status controls.
- Manually compare app signing identity rows with `codesign -dv --verbose=4 <app>`.
- Manually compare the app's background item view with `sfltool dumpbtm` and common LaunchAgent/LaunchDaemon directories.
- Manually review `/Library/PrivilegedHelperTools` helper flags for false positives.
- Review permission-sensitive changes.
- Create release notes.
- Create a GitHub prerelease from the tagged default-branch commit.
- Attach signed/notarized artifacts only after the signing process is documented and verified.
