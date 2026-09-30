# [READY] wk — Personal devtree-aware work management frontend

## Introduction

This spec defines `wk`, the personal work frontend for the devtree harness.
`wk` is the in-project form, `wkg` the cross-devtree form, and `wkt` the in-devtree form.

The trio renames the harness's in-project, cross-devtree, and in-devtree task commands to short work-named binaries.

The premise is that users should type task commands, not database commands.
Upstream beads `bd` is an implementation detail: it is not on `PATH` and is only ever reached through the trio.

`wk` runs the `wk` wrapper, which attaches the per-devtree shared Dolt server and applies the `:scope` rewrite before invoking the bundled `bd`.

This spec covers only what is specific to the frontend surface.

Routing target grammar and the `wkg`/`wkt` delegation mechanism are owned by `_SPECS/cross-devtree-task-routing/SPEC.md`.
The `:scope` syntax and its translation table are owned by `_SPECS/task-scopes/SPEC.md`.
Neither is re-specified here.

## Naming & IDs

The frontend exposes three binaries:

- `wk` — work. The in-project form.
- `wkg` — work-global. The cross-devtree form.
- `wkt` — work-devtree. The in-devtree form.

The names map one-to-one onto the harness task commands they replace: `wk` to the in-project command, `wkg` to the cross-devtree command, and `wkt` to the in-devtree command.
There are no aliases and no back-compatibility shims: no scripts or habits depend on the old names.

The `wk` wrapper is what `wk` runs.
It fronts the bundled upstream beads `bd`: it attaches the per-devtree shared Dolt server and applies the `:scope` rewrite, then invokes `bd` with the resulting arguments.

Upstream `bd` is only ever reached through the `wk` wrapper.

The implementation directory is `wk-beads-wrappers/`.

## Interface / How to use

Run `wk` from inside a project for in-project tasks.
Run `wkt <target>` for tasks elsewhere in the same devtree.
Run `wkg <target>` for tasks across devtrees.

The `<target>` grammar and the `wkg`/`wkt` resolution-and-delegation mechanism are specified in `_SPECS/cross-devtree-task-routing/SPEC.md`.
The `:scope` segment and its translation are specified in `_SPECS/task-scopes/SPEC.md`.

Both are referenced here, not restated.

Examples:

- `wk ready` — list ready tasks in the current project.
- `wk create --title="fix the thing" --type=bug` — create a task in the current project.
- `wkt ghh list` — list tasks in project `ghh` in the current devtree.
- `wkg self:ghh ready` — list ready tasks in project `ghh` of devtree `self`.
- `wk :auth list` — list tasks in scope `auth`.
- `wk init` — bootstrap the current project (see `wk init`).

### Open Questions

**Other intercepted verbs** — Whether `wk` should intercept any verb besides `init`.
Non-blocking. Currently none: every verb except `init` is forwarded to the wrapped `bd`.

## Packaging & `bd` Bundling

The trio ships as a single Nix package that provides `wk`, `wkg`, and `wkt` on `PATH`.
Upstream beads `bd` is not exposed on `PATH`; it is bundled inside the same closure.

The user only ever types `wk`, `wkg`, or `wkt`.

The binaries are built from the Rust source in `wk-beads-wrappers/` and wired into `flake.nix`, alongside the bundled `bd`.
`wkg` and `wkt` resolve their target, change directory, and exec `wk` — a sibling binary from the same closure — forwarding the remaining arguments.

Exec'ing `wk` from the resolved directory is what lets the target devtree's shared Dolt server be started and attached.
This mirrors the shared-server mechanism described in `HANDOFF-20260920-beads-shared-server-devtree.md`.

## `wk init`

`wk init` intercepts the `init` verb to run the harness-safe devtree bootstrap, replacing `bd init`.
It is the one deliberate exception to passthrough: `init` is not forwarded to the wrapped `bd`.

The behavior is that of the existing `beads-devtree-init` tool, reimplemented in Rust in `wk-beads-wrappers/`:

- Resolves the current git repository (including worktrees) and walks up for the `.devtree-root` marker.
- Refuses to run if `.beads/` already exists.
- Runs `bd init --stealth --skip-agents --skip-hooks` (plus `--non-interactive`, and an optional `--prefix`).
- Undoes beads' automatic commit via a soft reset, then force-adds the tracked beads files (`.beads/.gitignore`, `README.md`, `config.yaml`, `metadata.json`, `issues.jsonl`).
- Installs the packaged beads skills, honoring the in-repo / devtree / skip choice.

