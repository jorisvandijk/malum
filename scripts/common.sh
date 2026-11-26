#!/usr/bin/env bash
# Helpers that scripts/test.sh and scripts/check.sh share. Source it; don't run it.

BASE_BRANCH="main"

# Adds the flags a Mac with only the Command Line Tools needs to find the Testing framework.
_toolchain_flags() {
    command -v xcode-select > /dev/null || return 0
    local developer
    developer="$(xcode-select -p 2> /dev/null)" || return 0
    [[ "$developer" == *CommandLineTools* ]] || return 0
    local frameworks="$developer/Library/Developer/Frameworks"
    local libraries="$developer/Library/Developer/usr/lib"
    FLAGS+=(-Xswiftc -F -Xswiftc "$frameworks" -Xlinker -rpath -Xlinker "$frameworks")
    [[ -d "$libraries" ]] && FLAGS+=(-Xlinker -rpath -Xlinker "$libraries")
    return 0
}

# Prints the Swift files this branch changed, compared with main, plus new untracked ones.
# Deleted files are listed too; callers that need the file itself check that it exists.
_changed_swift_files() {
    local base
    base="$(git merge-base HEAD "origin/$BASE_BRANCH" 2> /dev/null || git merge-base HEAD "$BASE_BRANCH")"
    { git diff --name-only "$base" -- "$@"; git ls-files --others --exclude-standard -- "$@"; } \
        | { grep '\.swift$' || true; } \
        | sort -u
}

MAX_PROBLEMS=20

# Prints a title and the "path:line:col: error|warning: message" lines in a log, once each, with
# paths relative to the repo. Build errors, swift-format and SwiftLint all use that shape. Names
# the log only when it holds no such line.
_report_problems() {
    local log="$1"
    local title="$2"
    local problems
    problems="$(grep -E ': (error|warning): ' "$log" | sed "s|^$PWD/||" | awk '!seen[$0]++')" || true
    printf '%s\n' "$title"
    [[ -n "$problems" ]] || { tail -n 5 "$log"; printf '%s\n' "Full log: $log"; return; }
    local count
    count="$(printf '%s\n' "$problems" | wc -l | tr -d ' ')"
    printf '%s\n' "$problems" | head -n "$MAX_PROBLEMS"
    ((count > MAX_PROBLEMS)) && printf '%s\n' "...and $((count - MAX_PROBLEMS)) more"
    return 0
}
