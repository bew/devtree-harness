# Test suite for `devtree` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/devtree"

# Each test gets its own devtree root named `self` with the marker file
function setup() {
    DEVROOT="$BATS_TEST_TMPDIR/self"
    mkdir -p "$DEVROOT"
    touch "$DEVROOT/.devtree-root"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: prints the devtree name and path as JSON" {
    cd "$DEVROOT"

    run -0 "$SCRIPT_PATH" root --json

    [[ "$(jq -r '.name' <<< "$output")" == "self" ]]
    [[ "$(jq -r '.path' <<< "$output")" == "$(pwd -P)" ]]
}

@test "defaults: resolves the root from a nested subdirectory" {
    mkdir -p "$DEVROOT/group/repo"
    cd "$DEVROOT/group/repo"

    run -0 "$SCRIPT_PATH" root --json

    [[ "$(jq -r '.name' <<< "$output")" == "self" ]]
    [[ "$(jq -r '.path' <<< "$output")" == "$(cd "$DEVROOT" && pwd -P)" ]]
}

@test "defaults: emits valid single-line JSON" {
    cd "$DEVROOT"

    run -0 "$SCRIPT_PATH" root --json

    run -0 jq -e 'has("name") and has("path")' <<< "$output"
    [[ "$(printf '%s' "$output" | wc -l | tr -d ' ')" -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Tests: usage

@test "usage: --help lists the root subcommand" {
    run -0 "$SCRIPT_PATH" --help

    [[ "$output" == *"root"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: root without --json fails" {
    cd "$DEVROOT"

    run -1 --separate-stderr "$SCRIPT_PATH" root

    [[ "$stderr" == *"--json"* ]]
}

@test "error: fails when no devtree marker is found" {
    rm -f "$DEVROOT/.devtree-root"
    cd "$DEVROOT"

    run -1 --separate-stderr "$SCRIPT_PATH" root --json

    [[ "$stderr" == *".devtree-root"* ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: prefers the nearest devtree when markers are nested" {
    local inner="$DEVROOT/inner"
    mkdir -p "$inner/sub"
    touch "$inner/.devtree-root"
    cd "$inner/sub"

    run -0 "$SCRIPT_PATH" root --json

    [[ "$(jq -r '.name' <<< "$output")" == "inner" ]]
    [[ "$(jq -r '.path' <<< "$output")" == "$(cd "$inner" && pwd -P)" ]]
}
