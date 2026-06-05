#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "README.md"
  "LICENSE"
  "Package.swift"
  "CONTRIBUTING.md"
  "SECURITY.md"
  "PRIVACY.md"
  "SUPPORT.md"
  "CODE_OF_CONDUCT.md"
  "ROADMAP.md"
  "CHANGELOG.md"
  "AGENTS.md"
  ".gitignore"
  ".editorconfig"
  "scripts/build-app-bundle.sh"
  ".github/pull_request_template.md"
  ".github/ISSUE_TEMPLATE/bug_report.yml"
  ".github/ISSUE_TEMPLATE/feature_request.yml"
  ".github/ISSUE_TEMPLATE/privacy_review.yml"
  ".github/ISSUE_TEMPLATE/config.yml"
  ".github/workflows/ci.yml"
  "Sources/PermissionPilotApp/CodeSignatureScanner.swift"
  "Sources/PermissionPilotApp/PermissionPilotApp.swift"
  "Sources/PermissionPilotApp/TCCDatabaseScanner.swift"
  "Tests/PermissionPilotTests/BackgroundItemScannerTests.swift"
  "Tests/PermissionPilotTests/CodeSignatureScannerTests.swift"
  "Tests/PermissionPilotTests/InstalledAppTests.swift"
  "Tests/PermissionPilotTests/ReportExporterTests.swift"
  "Tests/PermissionPilotTests/TCCDatabaseScannerTests.swift"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

if ! git check-ignore -q project.md; then
  echo "project.md must remain ignored by git" >&2
  exit 1
fi

if grep -q "## Planned MVP" README.md; then
  echo "README.md should describe the implemented v0.1 MVP, not a planned MVP." >&2
  exit 1
fi

if grep -q "| .* | Partial |" docs/requirements.md; then
  echo "docs/requirements.md should not mark v0.1 MVP requirements as Partial." >&2
  exit 1
fi

echo "Repository foundation checks passed."
