# [READY] Task Scopes

## Introduction

The cross-devtree task routing layer (`wkg`/`wkt`, see `_SPECS/cross-devtree-task-routing/SPEC.md`) addresses projects.
One target resolves to exactly one project, and `wk` runs there unmodified.

That is the right granularity for reaching a project, but not for working inside one: a project holds many tasks, and the routing layer has no way to express a finer grouping of them.

A scope is that finer grouping.
It is a per-project classification on a task, where a task can sit in several scopes at once.

Scopes are neither cross-devtree nor intra-devtree — they belong to a project, not to the devtree addressing axis.
They are flat and free-form: there is no declared vocabulary, and no membership is exclusive.

A scope is carried as an ordinary `bd` label under a reserved `scope:` namespace (`scope:auth`), and selected on the command line with a `:scope` segment (`wkg self:ghh:auth list`).
The segment is not addressing: it does not change which project is reached.
Instead, the wrapper layer rewrites it into the right `bd` label parameter per subcmd and forwards the rest of the command verbatim.

The routing spec reserves that optional third target segment; this spec defines the scope model and the rewrite.

The design serves the human first, per the harness constraint in `README.md`: a short, explicit selector typed per invocation, with no persisted "current scope" and no new storage.

## Terminology & Key Concepts

**scope** (new!):
A per-project, free-form, additive grouping on tasks.
Flat, and a task may hold any number of scopes.

**scope name** (new!):
The bare identifier of a scope, without the `scope:` prefix — e.g. `auth`.

**scope label** (new!):
The `bd` label that carries membership, formed as `scope:<scope-name>` (e.g. `scope:auth`).

**scope segment** (new!):
The optional `:scope` part of a command-line target — `:auth`, or `:auth,ui` for several.
It selects membership on reads and assigns it on writes.

**wrapper layer** (new!):
The `wk` wrapper — the in-project `wk` frontend that reaches the bundled `bd` — together with `wkg`/`wkt`.
All three share one rewrite implementation and are the only point where a scope segment becomes a `bd` label parameter.

## Scope as a `bd` label

A scope has no storage of its own: it is an ordinary `bd` label under a reserved namespace.
Membership is the label's presence, so a task is in scope `auth` exactly when it carries the label `scope:auth`.
The write and read sides are `bd`'s own: `bd label add`/`remove` and `--set-labels` write membership, and `bd list --label scope:auth` reads it.

The scope layer introduces no table, index, or file — only a naming convention plus the rewrite.

A label was chosen over the other carriers:

- Filtering is native and cheap: `bd`'s label filters (exact, any, pattern, regex) apply unchanged.
- Membership is naturally many-to-many and additive, matching "any number of scopes" with no primary/foreign distinction.
- It is inspectable with no tooling: `bd label list <id>` shows a task's scopes, and the `scope:` prefix keeps them apart from ordinary tags.
- Nothing has to stay fresh: there is no registry, cache, or TTL.

The rejected carriers:

- **Plain labels, no namespace.** Scopes would be indistinguishable from ordinary tags. The `scope:` prefix is what makes a scope a scope.
- **`bd` metadata.** Metadata is an unindexed key=value bag with no first-class filter, so membership could not be queried server-side.
- **`parent`/epic.** `bd`'s parent is single-valued, so a task could belong to at most one scope — incompatible with additive multi-membership.
- **A new construct.** A dedicated scope entity would reimplement filtering and add storage and freshness with no requirement driving it.

The namespace is reserved but not governed: `scope:` names are flat, with no declared vocabulary and a constrained character set (see *Naming & IDs*).
Scope membership is additive through inheritance too: because `bd` labels inherit by default, a child task picks up its parent's scopes.

## Naming & IDs

**Scope label**:

```
scope-label := "scope:" scope-name
scope-name  := [a-z0-9-]+          # lowercase; no ":", ",", or whitespace
```

The `scope:` prefix is reserved: any label beginning with it is a scope, and that prefix is used for nothing else.

**Scope segment**:

```
scope-segment := ":" scope-list
scope-list    := scope-name ("," scope-name)*
```

- `:auth` — one scope.
- `:auth,ui` — scopes `auth` and `ui`, combined with AND.

**Command shapes**:

```
wk   [:scope-list] <subcmd> [args…]      # direct — a leading segment before the subcmd
wkg <target>[:scope-list] [args…]       # routed — appended to the target
wkt <project>[:scope-list] [args…]      # in-devtree — appended to the project
```

```
wk :auth list
wkg self:ghh:auth list
wkt ghh:auth list
wkg self:ghh:auth,ui ready
```

