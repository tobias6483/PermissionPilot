# Architecture

PermissionPilot currently ships as a Swift Package Manager executable target named `PermissionPilotApp`.

## Current Shape

- `DashboardView`: SwiftUI navigation, app list, permission explanations, background item summary, and export actions.
- `DashboardStore`: Main actor state container for scan results.
- `AppInventoryScanner`: Finds `.app` bundles in `/Applications` and `~/Applications`.
- `TCCDatabaseScanner`: Performs best-effort reads of the user's TCC database through `/usr/bin/sqlite3` and maps known services to permissions.
- `BackgroundItemScanner`: Reads LaunchAgent and LaunchDaemon plists from common locations and parses best-effort `sfltool dumpbtm` output for login items and background tasks.
- `PermissionCatalog`: Educational permission definitions, sensitivity labels, and System Settings URLs.
- `ReportExporter`: Markdown and JSON report generation.
- `SystemSettingsLinker`: Opens relevant macOS System Settings panes.

## Boundaries

- Scanners should report what they can inspect and why a value may be unknown.
- UI code should not directly parse system files.
- Export code should be explicit about included fields.
- Any privileged helper or background component must be treated as a separate reviewed subsystem.

## Current Limitations

- TCC permission states depend on macOS allowing local database access.
- Login Items scanning depends on undocumented `sfltool dumpbtm` output and should be treated as best-effort.
- The current app is distributed as a SwiftPM executable during development, not a signed `.app` bundle.

## Future Separation Points

- Core scanner library.
- App UI.
- Export formats.
- Admin/audit integrations.