### Open Questions

**Relationship to a future `repo-init`** — Whether `wk init` eventually becomes one step of the generic `repo-init` devtree wrapper noted as a gap in `README.md`.
Non-blocking. `wk init` is specified here as a standalone command.

## Spec Amendments

Linking this frontend into the existing specs required the following edits, now applied:

- `_SPECS/cross-devtree-task-routing/SPEC.md`: renamed the user-facing entry points `bdg`/`bdt` to `wkg`/`wkt`, replaced the "exec `bd` from `PATH`" clause with exec'ing `wk`, and pointed its out-of-scope `bd`-wrapper item at this spec.
- `_SPECS/task-scopes/SPEC.md`: answered Global Open Question #1 as yes — the frontend supersedes the `:scope` wrapper syntax at the surface — and replaced the "a separate `wk` binary is out of scope" note, which was stale.

The routing and scope semantics themselves are unchanged.

## Placement / Scope

The implementation lives in `wk-beads-wrappers/`, replacing the standalone `tooling/beads-devtree-init/` package.
It is written in Rust, departing from the Python used by the rest of the harness tooling.

In scope:

- The naming and surface of the `wk`/`wkg`/`wkt` trio.
- Bundling `bd` inside the trio's closure, off `PATH`.
- The `wk` wrapper: shared-server attach plus the `:scope` rewrite.
- `wk init`, the intercepted bootstrap.

Out of scope:

- Routing target grammar and the `wkg`/`wkt` resolution-and-delegation mechanism — owned by `_SPECS/cross-devtree-task-routing/SPEC.md`.
- `:scope` syntax and its translation table — owned by `_SPECS/task-scopes/SPEC.md`.
- Upstream beads `bd` behavior, and cross-project aggregation.

## Alternatives & Tradeoffs

**Keep upstream `bd` on `PATH`, no trio.**
This is the simplest option: nothing to build, and users keep typing `bd` directly.
It gives up the shared-server attach, the `:scope` rewrite, and hiding `bd` — exactly the wrapper value the trio exists to provide.
Rejected.

**Use stock `bd init`, no custom `init`.**
This defers initialization to beads' default.
`bd init` is not good enough by default: its defaults do not suit the harness, and it does not follow devtree conventions.
That is exactly why `wk init` overrides it (see `wk init`).
Rejected.

**Rename only, keep the implementation in Python.**
This keeps the trio purely a rename of the existing Python tooling, with no rewrite.
It is less work than a Rust implementation and keeps the harness tooling in one language.
Rust is chosen deliberately for the frontend binaries; the tradeoff is a rewrite of `beads-devtree-init` and a second language in the tooling.
Accepted.

**Name the trio `wk`/`wkg`/`wkt`.**
`wk` abbreviates "work", a generic term with no overloaded `task`/`ticket` baggage in agent tooling or Jira.
Accepted; `t*` and `tk*` are the rejected alternatives below.

**Name the trio `t`/`tg`/`tt`.**
`t` is one letter, and `tg`/`tt` follow the old `bdg`/`bdt` suffix pattern.
`t` is overloaded: in agent tooling and trackers like Jira, `t`/`task`/`ticket` are ubiquitous, so the name reads ambiguously and invites collisions.
Rejected in favor of `wk`/`wkg`/`wkt`.

**Name the trio `tk`/`tkg`/`tkt`.**
`tk` reads as "task"/"ticket", making the family's intent explicit.
It carries the same overloaded `task`/`ticket` connotation, which is exactly what the naming is meant to avoid.
Rejected in favor of `wk`/`wkg`/`wkt`.

## Related artifacts

- `_SPECS/cross-devtree-task-routing/SPEC.md` — target grammar and `wkg`/`wkt` delegation.
- `_SPECS/task-scopes/SPEC.md` — `:scope` syntax and translation.
- `HANDOFF-20260920-beads-shared-server-devtree.md` — per-devtree shared Dolt server.
- `_SPECS/wk-beads-wrappers/EXPLORATION-frontend-cli.md` — the exploration that settled this design.
- `docs/beads-refs/` — the upstream beads reference.
- `README.md` — the harness overview and tooling conventions.
