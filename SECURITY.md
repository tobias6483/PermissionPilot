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
- Scanners should be transparent about inspected paths and limitations.
- TCC inspection must remain best-effort and must not bypass macOS protections.
- Login item and background task inspection must remain read-only and transparent about source data.
- Privileged operations should be avoided unless clearly justified and reviewed.
- Any future helper tool, daemon, or background process requires a dedicated security and privacy review before release.

## Out Of Scope

- Bypassing macOS TCC protections.
- Reading protected databases without user-granted access.
- Hiding security-relevant app behavior from the user.
- Collecting or selling permission data.
