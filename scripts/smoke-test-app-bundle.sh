#!/usr/bin/env bash
set -euo pipefail

app_bundle="${APP_BUNDLE:-.build/app/PermissionPilot.app}"
app_name="PermissionPilot"
crash_dir="$HOME/Library/Logs/DiagnosticReports"
start_time="$(date +%s)"

if [[ ! -d "$app_bundle" ]]; then
  echo "App bundle not found at $app_bundle. Building it first."
  bash scripts/build-app-bundle.sh
fi

if ! command -v osascript >/dev/null 2>&1; then
  echo "osascript is required for this smoke test." >&2
  exit 1
fi

open "$app_bundle"

for _ in {1..30}; do
  if pgrep -x "$app_name" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! pgrep -x "$app_name" >/dev/null 2>&1; then
  echo "$app_name did not start." >&2
  exit 1
fi

sleep 2

osascript <<'APPLESCRIPT' >/dev/null
tell application "PermissionPilot" to activate
delay 1
tell application "System Events"
  tell process "PermissionPilot"
    set clickedRefresh to false
    repeat with menuBarItem in menu bar items of menu bar 1
      try
        if exists menu item "Refresh Scan" of menu 1 of menuBarItem then
          click menu item "Refresh Scan" of menu 1 of menuBarItem
          set clickedRefresh to true
          exit repeat
        end if
      end try
    end repeat

    if clickedRefresh is false then
      error "Refresh Scan menu item was not found."
    end if
  end tell
end tell
APPLESCRIPT

sleep 3

if ! pgrep -x "$app_name" >/dev/null 2>&1; then
  echo "$app_name exited after Refresh Scan." >&2
  exit 1
fi

recent_crashes=0
if [[ -d "$crash_dir" ]]; then
  recent_crashes="$(
    { find "$crash_dir" -name 'PermissionPilot*.crash' -type f -newermt "@$start_time" 2>/dev/null || true; } | wc -l | tr -d ' '
  )"
fi

osascript <<'APPLESCRIPT' >/dev/null
tell application "PermissionPilot" to quit
APPLESCRIPT

for _ in {1..10}; do
  if ! pgrep -x "$app_name" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if pgrep -x "$app_name" >/dev/null 2>&1; then
  echo "$app_name did not quit cleanly." >&2
  exit 1
fi

if [[ "$recent_crashes" != "0" ]]; then
  echo "Found $recent_crashes recent PermissionPilot crash report(s)." >&2
  exit 1
fi

echo "PermissionPilot app bundle smoke test passed."
