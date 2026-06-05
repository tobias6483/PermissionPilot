# Security Policy

## Supported Versions

PermissionPilot has not shipped a stable release yet. Security fixes will target the active development branch until versioned releases begin.

## Reporting A Vulnerability

If GitHub private vulnerability reporting is enabled for this repository, please use it.

If private reporting is not available, contact the maintainer through their GitHub profile before sharing details publicly. Do not post exploit details, private permission reports, local app inventories, file paths that reveal sensitive information, or device identifiers in a public issue.

## Security Principles

- Permission data is sensitive local state.
- Exported reports must make it clear what is included.
- The app should not transmit local permission state by default.
- The current app should not make network requests, collect telemetry, or require a cloud account.
- Scanners should be transparent about inspected paths and limitations.
- Scanners should remain read-only and should not modify TCC databases, startup items, ServiceManagement records, or helper tool locations.
- Code signing metadata helps identify app origin, but it is not a complete trust or safety verdict.
- TCC inspection must remain best-effort and must not bypass macOS protections.
- Login item and background task inspection must remain read-only and transparent about source data.
- Privileged helper tool checks should be conservative; an unreferenced helper is a review signal, not proof of compromise.
- Privileged operations should be avoided unless clearly justified and reviewed.
- Any future helper tool, daemon, or background process requires a dedicated security and privacy review before release.

## Current Security Boundaries

PermissionPilot currently runs as a user-launched macOS app. It does not install a daemon, login item, privileged helper, browser extension, kernel/system extension, or background service.

Current scanner behavior uses system tools and local files only:

- `/usr/bin/codesign` for app signing metadata.
- `/usr/bin/sqlite3` for best-effort user TCC database reads.
- `/usr/bin/sfltool dumpbtm` for login item and background task records.
- Direct plist and directory reads for app bundles, LaunchAgents, LaunchDaemons, and privileged helper tool filenames.

The app should not request or require elevated privileges for the current MVP. If the user grants Full Disk Access in macOS, TCC database visibility may improve, but the app must still treat TCC inspection as read-only and best-effort.

## Report Handling

Exported Markdown and JSON reports can contain sensitive local paths, installed app names, bundle identifiers, permission evidence, signing metadata, and background-service records.

Users should avoid posting full reports in public issues. Public bug reports should redact private paths, device-specific details, and any app inventory data that the user does not want to disclose.

## Review Triggers

Open a dedicated privacy and security review before adding:

- Networking, telemetry, analytics, update checks, crash reporting, or remote integrations.
- Any write operation that changes permissions, startup items, helper tools, or app state outside the user's explicit export destination.
- Any helper tool, daemon, login item, background service, scheduled job, or privileged operation.
- Any broader scanning source such as the system TCC database, additional protected folders, browser profile data, shell history, credentials, or app-specific private databases.
- Distribution changes involving signing, notarization, auto-update, installer packages, or artifact publishing.

## Out Of Scope

- Bypassing macOS TCC protections.
- Reading protected databases without user-granted access.
- Hiding security-relevant app behavior from the user.
- Collecting or selling permission data.
- Treating code signing, stale helper heuristics, or permission state as a malware verdict.
