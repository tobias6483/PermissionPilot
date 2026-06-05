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
  ".github/pull_request_template.md"
  ".github/ISSUE_TEMPLATE/bug_report.yml"
  ".github/ISSUE_TEMPLATE/feature_request.yml"
  ".github/ISSUE_TEMPLATE/privacy_review.yml"
  ".github/ISSUE_TEMPLATE/config.yml"
  ".github/workflows/ci.yml"
  "Sources/PermissionPilotApp/PermissionPilotApp.swift"
  "Tests/PermissionPilotTests/ReportExporterTests.swift"
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

echo "Repository foundation checks passed."
