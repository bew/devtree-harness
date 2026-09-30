# Task Scopes — exploration brief

## Motivation

The cross-devtree task routing layer (`bdg`/`bdt`, see `_SPECS/cross-devtree-task-routing/SPEC.md`) is pure addressing: one target resolves to one project's beads workspace, and `bd` runs there unmodified.
It has no way to express that a task belongs to a finer-grained grouping.

A scope is a per-project classification on a task, where a task can sit in several scopes at once.
Scopes are neither cross-devtree nor intra-devtree — they are a property of a project's own beads workspace, not an addressing axis projected onto the devtree.

This exploration matures the scope design: what a scope is, how tasks enter and leave scopes, how scopes are queried, and what — if anything — the `bd` wrapper must do.

In scope: the scope model and identity, membership/assignment, the query and addressing grammar, and any storage.
Out of scope: devtree-level and cross-devtree routing semantics (settled in the routing spec); reimplementing `bd`; any aggregate or cross-project query path.

## Topics

- (settled) `scope-model` — what a scope is, its identity, and how membership is represented
- (active) `scope-translation` — how a `:scope` selector is rewritten into the right per-verb `bd` label param, and which wrapper layer performs the rewrite

The broader `t` CLI was split off into its own exploration at `_WIP_EXPLORATIONS/frontend-cli/`;
it gets its own later spec, and scope translation now lives in the wrapper layer instead.
