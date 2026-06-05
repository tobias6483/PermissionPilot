# Requirements

## Product Requirement Coverage

| Requirement | Status | Notes |
| --- | --- | --- |
| Native SwiftUI macOS app | Planned | First implementation milestone. |
| Installed app inventory | Planned | Should include bundle metadata where available. |
| TCC permission overview | Planned | Must respect macOS access limits. |
| Sensitivity labels | Planned | High, medium, and low categories. |
| Explain mode | Planned | Educational descriptions for each permission. |
| System Settings deep links | Planned | Open relevant Privacy & Security panes. |
| LaunchAgents and LaunchDaemons scanner | Planned | Include user and system locations. |
| Login Items scanner | Planned | Depends on supported macOS APIs. |
| Helper tool detection | Planned | Needs careful false-positive handling. |
| Markdown report export | Planned | Explicit user action only. |
| JSON report export | Planned | Explicit user action only. |
| No telemetry by default | Planned | Privacy principle. |

## Release Gate For v0.1

- App builds locally.
- Basic scan view works without privileged helper tools.
- User can open relevant System Settings panes.
- Exported reports are clearly labeled.
- Privacy and security docs are updated with actual behavior.

