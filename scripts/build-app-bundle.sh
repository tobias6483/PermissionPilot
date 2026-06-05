#!/usr/bin/env bash
set -euo pipefail

configuration="${CONFIGURATION:-release}"
app_name="PermissionPilot"
executable_name="PermissionPilot"
bundle_id="${BUNDLE_ID:-io.github.tobias6483.PermissionPilot}"
version="${VERSION:-0.1.0}"
build_number="${BUILD_NUMBER:-1}"
minimum_system_version="${MACOSX_DEPLOYMENT_TARGET:-14.0}"
output_root="${OUTPUT_ROOT:-.build/app}"
app_bundle="$output_root/$app_name.app"
contents_dir="$app_bundle/Contents"
macos_dir="$contents_dir/MacOS"
plist_path="$contents_dir/Info.plist"

if [[ "$configuration" != "debug" && "$configuration" != "release" ]]; then
  echo "CONFIGURATION must be 'debug' or 'release'." >&2
  exit 1
fi

swift_build_args=()
if [[ "$configuration" == "release" ]]; then
  swift_build_args+=("--configuration" "release")
fi

swift build "${swift_build_args[@]}"
binary_dir="$(swift build "${swift_build_args[@]}" --show-bin-path)"
binary_path="$binary_dir/$executable_name"

if [[ ! -x "$binary_path" ]]; then
  echo "Built executable not found at $binary_path" >&2
  exit 1
fi

rm -rf "$app_bundle"
mkdir -p "$macos_dir"
install -m 0755 "$binary_path" "$macos_dir/$executable_name"

cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$app_name</string>
  <key>CFBundleExecutable</key>
  <string>$executable_name</string>
  <key>CFBundleIdentifier</key>
  <string>$bundle_id</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$app_name</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$version</string>
  <key>CFBundleVersion</key>
  <string>$build_number</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$minimum_system_version</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticTermination</key>
  <true/>
  <key>NSSupportsSuddenTermination</key>
  <true/>
</dict>
</plist>
EOF

plutil -lint "$plist_path" >/dev/null

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$app_bundle"
  codesign --verify --deep --strict --verbose=2 "$app_bundle"
  echo "Built and signed $app_bundle"
else
  echo "Built unsigned app bundle at $app_bundle"
  echo "Set CODESIGN_IDENTITY to sign the bundle."
fi
