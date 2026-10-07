# Test suite for `beads-devtree-init` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/beads-devtree-init"
EXP_PATH="$SCRIPT_DIR/test-fixtures/interactive.exp"

# Each test gets its own throwaway git repo under a devtree root
function setup() {
    TEST_REPO="$BATS_TEST_TMPDIR/repo"
    touch "$BATS_TEST_TMPDIR/.devtree-root"
}

# Create a git repo at $1 with user identity configured (no commits yet)
function setup_git_repo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
}

# Stage and commit everything in the repo at $1
function commit_all() {
    local repo="$1"
    git -C "$repo" add -A
    git -C "$repo" commit -q --allow-empty -m "initial"
}

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: initializes beads in the current directory" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    cd "$TEST_REPO"

    run -0 --separate-stderr "$SCRIPT_PATH"

    [[ -d ".beads" ]]
    [[ -f ".beads/metadata.json" ]]
    [[ -f ".beads/issues.jsonl" ]]
}

@test "defaults: stages only the wanted .beads files" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    cd "$TEST_REPO"

    run -0 "$SCRIPT_PATH"

    run -0 git diff --cached --name-only
    [[ "$output" == $'.beads/.gitignore\n.beads/README.md\n.beads/config.yaml\n.beads/issues.jsonl\n.beads/metadata.json' ]]
}

@test "defaults: does not create a commit" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    local before
    before="$(git -C "$TEST_REPO" rev-parse HEAD)"
    cd "$TEST_REPO"

    run -0 "$SCRIPT_PATH"

    [[ "$(git rev-parse HEAD)" == "$before" ]]
}

@test "defaults: keeps bd's ignore policy in .git/info/exclude" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    cd "$TEST_REPO"

    run -0 "$SCRIPT_PATH"

    [[ ! -e ".gitignore" ]]
    run -0 cat .git/info/exclude
    [[ "$output" == *".beads/"* ]]
}

@test "defaults: installs beads skills in-repo" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    cd "$TEST_REPO"

    run -0 "$SCRIPT_PATH"

    [[ -f ".agents/skills/repo-tasks/SKILL.md" ]]
    [[ -f ".agents/skills/repo-progress-work/SKILL.md" ]]
    run -0 git ls-files .agents/skills/repo-tasks/SKILL.md
    [[ -n "$output" ]]
}

# ------------------------------------------------------------------------------
# Tests: cli

@test "cli: --repo initializes the target repo" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -0 "$SCRIPT_PATH" --repo "$TEST_REPO"

    [[ -d "$TEST_REPO/.beads" ]]
}

@test "cli: forwards extra arguments after -- to bd init" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -1 --separate-stderr "$SCRIPT_PATH" --repo "$TEST_REPO" -- --definitely-not-a-bd-flag

    [[ "$stderr" == *"bd init failed"* ]]
}

@test "cli: --skills devtree installs skills at the devtree root" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -0 "$SCRIPT_PATH" --repo "$TEST_REPO" --skills devtree

    [[ -f "$BATS_TEST_TMPDIR/.agents/skills/repo-tasks/SKILL.md" ]]
    [[ ! -d "$TEST_REPO/.agents" ]]
}

@test "cli: --skills skip installs no skills" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -0 "$SCRIPT_PATH" --repo "$TEST_REPO" --skills skip

    [[ ! -d "$TEST_REPO/.agents" ]]
    [[ ! -d "$BATS_TEST_TMPDIR/.agents" ]]
}

@test "cli: installs skills from BEADS_DEVTREE_INIT_SKILLS when set" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    mkdir -p "$BATS_TEST_TMPDIR/skills/my-skill"
    echo "sentinel" > "$BATS_TEST_TMPDIR/skills/my-skill/SKILL.md"

    BEADS_DEVTREE_INIT_SKILLS="$BATS_TEST_TMPDIR/skills" run -0 "$SCRIPT_PATH" --repo "$TEST_REPO"

    [[ -f "$TEST_REPO/.agents/skills/my-skill/SKILL.md" ]]
}

