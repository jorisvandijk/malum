#!/usr/bin/env bash
# Builds and lints like CI does, and prints only the problems. The full output goes to the logs.
#
# usage: scripts/check.sh [--changed] [build] [lint] [duplicates]
#
#   (no step)   every step: build, lint, duplicates
#   build       swift build
#   lint        swift-format and SwiftLint, both --strict
#   duplicates  jscpd over Sources, with the settings and version CI uses
#   --changed   lint only the Swift files this branch changed, compared with main, and skip
#               duplicates when Sources didn't change
#
# Prints "All checks passed" when every step passes. Otherwise it prints each failed step with one
# line per problem. A step whose tool isn't installed is skipped and says so. Exits non-zero on
# any failure.
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=scripts/common.sh
source scripts/common.sh

LOGS=".build"
LINT_PATHS=(Package.swift Sources Tests)
DUPLICATES_PATH="Sources"
WORKFLOW=".github/workflows/test.yml"
JSCPD_MIN_TOKENS=60

# Prints the files lint should check: the changed ones that still exist, or nothing for all.
_lint_files() {
    [[ "$CHANGED" == true ]] || return 0
    local file
    _changed_swift_files "${LINT_PATHS[@]}" | while read -r file; do
        [[ -f "$file" ]] && printf '%s\n' "$file"
    done
    return 0
}

_build() {
    local log="$LOGS/check-build.log"
    FLAGS=()
    _toolchain_flags
    swift build ${FLAGS[@]+"${FLAGS[@]}"} > "$log" 2>&1 && return 0
    _report_problems "$log" "Build failed:"
    return 1
}

_lint() {
    local files=()
    local file
    while read -r file; do files+=("$file"); done < <(_lint_files)
    [[ "$CHANGED" == true && ${#files[@]} -eq 0 ]] && { printf '%s\n' "Lint: no changed Swift files"; return 0; }
    local status=0
    _swift_format ${files[@]+"${files[@]}"} || status=1
    _swiftlint ${files[@]+"${files[@]}"} || status=1
    return "$status"
}

_swift_format() {
    local log="$LOGS/check-format.log"
    local targets=("$@")
    ((${#targets[@]} > 0)) || targets=(--recursive "${LINT_PATHS[@]}")
    swift format lint --strict "${targets[@]}" > "$log" 2>&1 && return 0
    _report_problems "$log" "swift-format failed:"
    return 1
}

_swiftlint() {
    command -v swiftlint > /dev/null || { printf '%s\n' "SwiftLint: not installed, skipped"; return 0; }
    local log="$LOGS/check-swiftlint.log"
    local targets=()
    (($# > 0)) && targets=(--force-exclude "$@")
    swiftlint lint --strict --quiet ${targets[@]+"${targets[@]}"} > "$log" 2>&1 && return 0
    _report_problems "$log" "SwiftLint failed:"
    return 1
}

_duplicates() {
    command -v npx > /dev/null || { printf '%s\n' "Duplicates: npx not installed, skipped"; return 0; }
    [[ "$CHANGED" == true && -z "$(_changed_swift_files "$DUPLICATES_PATH")" ]] && return 0
    local log="$LOGS/check-duplicates.log"
    local version
    version="$(sed -nE 's/^ *JSCPD_VERSION: "([^"]+)".*/\1/p' "$WORKFLOW")"
    [[ -n "$version" ]] || { printf '%s\n' "Duplicates: no JSCPD_VERSION in $WORKFLOW"; return 1; }
    npx --yes "jscpd@$version" --min-tokens "$JSCPD_MIN_TOKENS" --threshold 0 "$DUPLICATES_PATH" > "$log" 2>&1 \
        && return 0
    _report_clones "$log"
    return 1
}

# Prints each clone jscpd found: its header and the two places, without colors.
_report_clones() {
    local log="$1"
    local clones
    clones="$(sed -E 's/\x1b\[[0-9;]*m//g' "$log" | grep -E 'Clone found|\[[0-9]+:[0-9]+ - [0-9]+:[0-9]+\]')" || true
    printf '%s\n' "Duplicates failed:"
    [[ -n "$clones" ]] || { tail -n 5 "$log"; printf '%s\n' "Full log: $log"; return; }
    printf '%s\n' "$clones" | head -n "$MAX_PROBLEMS"
}

CHANGED=false
STEPS=()
for ARGUMENT in "$@"; do
    case "$ARGUMENT" in
        --changed) CHANGED=true ;;
        build | lint | duplicates) STEPS+=("$ARGUMENT") ;;
        *) printf '%s\n' "Unknown argument: $ARGUMENT" "usage: scripts/check.sh [--changed] [build] [lint] [duplicates]" >&2; exit 2 ;;
    esac
done
((${#STEPS[@]} > 0)) || STEPS=(build lint duplicates)

mkdir -p "$LOGS"
FAILED=0
for STEP in "${STEPS[@]}"; do
    "_$STEP" || FAILED=1
done

((FAILED == 0)) || exit 1
printf '%s\n' "All checks passed"