The segment is the last part of the target and adds no addressing axis (see *Segment resolution*).
An empty project segment targets the devtree root's own workspace — `wkg work::auth`, `wkt :auth`.

The direct-`wk` form is wrapper syntax: stock `bd` takes no leading `:scope`, so the `wk` wrapper strips it before exec (see *Translation rules*).
A leading `:` token is always a scope; there is no escape, so a literal argument beginning with `:` cannot be forwarded in that position.

## Interface / How to use

A scope segment is typed on a routed target (`wkg`/`wkt`) or as a leading token before a direct-`wk` subcmd.
The same segment filters on reads, assigns on writes, and is dropped with a warning on subcmds that cannot carry it.

### Filtering

On read subcmds that take a label filter (`ready`, `list`, `count`), the segment becomes `--label scope:<name>`.

```
wk :auth list                     # -> bd list --label scope:auth
wkg self:ghh:auth ready           # -> bd ready --label scope:auth   (in project ghh)
wkt ghh:auth list
```


Several scopes are ANDed, expanding to repeated `--label` flags.

```
wkg self:ghh:auth,ui list        # -> bd list --label scope:auth --label scope:ui
```

### Assignment

On write subcmds, the segment assigns membership.

```
wkg self:ghh:auth create --title="Fix login"   # -> bd create --title="…" --labels scope:auth
wkt ghh:auth create --title="Fix login"
wk :auth update ghh-123 priority=1             # -> bd update ghh-123 priority=1 --add-label scope:auth
```

### Query

`bd query` carries `label=` in its own query language.

```
wk :auth query "status=open"     # -> bd query "label=scope:auth AND status=open"
```

### Subcmds with no label parameter

Subcmds such as `close`, `show`, `dep`, `comment`, and `note` expose no label parameter.
A scope segment there is dropped with a warning, and the subcmd runs unchanged.

```
$ wk :auth close ghh-123
!! warning: ignored scope 'auth'; `close` takes no label parameter
```

The warning goes to stderr and leaves the exit status untouched, so pipes and scripts are unaffected.

## Translation rules

Each wrapper strips the scope segment, then hands the collected scope names to one shared rewrite, which injects label parameters into the forwarded arguments.
The rewrite is subcmd-aware: it classifies the subcmd and injects the matching parameter.

### Subcmd classes

| Class | Subcmds | Injected parameter |
| --- | --- | --- |
| filter | `ready`, `list`, `count` | `--label scope:<name>`, repeated per scope (AND) |
| query | `query` | `label=scope:<name>` AND-ed into the query string |
| assign | `create` | `--labels scope:<name>` |
| assign | `update` | `--add-label scope:<name>` |
| none | `close`, `show`, `dep`, `comment`, `note` | none — ignored with a warning |

A subcmd outside the table is treated as label-less: the scope is ignored with a warning and the rest is forwarded unchanged.

### Notes

- Filtering is conjunctive: several scopes become repeated `--label` flags.
- Assignment is additive: `create` sets the scopes, `update` adds them; neither clears other labels.
- A scope merges with any label flag the caller passes: the injected parameter is added alongside, leaving the caller's flags in place.
- Inheritance follows `bd`'s default; the rewrite does not pass `--no-inherit-labels`.
- The ignored-scope warning goes to stderr and leaves the exit status unchanged.

## Segment resolution

A `wkg`/`wkt` target is a `:`-separated sequence of segments.
Resolution keeps the routing spec's rules for the devtree and project axes, and layers the scope segment on top as the last segment.

### Two axes plus a scope

The scope segment is optional and always last; everything before it is the routing address, resolved by the routing spec unchanged.

```
<devtree>:<project>:<scope-list>     # wkg
       <project>:<scope-list>        # wkt — devtree from cwd
```

`wkt` has no devtree segment, so its leading segment is always a project and its scope is never confused with a devtree.

### Devtree names win

For `wkg`, a two-segment target is ambiguous between `<devtree>:<project>` and `<project>:<scope-list>`.
The routing spec's existing rule decides it: a bare name matching a known devtree is that devtree.

So `wkg work:auth` is devtree `work` + project `auth` whenever `work` is a known devtree, never project `work` + scope `auth`.
When the first segment is not a devtree name, the pair reads as `<project>:<scope-list>`, so `wkg ghh:auth` is project `ghh` + scope `auth`.
The three-segment form `<devtree>:<project>:<scope-list>` is unambiguous.

### The devtree root's own workspace

The devtree root carries its own `bd` workspace, reachable by its bare devtree name (`wkg work`).
That name occupies the devtree segment, so `wkg work:auth` always means devtree `work` + project `auth`, never the root's own workspace with a scope.

