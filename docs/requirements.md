# Requirements

## Product Requirement Coverage

| Requirement | Status | Notes |
| --- | --- | --- |
| Native SwiftUI macOS app | Implemented | SwiftPM executable app scaffold. |
| Installed app inventory | Partial | Scans `/Applications` and `~/Applications` with bundle metadata where available. |
| TCC permission overview | Partial | Best-effort local TCC record matching for known services when macOS allows database access. |
| Sensitivity labels | Implemented | High, medium, and low categories. |
| Explain mode | Implemented | Educational descriptions for each permission. |
| System Settings deep links | Implemented | Opens relevant Privacy & Security panes when macOS accepts the URL. |
| LaunchAgents and LaunchDaemons scanner | Partial | Scans common user and system locations plus relevant `sfltool dumpbtm` records. |
| Login Items scanner | Partial | Parses best-effort `sfltool dumpbtm` output for login items and background tasks. |
| Helper tool detection | Partial | Marks plist executables that no longer exist as potentially stale. |
| Markdown report export | Implemented | Explicit user action only. |
| JSON report export | Implemented | Explicit user action only. |
| No telemetry by default | Implemented | No telemetry or networking code exists. |

## Release Gate For v0.1

- App builds locally.
- Basic scan view works without privileged helper tools.
- User can open relevant System Settings panes.
- Exported reports are clearly labeled.
- Privacy and security docs are updated with actual behavior.
