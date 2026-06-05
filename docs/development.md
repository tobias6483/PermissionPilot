# Development

PermissionPilot currently uses Swift Package Manager for the first buildable SwiftUI macOS app slice.

## Commands

Build:

```sh
swift build
```

Test:

```sh
swift test
```

Run:

```sh
swift run PermissionPilot
```

Build a local `.app` bundle:

```sh
bash scripts/build-app-bundle.sh
```

Open the generated bundle:

```sh
open .build/app/PermissionPilot.app
```

Repository check:

```sh
bash scripts/check-repo.sh
```

## Current App Workflow

The app currently includes:

- Native SwiftUI dashboard.
- Installed app inventory from `/Applications` and `~/Applications`.
- Code signing identity inspection through `/usr/bin/codesign`.
- Best-effort user TCC database record matching through `/usr/bin/sqlite3`.
- Typed TCC evidence states for missing/unreadable databases, no records, matched grants/denials, query failures, and modern versus legacy authorization columns.
- First-run guidance for limited TCC visibility and empty scan results.
- Educational permission catalog and sensitivity labels.
- System Settings links for known Privacy & Security panes.
- Runtime-only manual QA status controls for System Settings links.
- Conservative review-priority badges and evidence in app details.
- LaunchAgent and LaunchDaemon scanning from common system and user locations.
- Best-effort login item and background task scanning through `/usr/bin/sfltool dumpbtm`.
- Privileged helper tool scanning from `/Library/PrivilegedHelperTools`.
- Full and filtered Markdown and JSON report export.

## Local Planning

`project.md` is intentionally ignored by git and should not be referenced by public docs.

## App Bundle Workflow

`scripts/build-app-bundle.sh` builds the SwiftPM executable and wraps it as `.build/app/PermissionPilot.app`.

The script generates `Contents/Info.plist`, copies the compiled executable into `Contents/MacOS`, and validates the plist with `plutil`. By default the bundle is unsigned and intended for local development or release workflow rehearsal.

Optional environment variables:

- `CONFIGURATION`: `release` by default. Set to `debug` for a debug bundle.
- `BUNDLE_ID`: defaults to `io.github.tobias6483.PermissionPilot`.
- `VERSION`: defaults to `0.1.0`.
- `BUILD_NUMBER`: defaults to `1`.
- `OUTPUT_ROOT`: defaults to `.build/app`.
- `CODESIGN_IDENTITY`: when set, the script signs and verifies the bundle with hardened runtime enabled.

Manual QA for bundle changes:

- Build the bundle with `bash scripts/build-app-bundle.sh`.
- Open `.build/app/PermissionPilot.app`.
- Confirm the dashboard loads and refreshes.
- Confirm System Settings links still open the expected Privacy & Security panes.
- In each permission detail, mark the System Settings link as `Tested working` or `Tested failed` while checking links. This status is runtime-only UI state and is not persisted.
- Confirm first-run guidance appears when TCC data is unreadable or the scan has only unknown permission states.
- Confirm full and filtered Markdown and JSON reports can still be generated.

## Platform Caveats

macOS intentionally restricts access to some privacy databases and permission states. PermissionPilot should explain limitations instead of pretending to see more than the OS allows.

Current TCC scanning reads the user's `~/Library/Application Support/com.apple.TCC/TCC.db` only when macOS allows it. Without permission, values remain `unknown` and the app explains that the database was not readable.

Granting Full Disk Access can improve local TCC visibility, but QA should treat it as optional. PermissionPilot must not write to permissions, modify System Settings, or imply that access is required.
