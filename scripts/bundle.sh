#!/bin/bash
# Builds Malum.app from the release executable and Resources/Info.plist.
#
# usage: scripts/bundle.sh [output folder]   (default: build)
#
# The name, bundle ID, executable and version come from Project.swift. The bundle is signed
# ad hoc; Malum signs its own copy with its local certificate when it installs it.
set -euo pipefail

cd "$(dirname "$0")/.."

project="Sources/MalumCore/Project.swift"
output="${1:-build}"

# Reads `public static let <key> = "<value>"` from Project.swift.
value() {
    local found
    found="$(sed -nE "s/^[[:space:]]*public static let $1 = \"(.*)\"$/\1/p" "$project")"
    if [ -z "$found" ]; then
        echo "[error] couldn't read $1 from $project" >&2
        exit 1
    fi
    printf '%s' "$found"
}

name="$(value name)"
bundle_id="$(value bundleID)"
version="$(value version)"
executable="$name"
app="$output/$name.app"

swift build -c release --arch arm64 --product "$executable"
bin="$(swift build -c release --arch arm64 --show-bin-path)/$executable"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/$executable"

plist="$app/Contents/Info.plist"
cp Resources/Info.plist "$plist"
plutil -insert CFBundleName -string "$name" "$plist"
plutil -insert CFBundleExecutable -string "$executable" "$plist"
plutil -insert CFBundleIdentifier -string "$bundle_id" "$plist"
plutil -insert CFBundleShortVersionString -string "$version" "$plist"
plutil -insert CFBundleVersion -string "$version" "$plist"
plutil -lint "$plist"

codesign --force --sign - --identifier "$bundle_id" "$app"
codesign --verify --strict "$app"

echo "[info] built $app ($version)"
