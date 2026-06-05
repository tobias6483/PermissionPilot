# Architecture

PermissionPilot currently ships as a Swift Package Manager executable target named `PermissionPilotApp`.

## Current Shape

- `DashboardView`: SwiftUI navigation, app list, permission explanations, background item summary, and export actions.
- `DashboardStore`: Main actor state container for scan results.
- `AppInventoryScanner`: Finds `.app` bundles in `/Applications` and `~/Applications`.
- `BackgroundItemScanner`: Reads LaunchAgent and LaunchDaemon plists from common locations.
- `PermissionCatalog`: Educational permission definitions, sensitivity labels, and System Settings URLs.
- `ReportExporter`: Markdown and JSON report generation.
- `SystemSettingsLinker`: Opens relevant macOS System Settings panes.

## Boundaries

- Scanners should report what they can inspect and why a value may be unknown.
- UI code should not directly parse system files.
- Export code should be explicit about included fields.
- Any privileged helper or background component must be treated as a separate reviewed subsystem.

## Current Limitations

- TCC permission states are not directly read yet.
- Login Items scanning is not implemented yet.
- The current app is distributed as a SwiftPM executable during development, not a signed `.app` bundle.

## Future Separation Points

- Core scanner library.
- App UI.
- Export formats.
- Admin/audit integrations.
