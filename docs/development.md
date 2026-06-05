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

Repository check:

```sh
bash scripts/check-repo.sh
```

## Current App Workflow

The app currently includes:

- Native SwiftUI dashboard.
- Installed app inventory from `/Applications` and `~/Applications`.
- Educational permission catalog and sensitivity labels.
- System Settings links for known Privacy & Security panes.
- LaunchAgent and LaunchDaemon scanning from common system and user locations.
- Markdown and JSON report export.

## Local Planning

`project.md` is intentionally ignored by git and should not be referenced by public docs.

## Platform Caveats

macOS intentionally restricts access to some privacy databases and permission states. PermissionPilot should explain limitations instead of pretending to see more than the OS allows.

Current permission status values are `unknown` until direct TCC scanning is implemented and reviewed.
