# Contributing

Thanks for helping make macOS permissions easier to understand.

## Development Setup

The first SwiftUI app scaffold has not been added yet. Until then, contributors should use the repository checks:

```sh
bash scripts/check-repo.sh
```

When the app scaffold lands, this document will be updated with Xcode, build, test, and manual QA commands.

## Project Principles

- Keep the app local-first.
- Be clear about what macOS allows the app to inspect.
- Prefer educational language over fear-driven warnings.
- Do not add telemetry by default.
- Treat permission, identity, file-system, and background-service data as sensitive.
- Keep the UI native, direct, and useful for repeated inspection.

## Pull Requests

Pull requests should include:

- A concise summary.
- Local checks run.
- Manual QA notes for macOS permission or System Settings behavior.
- Privacy and security impact notes for permission-sensitive changes.

Agent-created pull requests should use a branch-based workflow and prefer squash merge after checks pass.

## Issues

Please use the issue templates when possible. Avoid posting secrets, private app inventories, device identifiers, or full permission exports in public issues.

