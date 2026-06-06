# Architecture

PermissionPilot currently ships as a Swift Package Manager executable target named `PermissionPilotApp`.

## Current Shape

- `PermissionPilotApp`: SwiftUI app entry point, command menu, Settings scene, and app-wide Developer Mode setting.
- `DashboardView`: SwiftUI navigation, explicit row selection, app list, permission explanations, compact background item review, and export actions.
- `DashboardStore`: Main actor state container for scan results.
- `AppInventoryScanner`: Finds `.app` bundles in `/Applications` and `~/Applications`.
- `CodeSignatureScanner`: Uses `/usr/bin/codesign` to inspect app signing identity metadata.
- `TCCDatabaseScanner`: Performs best-effort reads of the user and system TCC databases through `/usr/bin/sqlite3` and maps known TCC services to privacy permission categories.
- `SystemPrivacySettingsScanner`: Represents global or system-scoped Privacy & Security categories without forcing them into per-app TCC evidence.
- `BackgroundItemScanner`: Reads LaunchAgent and LaunchDaemon plists from common locations, scans `/Library/PrivilegedHelperTools`, and parses best-effort `sfltool dumpbtm` output for login items and background tasks.
- `PermissionCatalog`: Educational permission definitions, sensitivity labels, evidence-source metadata, and System Settings URLs for audited Privacy & Security categories.
- `ReportExporter`: Markdown and JSON report generation.
- `SystemSettingsLinker`: Opens relevant macOS System Settings panes.

## Boundaries

- Scanners should report what they can inspect and why a value may be unknown.
- UI code should not directly parse system files.
- Export code should be explicit about included fields.
- App-scoped TCC permissions, global/system Privacy & Security settings, app identity, and background execution items are separate evidence channels.
- Global/system settings should not be displayed as per-app grants or app-row status badges.
- Any privileged helper or background component must be treated as a separate reviewed subsystem.

## Current Limitations

- TCC permission states depend on macOS allowing local database access.
- Some Privacy & Security panes are not represented as app-scoped TCC service rows. These are modeled through `SystemPrivacySettingsScanner` as not app-scoped until a safe local evidence source is implemented.
- Code signing metadata should be presented as identity context, not as a guarantee that an app is safe.
- Login Items scanning depends on undocumented `sfltool dumpbtm` output and should be treated as best-effort.
- Privileged helper stale detection is heuristic and should be presented as a review signal.
- The current app is distributed as a SwiftPM executable during development, not a signed `.app` bundle.
- Developer Mode exposes local QA controls for System Settings links, but those controls are not part of the default user workflow and do not modify macOS settings.

## Future Separation Points

- Core scanner library.
- App UI.
- Export formats.
- Admin/audit integrations.
