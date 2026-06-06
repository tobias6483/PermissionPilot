# Requirements

## Product Requirement Coverage

| Requirement | Status | Notes |
| --- | --- | --- |
| Native SwiftUI macOS app | Implemented | SwiftPM executable app scaffold. |
| Installed app inventory | Implemented | Scans `/Applications` and `~/Applications` with bundle metadata where available. |
| App signing identity | Implemented | Uses `codesign` to inspect signature status, Team ID, signing identifier, and authority chain. |
| TCC permission overview | Implemented with OS limits | Best-effort local TCC record matching for known services when macOS allows database access; unreadable data is marked unavailable and readable no-match data is marked not recorded. Current known-service coverage includes Location, Browser Passkey Access, Files & Folders, Photos, Full Disk Access, Home, Calendars, Contacts, Media & Apple Music, Reminders, App Management, Automation, Motion & Fitness, Bluetooth, Focus, Camera, Local Network, Microphone, Screen Recording, System Audio Recording, Keyboard Monitoring, Remote Desktop, Speech Recognition, Accessibility, and Developer Tools. |
| Global Privacy & Security categories | Implemented as not app-scoped | Includes Sensitive Content Warning, Blocked Contacts, Analytics & Improvements, Apple Advertising, Apple Intelligence Report, FileVault, Background Security Improvements, Blocked System Software, and System-Wide Settings Protection without pretending they are per-app TCC grants. |
| TCC evidence model | Implemented | Distinguishes database unreadable, database missing, no record, matched granted/denied/unknown, unmapped service, query failure, authorization-column source, and Apple Events target identifiers when available. |
| First-run and empty-state guidance | Implemented | Explains unreadable TCC data, all-unknown permission states, no apps found, and no background items found without pressuring the user to grant access. |
| Permission status summaries | Implemented | Shows granted, denied, unknown, unavailable, and not-recorded app counts in the sidebar for each permission in the current scan. |
| Dashboard selection behavior | Implemented | Permission rows, scan summary apps, scan summary background items, scan summary stale items, installed apps, and background items are explicit clickable selections with visible selected state. |
| Sensitivity labels | Implemented | High, medium, and low categories. |
| App detail evidence view | Implemented | Groups recorded permissions by granted, denied, unknown, and unavailable; highlights high-sensitivity grants; shows concise status lines plus detailed evidence; and collapses all-not-recorded apps into a neutral empty state. |
| Limited TCC evidence state | Implemented | When all selected-app permission evidence is unavailable, the UI shows one concise limited-evidence notice instead of repeating unknown rows. |
| Review priority | Implemented | Conservative low/medium/high audit signal based on high-sensitivity grants and unsigned/unknown signing; not a malware verdict. |
| App list filtering and sorting | Implemented | Search by app metadata, filter by selected permission status and signing state, and sort by name, sensitivity, status, or signature. |
| Explain mode | Implemented | Educational descriptions for each permission. |
| System Settings deep links | Implemented | Provides a prominent Full Disk Access action when local TCC visibility is limited and opens relevant Privacy & Security panes when macOS accepts the URL. |
| Developer Mode link QA | Implemented | Runtime-only local status per permission for untested, tested working, and tested failed links; hidden unless Developer Mode is enabled in app settings. |
| LaunchAgents and LaunchDaemons scanner | Implemented | Scans common user and system locations plus relevant `sfltool dumpbtm` records. |
| Login Items scanner | Implemented with OS limits | Parses best-effort `sfltool dumpbtm` output for login items and background tasks. |
| Helper tool detection | Implemented | Scans `/Library/PrivilegedHelperTools` and marks helpers without a LaunchAgent/LaunchDaemon executable reference as potentially stale. |
| Background item filtering and sorting | Implemented | Search by labels and paths, filter by item kind or stale state, sort by label, kind, or stale status, and review compact kind summaries. |
| Background item detail view | Implemented | Selecting a background item shows kind, label, paths, executable, stale state, stale reason, evidence, and why it matters. |
| Markdown report export | Implemented | Explicit user action only, with scan summary, permission counts, apps, and background items. |
| JSON report export | Implemented | Explicit user action only, with summary metadata and raw report data. |
| Filtered report export | Implemented | Explicit user action only; exports the current filtered apps and background items as Markdown or JSON with filtered scope metadata. |
| No telemetry by default | Implemented | No telemetry or networking code exists. |

## v0.1 MVP Completion

The planned v0.1 MVP is complete in the app code and public documentation. The remaining caveats are operating-system visibility limits and release-operator tasks, not missing MVP features.

Implemented MVP scope:

- Installed app inventory with known permission states where macOS allows local inspection.
- Signing identity metadata including signature status, Team ID, signing identifier, and authority chain.
- High-sensitivity permission highlighting for Screen Recording, System Audio Recording, Accessibility, Full Disk Access, Files & Folders, App Management, Keyboard Monitoring, Developer Tools, Remote Desktop, FileVault, Background Security Improvements, and Blocked System Software.
- Permission evidence grouped by granted, denied, unknown, unavailable, and not-recorded states.
- Conservative review-priority signals without malware verdicts.
- Permission explanations and System Settings deep links.
- Compact, clickable dashboard navigation and selectable installed-app/background-item detail.
- Background item scanning for LaunchAgents, LaunchDaemons, Login Items, background tasks, ServiceManagement records, and privileged helper tools.
- Full and filtered local Markdown/JSON report export.

## Release Gate For v0.1

- App builds locally.
- Basic scan view works without privileged helper tools.
- User can open Full Disk Access guidance when TCC visibility is limited.
- Developer Mode can expose System Settings link manual QA status locally during release checks.
- Exported reports are clearly labeled.
- Privacy and security docs are updated with actual behavior.
- Signed and notarized distribution steps are documented before attaching release artifacts.