@test "cli: --interactive prompts for the prefix and installs skills in-repo" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -0 expect -f "$EXP_PATH" "$SCRIPT_PATH" "$TEST_REPO" "mypref" "1"

    [[ -f "$TEST_REPO/.agents/skills/repo-tasks/SKILL.md" ]]
    cd "$TEST_REPO"
    run -0 bd config get issue_prefix
    [[ "$output" == *"mypref"* ]]
}

@test "cli: --interactive installs skills at the devtree when chosen" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -0 expect -f "$EXP_PATH" "$SCRIPT_PATH" "$TEST_REPO" "mypref" "2"

    [[ -f "$BATS_TEST_TMPDIR/.agents/skills/repo-tasks/SKILL.md" ]]
    [[ ! -d "$TEST_REPO/.agents" ]]
}

@test "cli: --interactive offers skip when skills already exist at the devtree" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    mkdir -p "$BATS_TEST_TMPDIR/.agents/skills/repo-tasks"
    mkdir -p "$BATS_TEST_TMPDIR/.agents/skills/repo-progress-work"

    run -0 expect -f "$EXP_PATH" "$SCRIPT_PATH" "$TEST_REPO" "mypref" "1"

    [[ ! -d "$TEST_REPO/.agents" ]]
}

@test "cli: --interactive skips the prefix prompt when --prefix is forwarded" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -0 expect -f "$EXP_PATH" "$SCRIPT_PATH" "$TEST_REPO" "" "1" --prefix forwarded

    cd "$TEST_REPO"
    run -0 bd config get issue_prefix
    [[ "$output" == *"forwarded"* ]]
}

# ------------------------------------------------------------------------------
# Tests: error

@test "error: rejects a nonexistent repo path" {
    run -1 --separate-stderr "$SCRIPT_PATH" --repo "$BATS_TEST_TMPDIR/nope"

    [[ "$stderr" == *"does not exist"* ]]
}

@test "error: rejects a non-git directory" {
    mkdir -p "$TEST_REPO"

    run -1 --separate-stderr "$SCRIPT_PATH" --repo "$TEST_REPO"

    [[ "$stderr" == *"not a git repository"* ]]
}

@test "error: refuses an already initialized repo" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    mkdir -p "$TEST_REPO/.beads"

    run -1 --separate-stderr "$SCRIPT_PATH" --repo "$TEST_REPO"

    [[ "$stderr" == *"already exists"* ]]
}

@test "error: fails when no devtree marker is found" {
    rm -f "$BATS_TEST_TMPDIR/.devtree-root"
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -1 --separate-stderr "$SCRIPT_PATH" --repo "$TEST_REPO"

    [[ "$stderr" == *".devtree-root"* ]]
}

@test "error: rejects an invalid --skills value" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -1 --separate-stderr "$SCRIPT_PATH" --repo "$TEST_REPO" --skills bogus

    [[ "$stderr" == *"invalid --skills"* ]]
}

@test "error: --interactive without a terminal fails" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"

    run -1 --separate-stderr "$SCRIPT_PATH" --repo "$TEST_REPO" --interactive

    [[ "$stderr" == *"requires a terminal"* ]]
}

# ------------------------------------------------------------------------------
# Tests: edge

@test "edge: preserves pre-existing staged changes" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    echo "hello" > "$TEST_REPO/staged.txt"
    git -C "$TEST_REPO" add staged.txt
    cd "$TEST_REPO"

    run -0 "$SCRIPT_PATH"

    run -0 git diff --cached --name-only
    [[ "$output" == *"staged.txt"* ]]
}

@test "edge: works in a repo with no commits" {
    setup_git_repo "$TEST_REPO"
    cd "$TEST_REPO"

    run -0 "$SCRIPT_PATH"

    [[ -d ".beads" ]]
    run -128 git rev-parse --verify HEAD
}

@test "edge: does not overwrite an existing in-repo skill" {
    setup_git_repo "$TEST_REPO"
    commit_all "$TEST_REPO"
    mkdir -p "$TEST_REPO/.agents/skills/repo-tasks"
    echo "sentinel" > "$TEST_REPO/.agents/skills/repo-tasks/SKILL.md"
    cd "$TEST_REPO"

    run -0 "$SCRIPT_PATH"

    run -0 cat ".agents/skills/repo-tasks/SKILL.md"
    [[ "$output" == "sentinel" ]]
}