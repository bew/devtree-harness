# Beads `bd init` — Complaints & Desired Behavior

This document records what the stock `bd init` does wrong in this devtree, and what `beads-devtree-init` must do instead.
`beads-devtree-init` is a narrow wrapper around `bd init` that performs beads setup for a devtree project.
Status: draft — complaints and desired behavior captured; wrapper design and the beads text added to `AGENTS.md` are not settled yet.

## Context

Observed on `bd` 1.0.3 (dev), run once in `devtree-harness`.
The harness is human-first: every capability must work manually, and agent support is a layer on top (see README).
Agents here are not fully autonomous: they run task-scoped, and never commit or push unless a dedicated agent is configured for it.
`bd init` instead assumes a Claude Code surface and an autonomous, always-pushing workflow, which does not match this devtree.

## Complaints

The complaints fall into several themes:
- unwanted generated files
- mandates injected into agent instructions
- unsolicited git mutations
- and a lack of control at init time

### Unwanted generated files

- `bd init` created `CLAUDE.md`, a full agent-instructions file specific to Claude Code.
- It created `.claude/settings.json`, wiring `bd prime` into Claude Code's `SessionStart` and `PreCompact` hooks.
- Neither is used here: the harness drives opencode, which reads `AGENTS.md`, not `CLAUDE.md` or `.claude/`.
- `CLAUDE.md` also ships placeholder template sections (`Build & Test`, `Architecture Overview`, `Conventions & Patterns`) that add nothing.
- It created a new root `.gitignore` (with a leading blank line) holding beads ignore rules, instead of leaving ignore policy to the harness.

### AGENTS.md injection

- `bd init` appended a `BEADS INTEGRATION` block to `AGENTS.md`, between marker comments.
- The block mandates `bd` for all task tracking and forbids other task tools.
- It prescribes a session-completion workflow ending in `git push`, via `git pull --rebase`, `bd dolt push`, then `git push`.
- It frames this as a `MANDATORY WORKFLOW` with `CRITICAL RULES`, including that work is not complete until `git push` succeeds.
- None of this matches how agents are used here: autonomy is opt-in per agent config, and commit/push is never a repo-level instruction.
- The push-centric framing also conflicts with the human-first constraint, where a human decides what leaves the machine.

### Git hooks

- `bd init` set repo-local `core.hooksPath` to `.beads/hooks`, taking over all git hooks.
- It installed shims for `pre-commit`, `prepare-commit-msg`, `post-checkout`, `post-merge`, and `pre-push`.
- Each shim calls `bd hooks run <name>`, so every git action spawns a full `bd` process.
- `pre-commit` additionally exports the issue database to `.beads/issues.jsonl` and tries to `git add` it.
- Effect: `git commit` is noticeably slower; `bd hooks run pre-commit` measured at ~5s on an empty database.
- Whether hook takeover is wanted at all is unresolved: it is on by default, with no prompt.

### Automatic commit

- `bd init` committed its own output to the repository, without being asked.
- The commit was `bd init: initialize beads issue tracking`, 13 files and +483 lines, including `AGENTS.md` edits and the Claude/hook artifacts.
- It had to be removed manually with `git reset @^` to see the changes again.
- Silently rewriting history is the worst version of the control problem: the user cannot review the init as a working-tree diff.
- Nothing in the tool name or docs signals that init will commit.

### Lack of control

- `bd init` generates agent files, Claude settings, git hooks, and ignore rules by default, with no dry-run.
- It offers no preview or manifest of what it will create or modify before doing it.
- Declining any of it requires knowing the relevant flags in advance (`--skip-agents`, `--skip-hooks`, `--agents-profile`, ...).
- Its `AGENTS.md` edit is an in-place append, so it is hard to review as a discrete change.

## Desired behavior

`beads-devtree-init` must produce only what the harness wants, and make the rest an explicit choice.
An earlier `repo-init` step creates the initial `AGENTS.md`, and other steps will edit it too; this wrapper only adds its own beads content to a file that already exists.

- Drive `bd init` with flags rather than accepting its defaults.
- Suppress agent/Claude artifact generation with `--skip-agents`.
- If agent awareness is kept at all, control it precisely via `--agents-file`, `--agents-profile`, or `--agents-template`, instead of the default block.
- Never create `CLAUDE.md` or `.claude/` in these repos; opencode is the agent surface.
- Never inject task-tracking mandates or commit/push workflows into a repo's `AGENTS.md`.
- Treat git-hook installation as opt-in, not default; if enabled, keep `pre-commit` cheap enough not to slow commits.
- Make init inspectable and safe to re-run: a dry-run or manifest before writing, and idempotent behavior.
- Never create a commit itself; leave staging and committing to the user, keeping init results as reviewable working-tree changes.
- Treat committing as out of scope: whether the surrounding orchestration makes a commit is not this wrapper's concern.
- Leave ignore policy to the harness rather than dropping a fresh `.gitignore`.

## Open questions

- Wrapper home and name for `beads-devtree-init`, and how it is invoked from the broader init sequence (described in README).
- Git hooks: disable entirely, or keep a reduced set; if reduced, what stays and how commit cost is kept low.
- What `beads-devtree-init` adds to `AGENTS.md` (deferred until this doc is complete): a custom minimal block via `--agents-template`, or no beads text at all.
- Keep or drop the root `.gitignore` lines that `bd init` added.
- How to stop the auto-commit: is there a `bd init` flag or config, or must the wrapper reset it after the fact?
- Whether any complaint should go upstream to beads, e.g. the `pre-commit` `git add` failure when the export yields zero issues.
- Whether hook slowness is worth a separate performance follow-up, and what form it takes.
