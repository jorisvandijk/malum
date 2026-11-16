#!/bin/bash
# Builds Malum.app from the release executable, Resources/Info.plist and Resources/Bundle.
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
web_app="${name}WebApp"
app="$output/$name.app"

# rcodesign signs Malum with its own key file, so Malum never needs the keychain. A pinned
# release, checked against its SHA-256, goes in Contents/Helpers with its licence.
rcodesign_version="0.29.0"
rcodesign_sha256="d98372d5524226ccf9dc0eda03d4e4f5826182dabb2fc3f2bd303ed9113a748d"
rcodesign_name="apple-codesign-$rcodesign_version-macos-universal"
rcodesign_url="https://github.com/indygreg/apple-platform-rs/releases/download/apple-codesign%2F$rcodesign_version/$rcodesign_name.tar.gz"
downloads="$output/downloads"
rcodesign_archive="$downloads/$rcodesign_name.tar.gz"
mkdir -p "$downloads"
if ! printf '%s  %s\n' "$rcodesign_sha256" "$rcodesign_archive" | shasum -a 256 -c -s 2>/dev/null; then
    curl -fsSL -o "$rcodesign_archive" "$rcodesign_url"
    printf '%s  %s\n' "$rcodesign_sha256" "$rcodesign_archive" | shasum -a 256 -c -s
fi
tar -xzf "$rcodesign_archive" -C "$downloads"

swift build -c release --arch arm64 --product "$executable"
swift build -c release --arch arm64 --product "$web_app"
bin="$(swift build -c release --arch arm64 --show-bin-path)"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$app/Contents/Helpers"
cp "$bin/$executable" "$app/Contents/MacOS/$executable"
# The web app every site in webapps.toml becomes a copy of. Nested code is signed before the app.
cp "$bin/$web_app" "$app/Contents/Helpers/$web_app"
codesign --force --sign - "$app/Contents/Helpers/$web_app"
cp "$downloads/$rcodesign_name/rcodesign" "$app/Contents/Helpers/rcodesign"
cp "$downloads/$rcodesign_name/COPYING" "$app/Contents/Resources/rcodesign-COPYING"
cp Resources/Bundle/* "$app/Contents/Resources/"

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
