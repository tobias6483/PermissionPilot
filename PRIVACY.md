# Privacy

PermissionPilot is intended to be local-first privacy software.

## Data Handling Commitments

- Permission and background-item findings should stay on the user's Mac.
- No telemetry should be collected by default.
- No cloud account should be required.
- Exported Markdown or JSON reports should be created only after explicit user action.
- Reports should clearly show what categories of data they include.

## Sensitive Data

The app may surface sensitive local state, including:

- Apps with Screen Recording, Accessibility, Full Disk Access, Camera, Microphone, Location, or Automation permissions.
- User TCC database records when macOS allows local inspection.
- LaunchAgents and LaunchDaemons.
- Login Items and background services.
- Helper tools and privileged service metadata.
- Local file paths that can reveal installed apps or user-specific setup.

## Future Changes

Any future analytics, update checks, remote integrations, background agents, helper tools, or network features must be documented before release and reviewed for privacy impact.
