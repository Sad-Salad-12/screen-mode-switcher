#!/bin/bash
set -euo pipefail

task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_sdk="$(xcrun --show-sdk-path)"
mkdir -p "$task_root/build"
xcrun clang \
    -fobjc-arc -Wall -Wextra -Werror -O0 \
    -mmacosx-version-min=13.0 -isysroot "$task_sdk" \
    "-ffile-prefix-map=$task_root=." \
    -framework Cocoa -framework QuartzCore -framework ServiceManagement \
    "$task_root/tests/AuthorizationSmokeTests.m" \
    -o "$task_root/build/AuthorizationSmokeTests"
"$task_root/build/AuthorizationSmokeTests"