An empty project segment targets the root itself: `wkg work::auth` is devtree `work`'s own workspace plus scope `auth`.
In `wkt`, which has no devtree segment, the same form is a leading empty project segment: `wkt :auth`.

## Placement / Scope

### Where the rewrite lives

The scope rewrite is one shared implementation consumed by all three entry points: `wkg`, `wkt`, and the `wk` wrapper.
`wkg`/`wkt` resolve the target, strip its scope segment, call the shared rewrite, then exec `wk`.
A direct `wk` invocation reaches the same rewrite through the `wk` wrapper, the universal chokepoint for every call.

The layer adds no per-project artifact: nothing is written into a project repo, and no state file, cache, or server-side construct is introduced.

### In scope

- The scope model: a reserved `scope:` label namespace, flat and free-form, carrying membership.
- The `:scope` selection syntax across `wkg`, `wkt`, and direct `wk`.
- Translating a scope segment into the per-subcmd `bd` label parameter.
- Merging scopes with caller-supplied label flags.

### Out of scope

- **A declared scope vocabulary.** No project config lists scopes; no governance or validation beyond the label charset.
- **A persisted or ambient active scope.** A scope is named per invocation; nothing is stored as a "current scope".
- **The `wk` frontend.** The `wk`/`wkg`/`wkt` binaries, the `wk` wrapper, and their packaging are owned by `_SPECS/wk-beads-wrappers/SPEC.md`.
- **Aggregate or cross-project scope queries.** As in the routing spec, one invocation targets one project; there is no `wkg all :auth`.
- **`bd` itself** and its label model, which the scope layer only rides on.
- **The `wk` wrapper's lifecycle.** It belongs to the frontend spec; this spec only relies on it to perform the rewrite.

## Alternatives & Tradeoffs

The chosen direction is a reserved `scope:` label namespace plus a `:scope` segment rewritten by the wrapper layer.
The options below are whole-design directions; the carrier choice within the chosen one is settled in *Scope as a `bd` label*.

### Option A — reserved label + wrapper rewrite (chosen)

```
$ wkg self:ghh:auth list
# -> bd list --label scope:auth   (in project ghh)
```

- Advantages: scopes are ordinary `bd` labels, so `bd` stays the single source of truth with no storage or freshness of its own; the `:scope` segment gives one short spelling across every subcmd.
- Costs: the rewrite must know each subcmd's label parameter; a subcmd with no label parameter drops the scope (with a warning).

### Option B — convention only, no rewrite

```
$ wkg self:ghh list --label scope:auth
# the user spells the label and the flag themselves
```

- Advantages: no tooling change; works with stock `bd`.
- Costs: no `scope:` namespace unless everyone adopts the convention; verbose and easy to mistype; the user must know each subcmd's flag; no shared place to evolve the convention.

### Option C — first-class scopes

```
$ wkg self:ghh --scope auth list
# scopes stored and indexed by the harness, not as bd labels
```

- Advantages: a governed vocabulary and a dedicated query surface are possible.
- Costs: reimplements `bd`'s filtering, adds storage and freshness, and moves the source of truth away from `bd`.

### Decision criteria

- Option A when scopes are a routine grouping and the harness owns the shell entry points: the rewrite buys the short `:scope` form with no new state.
- Option B while scopes are rare and a single user drives them by hand; revisit when the convention needs to be shared or enforced.
- Option C only if `bd` labels prove unable to carry membership (a hard limit or a missing filter), which is not the case today.

## Related artifacts

- `_SPECS/cross-devtree-task-routing/SPEC.md` — the routing layer this builds on; defines `wkg`/`wkt` and reserves the `:scope` target segment.
- `EXPLORATION-scope-model.md`, `EXPLORATION-scope-translation.md` in this directory — the pre-spec design record for the scope model and the rewrite.
- `docs/beads-refs/` — the `bd` data model and how-to, including labels and the per-subcmd label flags the rewrite targets.
- `HANDOFF-20260920-beads-shared-server-devtree.md` — the `wk` wrapper this spec's rewrite rides in (one shared Dolt socket per devtree).
- `_SPECS/wk-beads-wrappers/SPEC.md` — the `wk`/`wkg`/`wkt` frontend; its `wk` wrapper is where this spec's rewrite lives.
- `README.md` — the devtree definition and the human-first constraint this design follows.

## Global Open Questions

1. Whether the personal frontend CLI (`wk`) supersedes the `:scope` wrapper syntax.
   Resolved: yes. The `wk`/`wkg`/`wkt` frontend supersedes the `:scope` wrapper syntax at the surface; see `_SPECS/wk-beads-wrappers/SPEC.md`.
