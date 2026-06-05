# Architecture

PermissionPilot has not added the app scaffold yet.

## Planned Shape

- SwiftUI app shell for presentation and navigation.
- Scanner services for app inventory, TCC-readable state, LaunchAgents, LaunchDaemons, Login Items, and helper tools.
- Explanation content model for permission education.
- Export service for Markdown and JSON reports.
- System Settings linking service.

## Boundaries

- Scanners should report what they can inspect and why a value may be unknown.
- UI code should not directly parse system files.
- Export code should be explicit about included fields.
- Any privileged helper or background component must be treated as a separate reviewed subsystem.

## Future Separation Points

- Core scanner library.
- App UI.
- Export formats.
- Admin/audit integrations.

