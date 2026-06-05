# PermissionPilot

PermissionPilot is an open-source macOS privacy and permissions dashboard.

It aims to help people understand which apps have sensitive local permissions, why those permissions matter, and how to review or revoke them in macOS System Settings.

## Status

PermissionPilot has an initial native SwiftUI macOS app scaffold. The current app can inventory installed apps, show an educational permission catalog, label sensitivity, scan LaunchAgents and LaunchDaemons, open relevant System Settings panes, and export local Markdown/JSON reports.

Direct TCC permission-state detection is not implemented yet. Current app permission rows show `unknown` until the scanner is expanded in a later milestone.

## Planned MVP

- Inventory installed apps and known permission states where macOS allows local inspection.
- Highlight high-sensitivity permissions such as Screen Recording, Accessibility, and Full Disk Access.
- Explain what each permission can allow an app to do.
- Link directly to relevant Privacy & Security panes in System Settings.
- Scan common LaunchAgents, LaunchDaemons, Login Items, and helper-tool locations.
- Export local Markdown and JSON privacy reports.

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

Run repository checks:

```sh
bash scripts/check-repo.sh
```

## Documentation

- [Development](docs/development.md)
- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Release Process](docs/release.md)
- [Roadmap](ROADMAP.md)
- [Privacy](PRIVACY.md)
- [Security](SECURITY.md)

## License

PermissionPilot is released under the MIT License. See [LICENSE](LICENSE).
