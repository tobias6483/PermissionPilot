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

Run a local app bundle smoke test:

```sh
bash scripts/smoke-test-app-bundle.sh
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
- Best-effort user and system TCC database record matching through `/usr/bin/sqlite3`.
- Typed TCC evidence states for missing/unreadable databases, no records, matched grants/denials, query failures, and modern versus legacy authorization columns.
- First-run guidance for limited TCC visibility and empty scan results.
- Educational permission catalog and sensitivity labels for audited TCC-backed and global Privacy & Security categories.
- A prominent Full Disk Access action when local TCC visibility is limited.
- Developer Mode setting for runtime-only manual QA status controls for System Settings links.
- Explicit clickable selections for permissions, scan summary apps, installed apps, and background items.
- Conservative review-priority badges and evidence in app details.
- LaunchAgent and LaunchDaemon scanning from common system and user locations.
- Best-effort login item and background task scanning through `/usr/bin/sfltool dumpbtm`.
- Privileged helper tool scanning from `/Library/PrivilegedHelperTools`.
- Compact background item review with kind summaries, stale/OK signals, and selected-item detail.
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
- Run `bash scripts/smoke-test-app-bundle.sh` to launch the bundle, trigger `Refresh Scan`, check for fresh crash reports, and quit the app.
- Open `.build/app/PermissionPilot.app`.
- Confirm the dashboard loads and refreshes.
- Confirm permission rows, scan summary apps, installed app rows, and background item rows can be selected.
- Confirm selecting an app-scoped permission defaults the app list to recorded states and status sorting, with `Any` still available to show not-recorded apps.
- Confirm the Full Disk Access action opens the expected Privacy & Security pane when TCC visibility is limited.
- Open app Settings, enable Developer Mode, and confirm each permission detail exposes Link QA controls.
- In Developer Mode, mark System Settings link status as `Tested working` or `Tested failed` while checking links. This status is runtime-only UI state and is not persisted.
- Confirm first-run guidance appears when TCC data is unreadable or the scan has only unknown permission states.
- Confirm selected-app permission evidence shows one limited-evidence notice when the TCC database is unreadable.
- Confirm background items render as compact rows with kind summaries and selectable detail.
- Confirm full and filtered Markdown and JSON reports can still be generated. Default save names include full/filtered scope and a UTC timestamp, for example `permissionpilot-full-report-20240101-000000.md`.

## Platform Caveats

macOS intentionally restricts access to some privacy databases and permission states. PermissionPilot should explain limitations instead of pretending to see more than the OS allows.

Current TCC scanning reads the user's `~/Library/Application Support/com.apple.TCC/TCC.db` and the system `/Library/Application Support/com.apple.TCC/TCC.db` only when macOS allows it. Without permission, values are marked unavailable and the app explains that the database was not readable.

Granting Full Disk Access can improve local TCC visibility, but QA should treat it as optional. PermissionPilot must not write to permissions, modify System Settings, or imply that access is required.
