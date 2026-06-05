# Development

PermissionPilot is currently in repository setup.

## Current Check

```sh
bash scripts/check-repo.sh
```

## Planned App Workflow

The first implementation milestone should add:

- A native SwiftUI macOS app scaffold.
- Documented Xcode version.
- Build command.
- Unit test command.
- Manual QA checklist for System Settings deep links and permission visibility.

## Local Planning

`project.md` is intentionally ignored by git and should not be referenced by public docs.

## Platform Caveats

macOS intentionally restricts access to some privacy databases and permission states. PermissionPilot should explain limitations instead of pretending to see more than the OS allows.

