# Release Process

PermissionPilot has not shipped a release yet.

## Before v0.1

- Convert the SwiftPM development target into a release-ready app bundle workflow if needed.
- Add signing and notarization notes.
- Add artifact workflow only after a real build script exists.
- Confirm privacy and security docs match app behavior.

## Release Checklist

- Run required local checks.
- Run `swift build`.
- Run `swift test`.
- Perform manual QA on supported macOS versions.
- Manually compare the app's background item view with `sfltool dumpbtm` and common LaunchAgent/LaunchDaemon directories.
- Manually review `/Library/PrivilegedHelperTools` helper flags for false positives.
- Review permission-sensitive changes.
- Create release notes.
- Attach signed/notarized artifacts only after the signing process is documented.
