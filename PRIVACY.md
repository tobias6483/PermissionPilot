# Privacy

PermissionPilot is intended to be local-first privacy software.

## Data Handling Commitments

- Permission and background-item findings should stay on the user's Mac.
- No telemetry should be collected by default.
- No network requests should be made by the current app.
- No cloud account, remote API, or hosted service should be required.
- Exported Markdown or JSON reports should be created only after explicit user action.
- Full and filtered reports should both be created only after explicit user action.
- Reports should clearly show what categories of data they include.
- Scanning should remain read-only. PermissionPilot should not write to TCC databases, LaunchAgent or LaunchDaemon plists, Login Items, ServiceManagement records, or privileged helper-tool locations.
- Manual System Settings link QA status is local runtime state only and should not be sent anywhere or used to modify permissions.

## Sensitive Data

The app may surface sensitive local state, including:

- Apps with Screen Recording, Accessibility, Full Disk Access, Camera, Microphone, Location, or Automation permissions.
- App code signing identity metadata such as Team ID, signing identifier, and authority chain.
- User TCC database records when macOS allows local inspection.
- LaunchAgents and LaunchDaemons.
- Login Items, ServiceManagement records, and background services exposed by `sfltool dumpbtm`.
- Helper tools and privileged service metadata from `/Library/PrivilegedHelperTools`.
- Local file paths that can reveal installed apps or user-specific setup.

## Current Local Data Sources

The current MVP scanner inspects these local sources:

- Installed app bundles under `/Applications` and `~/Applications`.
- App bundle metadata from each app's `Info.plist` through `Bundle`.
- Code signing metadata by running `/usr/bin/codesign -dv --verbose=4 <app>`.
- User TCC records from `~/Library/Application Support/com.apple.TCC/TCC.db` by running `/usr/bin/sqlite3` only when macOS allows the database to be read.
- LaunchAgent and LaunchDaemon plists from `~/Library/LaunchAgents`, `/Library/LaunchAgents`, and `/Library/LaunchDaemons`.
- Login item, background task, and ServiceManagement records exposed by `/usr/bin/sfltool dumpbtm`.
- Privileged helper tool filenames from `/Library/PrivilegedHelperTools`.

PermissionPilot does not currently inspect the system TCC database, install a helper tool, run as a daemon, modify startup items, or request elevated privileges.

## Permission State Limits

TCC permission status is intentionally conservative:

- `granted` or `denied` is shown only when a matching TCC record is found and parsed.
- `unknown` is shown when the TCC database cannot be read, no matching record exists, or no mapping exists for a permission.
- Evidence should distinguish database unreadable, database missing, no matching record, matched grant/denial, unmapped services, query failures, and whether TCC authorization came from modern `auth_value` or legacy `allowed` columns.
- The app should explain the evidence for each state instead of inferring access from app names, signing identity, or file paths.

Code signing metadata is identity context only. A signed app is not automatically safe, and an unsigned or unvalidated app is not automatically malicious.

Privileged helper tools marked as potentially stale are review signals. The current heuristic checks whether the helper executable is referenced by scanned LaunchAgent or LaunchDaemon plists; it is not proof that a helper is unsafe.

Review priority is also only an audit signal. It is based on conservative local signals such as granted high-sensitivity permissions and unsigned or unknown signing status; it is not malware detection and should not be presented as a safety verdict.

## Exported Reports

Markdown and JSON reports can include app names, bundle identifiers, local paths, signing metadata, permission evidence, review-priority evidence, background item labels, executable paths, and stale-helper signals.

Filtered reports include only the apps and background items visible under the current dashboard filters at export time. The JSON payload includes filtered scope metadata so the summary counts match the filtered data rather than the full scan.

Reports should be treated as sensitive local artifacts. Users should review report contents before sharing them publicly or attaching them to issues.

## Future Changes

Any future analytics, update checks, remote integrations, background agents, helper tools, or network features must be documented before release and reviewed for privacy impact.
