# scope-model — exploration

What a scope is, what identifies it, and how a task's membership in one or more scopes is represented.

## Findings

- A scope is per-project: it is a property of one project's beads workspace, not a devtree-level or cross-devtree axis.
- A task can be in multiple scopes at once (many-to-many).
- The user's shorthand: "a label on the task I want to ask about".
- `bd` already has free-form labels (`bd label`, `bd tag`), a `metadata` key=value bag, and hierarchy via `parent`/`epic` — any of which could carry scope membership.
- Membership is a `bd` label in a reserved `scope:` namespace (e.g. `scope:auth`); filtering is `bd list --label scope:<name>`. The prefix keeps scopes distinct from ordinary tags.
- Membership is purely additive: a task carries any number of scopes; no primary scope and no exclusive dimension.
- A declared vocabulary was considered, then dropped for now: scopes exist only as labels — no project config and no governance.
- The user is leaning toward a personal frontend CLI (`wk`) that wraps `bd` without exposing it directly, e.g. `wk :myscope ready` queries ready tasks carrying `scope:myscope`; scope addressing and any active context may live there rather than in `bdg`/`bdt`.
- A scope is a read-side filter named per invocation; nothing is persisted as a "current scope".

## Design crux

Representation is settled: a scope is a `bd` label under a reserved `scope:` namespace, flat, free-form, with no declared vocabulary.
Where the syntax lives is settled — the wrapper layer (`bdg`/`bdt`/`bd`) behind a shared implementation (see `EXPLORATION-scope-translation.md`); the open question there is how `:scope` composes with project and devtree addressing.

## Candidate directions

- (rejected) **A — plain label convention.** Loses the namespace; scopes indistinguishable from ordinary tags.
- (rejected) **B — scope is first-class metadata.** Weakest query surface; no first-class `bd` metadata filter.
- (rejected) **C — scope is an epic/parent.** `bd`'s parent is single-valued, so a task could hold at most one scope; contradicts purely-additive multi-membership.
- (rejected) **D — scope is a new first-class construct.** Reimplements filtering and adds storage/freshness with no requirement driving it.
- (settled) **E — reserved `scope:` label.** A scope is a `bd` label `scope:<name>`; membership is label presence; flat, free-form, additive, no declaration.

## Decisions

- (settled) **Scope is a `scope:`-namespaced `bd` label.** Membership is the label's presence; filtering is by that label.
- (settled) **No declared vocabulary.** A declared, name-only list was considered and dropped for now; scopes exist only as labels.
- (settled) **Flat.** No nesting.
- (settled) **Purely additive membership.** No primary scope, no exclusivity.
- (settled) **No persisted active context.** A scope is named per invocation; nothing is written as a "current scope".
- (superseded) **Hybrid representation with a project-config declared list.** Replaced by labels-only once declaration was dropped.
- (superseded) **Governed/advisory declared vocabulary.** Replaced by the labels-only decision above.

## Open threads

- (answered) Scope syntax lives in the wrapper layer (`bdg`/`bdt`/`bd`) behind a shared implementation, not a separate `wk` binary; see `EXPLORATION-scope-translation.md`.
- Composition grammar: `wk :scope ready` vs `wk project:scope ready` vs `wk devtree:project:scope ready` — how are the segments disambiguated?
- With no declared list, what does the "hint" on first use of a scope actually say?
- Is the label literally `scope:<name>`; how does it avoid noise in `bd label list-all`?
- Does the frontend offer an ephemeral active scope, given nothing is persisted?
