# PermissionPilot Agent Instructions

These instructions apply to agents working in this repository and take precedence over the global machine-level instructions.

## Repository Facts

- Project: PermissionPilot.
- Platform target: native macOS app.
- Planned stack: SwiftUI and Swift.
- Default branch: `main`.
- Current state: repository foundation; app scaffold not yet implemented.
- Local planning notes: `project.md` is local-only and must remain ignored by git.

## Required Checks

Run this before reporting setup or documentation changes complete:

```sh
bash scripts/check-repo.sh
```

When the SwiftUI app scaffold exists, update this file with the required build and test commands.

## Workflow

- Keep public docs suitable for an open-source repository.
- Do not publish local-only planning notes.
- Prefer branch-based changes when a remote is configured.
- Do not force push shared branches.
- Stage only files relevant to the current task.

## Privacy And Security

PermissionPilot is permission-sensitive software. Any change involving TCC data, app inventories, file-system scanning, background services, helper tools, exports, networking, analytics, or privileged operations needs explicit privacy and security notes in the pull request.

The app should stay local-first unless a future change is deliberately reviewed and documented.

