# PermissionPilot

PermissionPilot is an open-source macOS privacy and permissions dashboard.

It aims to help people understand which apps have sensitive local permissions, why those permissions matter, and how to review or revoke them in macOS System Settings.

## Status

The latest public alpha, `v0.1.0-alpha.2`, is available as a source-only GitHub prerelease. Signed and notarized `.app` artifacts are not attached until the distribution workflow is ready.

PermissionPilot has an initial native SwiftUI macOS app scaffold. The current app can inventory installed apps, inspect code signing identity, show an educational permission catalog based on a local macOS Privacy & Security audit, label sensitivity, scan LaunchAgents, LaunchDaemons, login items, background tasks, and privileged helper tools, open Full Disk Access guidance when local TCC visibility is limited, perform best-effort local TCC record matching across user and system TCC databases, show conservative review priorities, and export full or filtered local Markdown/JSON reports.

TCC permission-state detection is intentionally conservative. If macOS does not allow the app to read local TCC databases, PermissionPilot marks evidence as unavailable instead of guessing. If readable TCC data has no matching record for an app and permission, the app treats that as `notRecorded`, not as an unknown grant. First-run guidance explains OS visibility limits and offers a single Full Disk Access action for more visibility, but the app stays local-first and read-only.

## v0.1 MVP

The planned v0.1 MVP is implemented in the current app:

- Inventory installed apps and known permission states where macOS allows local inspection.
- Show signing identity metadata such as Team ID and signing authority.
- Highlight high-sensitivity permissions such as Screen Recording, Accessibility, and Full Disk Access.
- Track additional known TCC-backed categories such as Photos, Files & Folders, Calendars, Contacts, Reminders, Bluetooth, Local Network, Speech Recognition, Keyboard Monitoring, App Management, Developer Tools, Remote Desktop, Home, Focus, Motion & Fitness, Browser Passkey Access, System Audio Recording, and Media & Apple Music.
- Include global Privacy & Security categories such as Analytics & Improvements, Apple Advertising, Apple Intelligence Report, Sensitive Content Warning, Blocked Contacts, FileVault, and Background Security Improvements as non-app-scoped audit coverage.
- Group app permission evidence by granted, denied, unknown, unavailable, and not-recorded states.
- Provide conservative review-priority signals without malware verdicts.
- Explain what each permission can allow an app to do.
- Link directly to relevant Privacy & Security panes in System Settings.
- Scan common LaunchAgents, LaunchDaemons, Login Items, background tasks, and privileged helper-tool locations.
- Provide compact, selectable background item review with kind summaries and stale-signal details.
- Hide manual System Settings link QA controls unless Developer Mode is enabled in app settings.
- Export full or filtered local Markdown and JSON privacy reports.

Some scanners remain intentionally best-effort because macOS controls access to TCC data and some background-service sources. In those cases PermissionPilot reports unavailable, unknown, not-recorded, or review-signal evidence instead of guessing.

## Privacy Stance

PermissionPilot is intended to be local-first. It should not collect telemetry by default, transmit permission data, or require a cloud account. Permission and background-service findings should stay on the user's Mac unless the user explicitly exports a report.

## Requirements

Planned development target:

- macOS 14 or newer.
- Xcode 16 or newer.
- Swift 6 where practical.

These requirements may change during the first implementation phase.

## Build, Test, And Run

Build the app:

```sh
swift build
```

Run tests:

```sh
swift test
```

Run the app from SwiftPM:

```sh
swift run PermissionPilot
```

Build a local `.app` bundle:

```sh
bash scripts/build-app-bundle.sh
open .build/app/PermissionPilot.app
```

Run repository checks:

```sh
bash scripts/check-repo.sh
```

## Documentation

- [Development](docs/development.md)
- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Privacy & Security Coverage Audit](docs/privacy-security-audit.md)
- [Release Process](docs/release.md)
- [Roadmap](ROADMAP.md)
- [Privacy](PRIVACY.md)
- [Security](SECURITY.md)

## License

PermissionPilot is released under the MIT License. See [LICENSE](LICENSE).
