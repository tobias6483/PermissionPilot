# Changelog

All notable changes to PermissionPilot will be documented in this file.

## Unreleased

- Reworked dashboard interactions so permission rows, scan summary apps, installed apps, and background items are explicit clickable selections.
- Simplified the right detail pane by removing duplicated permission count cards and consolidating limited-TCC guidance around one prominent Full Disk Access action.
- Added a Settings window with Developer Mode for local System Settings link QA controls.
- Made background items more compact with kind summaries, a table-like list, selected-row detail, and concise stale/OK signals.
- Added typed TCC evidence states for unreadable, missing, no-record, matched, unmapped, query-failed, and legacy authorization-column cases.
- Added first-run guidance for unreadable TCC data, all-unknown permission scans, and empty app/background-item results.
- Improved app details with grouped permission states, high-risk grant highlights, readable evidence summaries, and conservative review-next hints.
- Added developer-only local runtime System Settings link QA status controls for v0.1 manual readiness checks.
- Added background item selection and a detail view with stale reasons, evidence, selectable paths, and why-it-matters context.
- Added conservative app review priority badges and explanations; this is an audit signal, not malware detection.
- Added full and filtered Markdown/JSON export options with filtered report metadata.
- Added scoped, UTC-timestamped default filenames for full and filtered report exports.
- Added report scan summaries to Markdown and JSON exports.
- Added a local `.app` bundle smoke-test script for launch, refresh, crash-report, and clean-quit checks.
- Added permission status summaries in the sidebar and selected permission detail view.
- Added background item search, kind filters, stale-only filtering, and sorting.
- Added dashboard app search, permission status filters, signature filters, and app sorting.
- Expanded privacy and security docs to match current scanner, export, and bundle behavior.
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
