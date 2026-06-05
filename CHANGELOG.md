# Changelog

All notable changes to PermissionPilot will be documented in this file.

## Unreleased

- Added a local SwiftPM-based `.app` bundle build script and documented bundle QA.

- Added code signing identity inspection for installed apps.
- Added initial SwiftUI macOS app scaffold.
- Added installed app inventory from common Applications folders.
- Added best-effort user TCC database scanner and permission record matching.
- Added permission catalog, sensitivity labels, and System Settings links.
- Added LaunchAgent and LaunchDaemon scanning.
- Added best-effort login item and background task scanning through `sfltool dumpbtm`.
- Added privileged helper tool scanning with a conservative stale-reference heuristic.
- Added Markdown and JSON report export with unit tests.
- Added initial public repository documentation and governance files.
- Added local repository check script.
- Added GitHub issue templates and pull request template.
