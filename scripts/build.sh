#!/bin/bash
set -euo pipefail

task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_arch="${1:-universal}"
case "$task_arch" in
    universal) task_arch_flags=(-arch arm64 -arch x86_64) ;;
    arm64|x86_64) task_arch_flags=(-arch "$task_arch") ;;
    *) printf 'Usage: %s [universal|arm64|x86_64]\n' "$0" >&2; exit 2 ;;
esac

task_sdk="$(xcrun --show-sdk-path)"
task_build="$task_root/build"
task_app="$task_build/屏幕模式切换.app"
task_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$task_root/resources/Info.plist")"
task_zip="ScreenModeSwitcher-v$task_version.zip"

mkdir -p "$task_app/Contents/MacOS" "$task_app/Contents/Resources"
cp "$task_root/resources/Info.plist" "$task_app/Contents/Info.plist"
cp "$task_root/LICENSE" "$task_app/Contents/Resources/LICENSE.txt"
plutil -lint "$task_app/Contents/Info.plist"

xcrun clang \
    -fobjc-arc -Wall -Wextra -Werror -O2 -g0 \
    -mmacosx-version-min=13.0 -isysroot "$task_sdk" \
    "-ffile-prefix-map=$task_root=." \
    "${task_arch_flags[@]}" \
    -framework Cocoa -framework QuartzCore -framework ServiceManagement \
    "$task_root/src/ScreenModeSwitcher.m" \
    -o "$task_app/Contents/MacOS/ScreenModeSwitcher"

# Local ad-hoc signing only: no Developer ID certificate or notarization.
codesign --force --sign - "$task_app"
codesign --verify --deep --strict --verbose=2 "$task_app"
ditto -c -k --sequesterRsrc --keepParent "$task_app" "$task_build/$task_zip"
(
    cd "$task_build"
    shasum -a 256 "$task_zip" > SHA256SUMS.txt
)
printf '\nApp: %s\nArchive: %s\n' "$task_app" "$task_build/$task_zip"
lipo -archs "$task_app/Contents/MacOS/ScreenModeSwitcher"
