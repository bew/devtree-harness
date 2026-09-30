# frontend-cli — exploration

Status: frozen — design settled and spec-ready; the name and implementation location are fixed.

A personal frontend CLI (`wk`/`wkg`/`wkt`) that exposes the harness task-tracking commands under short names and keeps upstream `bd` hidden.
`wk` is the in-project form, `wkg` the cross-devtree form, `wkt` the in-devtree form — renamed one-to-one from the existing harness `bd` wrapper, `bdg`, and `bdt`.

## Findings

- `wk`/`wkg`/`wkt` are the *same commands* as the existing harness `bd` wrapper, `bdg`, and `bdt` — a rename, not a new layer. Behavior, grammar, and output are identical.
- The harness `bd` wrapper is the command being renamed to `wk`: it fronts upstream beads `bd` (starting the per-devtree shared Dolt server) and is the chokepoint that performs the `:scope` rewrite. `bdg`/`bdt` exec it for routed invocations.
- Observed syntax: `wk :myscope ready`, the in-project form — equivalent to the direct `bd :auth list` grammar defined in the task-scopes spec.
- The wrapper layer is the universal chokepoint for every `bd` invocation, direct or routed, so `wk` inherits the `:scope` rewrite for free.
- The task-scopes spec (`_SPECS/task-scopes/SPEC.md`) already settles scope translation: `:scope` → per-subcmd `bd` label parameter, in the wrapper layer; its global open question #1 ("whether `wk` supersedes the `:scope` wrapper syntax") is answered **yes** at the surface level.
- The routing spec (`_SPECS/cross-devtree-task-routing/SPEC.md`) defines `bdg`/`bdt`, which the rename supersedes as user-facing entry points.
- Harness tooling is Python: extensionless scripts with a `python3` shebang, Nix-packaged (`tooling/devtree/devtree`, `tooling/beads-devtree-init/beads-devtree-init`). The renamed commands follow.
- No backward compatibility is needed: there are no scripts or habits tied to the old command names.
- Upstream `bd` is **not** on `PATH`; `wk`/`wkg`/`wkt` carry it inside their Nix closure and invoke it internally. The trio is the only user-facing task surface.
- The routing spec's `exec bd from PATH` wrapper mechanism is superseded: wrapper logic (server attach + `:scope` rewrite) moves into `wk`, and `wkg`/`wkt` exec `wk` (see *Decisions*).
- `tooling/beads-devtree-init/beads-devtree-init` (the harness-safe `bd init` wrapper: resolves `.devtree-root`, refuses if `.beads/` exists, runs `bd init --stealth --skip-agents --skip-hooks`, undoes bd's auto-commit, force-tracks the wanted `.beads` files, installs beads skills) relocates into `wk-beads-wrappers/` and becomes the `wk init` implementation. `init` is thus the one verb `wk` intercepts rather than forwarding to `bd`.

## Design crux

Settled as a rename: the crux is no longer what `wk` *adds* (nothing beyond shorter names) but the naming and retirement mechanics around swapping `bd`/`bdg`/`bdt` for `wk`/`wkg`/`wkt`.
Sub-cruxes: whether the old names are retired or kept as aliases, and whether `wk` is the final name.

## Decisions

- (settled) **Pure rename.** `wk` = the harness `bd` wrapper renamed; `wkg` = `bdg`; `wkt` = `bdt`. Identical behavior, grammar, and output; upstream beads `bd` stays hidden underneath. No curated verb set, no output curation.
- (settled) **Surface shape = trio `wk`/`wkg`/`wkt`**, one-to-one with `bd`/`bdg`/`bdt`: `wk` in-project, `wkg` cross-devtree, `wkt` in-devtree.
- (settled) **Scope translation is inherited**, not re-designed; it stays in the wrapper layer below `wk`.
- (settled) **No aliases, no back-compat.** The old names are simply not provided; there are no scripts or habits to preserve, and `bd` is bundled inside the trio rather than exposed on `PATH`.
- (settled) **`wkg`/`wkt` exec `wk`.** They resolve the target, chdir, then exec `wk` — a sibling from the same Nix package, on `PATH` — forwarding args. `wk` owns the wrapper logic (per-devtree Dolt server attach + `:scope` rewrite) and is the sole caller of the bundled `bd`.
- (settled) **Wrapper logic lives in `wk`.** The routing spec's `exec bd from PATH` clause is replaced by `wkg`/`wkt` → `wk`; there is no PATH-visible `bd` wrapper.
- (settled) **Names.** `wk` = work, `wkg` = work-global (cross-devtree), `wkt` = work-devtree (in-devtree). `wk` is the binary name; "work" avoids the overloaded `task`/`ticket` terminology used across agent tooling and Jira.
- (settled) **Implementation location.** `wk-beads-wrappers/`.
- (settled) **Supersedes the routing spec's user-facing entry points.** `bdg`/`bdt` are no longer the names the user types; the routing spec needs amending, and the task-scopes spec's global open question #1 is answered **yes**.
- (settled) **`wk init` is the relocated `beads-devtree-init`.** `wk` intercepts the `init` verb to run the harness-safe devtree bootstrap; plain `bd init` is not forwarded via `wk`. The one deliberate exception to "pure forward".
- (settled) **Rejected names.** `t`/`tg`/`tt` and `tk`/`tkg`/`tkt` — both carry the overloaded `task`/`ticket` connotation; `wk`/`wkg`/`wkt` is the chosen set.
- (settled) **Spec scope.** Frontend only: define the `wk`/`wkg`/`wkt` family, the delegation model, the bundled `bd`, and `wk init`; amend the routing and task-scopes specs rather than absorbing them.

## Open threads

- (open) Spec work: what exactly the routing and task-scopes specs must change to reflect the rename, the bundled off-`PATH` `bd`, and `wkg`/`wkt` → `wk` delegation.
