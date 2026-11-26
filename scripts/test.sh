#!/usr/bin/env bash
# Builds and runs the tests, and prints only a short summary. The full output goes to the log.
#
# usage: scripts/test.sh [--changed] [filter ...]
#
#   (nothing)   every test
#   --changed   only the suites for the Swift files this branch changed, compared with main
#   filter      a swift test --filter pattern, such as ScreenshotsConfigTests
#
# Prints "All tests passed" when every test passes. Otherwise it prints one line for each
# build error or failed expectation, which is all a fix needs. It names the full log only when
# a run stops without saying why, such as a crash. Exits non-zero on any failure.
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=scripts/common.sh
source scripts/common.sh

LOG=".build/test.log"
TESTS="Tests/MalumCoreTests"

# Prints the suite name for a changed Swift file, if that suite exists.
_suite_for() {
    local name
    name="$(basename "$1" .swift)"
    name="${name%%+*}"
    name="${name%Tests}Tests"
    [[ -f "$TESTS/$name.swift" ]] && printf '%s\n' "$name"
    return 0
}

# Adds one filter for each suite that covers a file this branch changed.
_changed_filters() {
    local file
    local suites
    suites="$(_changed_swift_files Sources Tests | while read -r file; do _suite_for "$file"; done | sort -u)"
    [[ -n "$suites" ]] || { printf '%s\n' "No tests cover the changed files"; exit 0; }
    local suite
    for suite in $suites; do
        FLAGS_FILTER+=(--filter "\\.$suite/")
    done
}

# Turns one "Test x() recorded an issue at File.swift:12:5: message" line into "x() at File.swift:12: message".
_issue_line() {
    local line="$1"
    local test="${line#*Test }"
    test="${test%% recorded an issue*}"
    local rest="${line#* recorded an issue}"
    local place
    place="$(printf '%s\n' "$rest" | sed -nE 's/^.* at ([^ ]+\.swift):([0-9]+):[0-9]+: (.*)$/ at \1:\2: \3/p')"
    [[ -n "$place" ]] && { printf '%s\n' "  $test$place"; return; }
    printf '%s\n' "  $test: ${rest#*: }"
}

# Prints the summary of a test run that ended with a failure.
_report_tests() {
    local status="$1"
    local summary
    summary="$(grep -E 'Test run with [0-9]+ tests? ' "$LOG" | tail -n 1)" || true
    [[ -n "$summary" ]] || {
        printf '%s\n' "Tests stopped early (exit $status). Last lines:"
        tail -n 5 "$LOG"
        printf '%s\n' "Full log: $LOG"
        return
    }
    local total
    total="$(printf '%s\n' "$summary" | sed -E 's/.*Test run with ([0-9]+) tests?.*/\1/')"
    local failed
    failed="$(grep -E 'Test .+ failed after ' "$LOG" | grep -vc 'Test run with ')" || true
    printf '%s\n' "All tests ran: $failed of $total failed"
    local line
    grep -F ' recorded an issue' "$LOG" | while IFS= read -r line; do _issue_line "$line"; done
}

# Reports a passing run, or a filter that matched nothing.
_report_pass() {
    grep -qE 'Test run with 0 tests ' "$LOG" && { printf '%s\n' "No tests matched the filter"; return; }
    printf '%s\n' "All tests passed"
}

FLAGS=()
FLAGS_FILTER=()
_toolchain_flags

for ARGUMENT in "$@"; do
    case "$ARGUMENT" in
        --changed) _changed_filters ;;
        *) FLAGS_FILTER+=(--filter "$ARGUMENT") ;;
    esac
done

mkdir -p .build
: > "$LOG"

swift build --build-tests ${FLAGS[@]+"${FLAGS[@]}"} >> "$LOG" 2>&1 || { _report_problems "$LOG" "Build failed:"; exit 1; }

STATUS=0
swift test --skip-build ${FLAGS[@]+"${FLAGS[@]}"} ${FLAGS_FILTER[@]+"${FLAGS_FILTER[@]}"} >> "$LOG" 2>&1 || STATUS=$?

((STATUS == 0)) || { _report_tests "$STATUS"; exit "$STATUS"; }
_report_pass
