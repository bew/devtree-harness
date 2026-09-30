# [READY] Cross-devtree Task Routing

## Introduction

Beads (`bd`) tracks work in a single repository.
It finds its workspace by walking up for a `.beads/` directory and scopes every query to that workspace's `issue_prefix`.
That model is exactly right inside one project, which is why per-project isolation needs no extra tooling.
It has no notion, however, of the many independent projects a developer keeps on one machine, nor of the devtrees that group them (see `README.md` for the devtree definition).
There is no way to address a different project, or a different devtree, from a shell without changing directory first, and no coherent scheme for naming such a target.

`bdg` and `bdt` are the addressing layer that fills that gap.
They take a user-typed target, resolve it to exactly one workspace, and route the `bd` invocation there: move to that directory, then exec `bd`.
They are pure routing — one command, one project — and deliberately do not reimplement `bd`.

The layer serves the human first, per the harness constraint in `README.md`: short commands, from anywhere, with agent support as a layer on top.
Two entry points cover the two situations a person works from.
`bdg` addresses any known devtree from anywhere: it resolves a bare name in the enclosing devtree when there is one, and otherwise across all known devtrees.
`bdt` is the in-devtree form: it resolves the enclosing devtree from the current directory and only ever reads that devtree's project registry.

The design stays within the precedent set by Gas City's `gc bd --rig <name>`, which routes by changing directory and exec'ing `bd` unmodified.
It also leans on beads' own shared-server model, where one Dolt server per devtree keeps projects logically isolated by `issue_prefix`.


## Terminology & Key Concepts

**`bdg`** (new!):
The cross-devtree routing command.
It resolves a target, then routes the `bd` invocation there.

**`bdt`** (new!):
The in-devtree routing command.
It resolves the enclosing devtree from the current directory and only ever reads that devtree's project registry.

**qualified form** (new!):
A target written as `<devtree>:<project>`, naming both axes explicitly.

**bare form** (new!):
A target written as `<project>` or `<devtree>`, with no devtree qualifier.

**resolver** (new!):
The logic that maps a target to exactly one beads workspace, or rejects it as ambiguous.

**devtree-aware tooling** (new!):
Tooling that resolves the enclosing devtree and follows harness conventions, such as calling `devtree registry lazy-register` on interaction.

**devtree root** (new!):
The directory carrying the `.devtree-root` marker; the enclosing devtree is found by walking up to it (see `README.md`).

**devtree project registry** (new!):
A devtree's own lazy index of its projects, stored under `<devtree>/.state/`.
A project appears once devtree-aware tooling has interacted with it inside that devtree.

**known-devtrees list** (new!):
The global list of known devtrees, held as name and path under `$XDG_STATE_HOME/devtree-global/`.

**lazy registration** (new!):
The idempotent upsert, exposed as `devtree registry lazy-register`, that devtree-aware tooling calls on interaction to add the current project to its devtree's project registry and the current devtree to the known-devtrees list.

**cwd-scoped resolution** (new!):
Resolving a target within the enclosing devtree of the current directory only, as `bdt` and in-devtree `bdg` do.

**registry-scoped resolution** (new!):
Resolving a bare project across every known devtree's project registry, used by `bdg` outside any devtree.


## Naming & IDs

**Commands**:
`bdg` (cross-devtree) and `bdt` (in-devtree).

**Target forms**:

```
target    := qualified | bare-project | bare-devtree
qualified := <devtree-name> ":" <project-prefix>
```

- `qualified` — `work:cmdo-nix`.
- `bare-project` — `cmdo-nix`.
- `bare-devtree` — `work`.

**Command shape**:

```
bdg <target> [bd-args…]
bdt <project-prefix> [bd-args…]     # devtree taken from cwd
```

The first positional argument is always the target; everything after it is forwarded verbatim to `bd`.
A missing target is an error: `bdt` does not fall back to the current project, and plain `bd` is used for that.

## Interface / How to use

Both commands take a target as their first positional argument and forward everything after it to `bd` unchanged.

### `bdg` — cross-devtree routing

```
# Qualified: devtree and project named explicitly. Resolves from anywhere.
$ bdg self:ghh list --status=open

# Bare project.
# Inside a devtree, resolved in that devtree only.
# Outside a devtree, resolved across all known devtrees.
$ bdg cmdo-nix ready

# Bare devtree: targets the devtree root's own scope.
$ bdg work list

# Arguments are forwarded verbatim, including cross-project dependency targets.
$ bdg work:cmdo-nix dep add commando-nix-a1b2 external:ghh:build
```

### `bdt` — in-devtree routing

```
# Devtree taken from the current directory; only the project is named.
$ bdt ghh list
$ bdt cmdo-nix ready

# Same, from anywhere under the devtree.
$ cd ~/self/my-projects/ghh/subdir && bdt cmdo-nix list
```

### Ambiguity and errors

```
# Outside a devtree, a colliding bare project is rejected, never guessed:
$ bdg api list
!! ERROR: 'api' is ambiguous across devtrees: self, work
   qualify as 'bdg self:api' or 'bdg work:api'

# A project unknown to the lazy registry has nowhere to route:
$ bdg ghh list
!! ERROR: 'ghh' project is unknown in devtree 'self'
```

### Routing semantics

`bdg`/`bdt` resolve the target to a workspace directory, change into it, and exec `bd` from `PATH` with the forwarded arguments.
The underlying `bd` runs unmodified: no output rewriting, no query interception.
`bdg`/`bdt` stream `bd`'s output and propagate its exit status, so they are transparent for piping and scripting.
Exec'ing `bd` from `PATH` (rather than a private binary) is deliberate: it lets the target devtree's shared-server wrapper start and attach its Dolt server (see *Placement / Scope*).

## Resolution rules

Resolution depends on two inputs: the target form, and whether the current directory is inside a devtree.
The enclosing devtree is found by walking up for the `.devtree-root` marker.

### Devtree names are global; project names are scoped

A bare name is matched against devtree names first.
On a match, the target is the devtree root's own scope.
Devtree names are global and win over any project prefix of the same spelling, so `bdg work` always means the devtree `work`, never a project named `work`.

When the bare name is not a devtree name, it is treated as a project and resolved by scope:
- Current directory inside a devtree: resolved in that devtree's project registry only.
  Other devtrees are never consulted, so a project prefix that also exists elsewhere is not a collision.
- Current directory outside any devtree: resolved across every known devtree's project registry.

NOTE: The devtree project registry is lazy-only, so an in-devtree bare project resolves only once something has registered it — typically a prior interaction inside it.
A never-touched project stays unknown until then.

### Qualified targets

`<devtree>:<project>` resolves the devtree axis globally and the project axis within that devtree.
The qualified form is always available and is the way to reach a project in another devtree.

### Collisions

- Outside a devtree, a bare project name that matches more than one devtree is rejected, never tie-broken: the error lists the candidate devtrees and asks for the qualified form.
- Prefixes are not required to be globally unique.
  Collisions are handled here, at resolution time, not enforced at creation.

### Misses

- An unknown devtree name is an error.
- A project absent from the resolved devtree is an error; resolution never falls back to another devtree.

### `bdt`

`bdt` resolves the devtree from the current directory and the project within that devtree's project registry only.
It never reads the known-devtrees list.

## Registry

The registry is a harness-wide concept, not a `bdg` detail.
It has two tiers, both populated lazily by devtree-aware tooling and each stored as a single JSON index.
This spec defines the contract `bdg`/`bdt` rely on; the registry's own commands live in the `devtree` CLI.

### Devtree project registry

Each devtree keeps its own index of its projects under `<devtree>/.state/`.
A project enters the index once devtree-aware tooling interacts with it inside that devtree; its identity is the `issue_prefix`.
The index is lazy-only: no scan, no TTL, and a project never interacted with stays absent.
`devtree registry refresh` is the explicit escape hatch that rebuilds a devtree's index.

### Known-devtrees list

The global list is held under `$XDG_STATE_HOME/devtree-global/` and stores each devtree's name and path only — no project data.
A devtree enters the list when any devtree interaction happens inside it.
Resolving across devtrees reads each entry's project registry from its recorded path, on demand.

### Lazy registration

`devtree registry lazy-register` is the single upsert all devtree-aware tooling calls on interaction.
It adds the current project to its devtree's project registry, and the current devtree to the known-devtrees list, each only if not already present.
It is idempotent.
`bdg`/`bdt` are ordinary consumers of this contract, no different from any other devtree-aware tool.

### Freshness

Lazy-only; there is no TTL and no daemon.
The known-devtrees list prunes an entry whose devtree directory no longer exists when the list is read.
A devtree project registry only changes through interaction or an explicit `refresh`.

## Placement / Scope

### State placement

- Devtree project registries live under `<devtree>/.state/`, alongside other devtree state (see `_SPECS/devtree-daemons/SPEC.md`); they are never committed to a project repo.
- The known-devtrees list lives under `$XDG_STATE_HOME/devtree-global/`.
- `bdg`/`bdt` write no state inside a project repo; a project only ever carries its `.beads/` workspace.

### In scope

- Resolving a target to exactly one beads workspace.
- Routing to it (change directory, then exec `bd`), preserving arguments, output, and exit status.
- Consuming the harness registry contract: reading registries for resolution, and calling `devtree registry lazy-register` on interaction.

### Out of scope

- **Aggregate or cross-project reporting.** `bdg`/`bdt` route one command to one project; there is no `bdg all …`.
- **The shared-server `bd` wrapper.** It is an external artifact (see *Related artifacts*); `bdg`/`bdt` only rely on it being on `PATH`.
- **Registry management commands.** `devtree registry lazy-register` and `devtree registry refresh` belong to the `devtree` CLI; this spec fixes only their contract.
- **`bd` itself** and its issue model, which `bdg`/`bdt` do not reimplement.

## Alternatives & Tradeoffs

The chosen direction is a two-command routing layer (`bdg`/`bdt`) over a two-tier lazy registry.

### Option A — pure routing (chosen)

```
$ bdg work:cmdo-nix list --status=open
# -> chdir <devtree>/cmdo-nix, exec bd list --status=open
```

- Advantages: minimal surface; `bd` stays the single source of truth; arguments, output, and exit status pass through untouched; matches Gas City's `gc bd --rig` ceiling.
- Costs: no cross-project view; every answer comes from a single project.

### Option B — routing plus aggregate reporting

```
$ bdg all list --status=open       # every project, every devtree
```

- Advantages: one query spans projects, useful for a global work view.
- Costs: forces the registry to carry Dolt connection info and stay fresh enough to trust; duplicates `bd`'s query surface; grows scope past addressing.

### Option C — live scan, no registry

```
# resolve a bare name by walking known devtrees on every run
```

- Advantages: no state to keep fresh; always current.
- Costs: slow across many devtrees; still needs a root-discovery source, which is the known-devtrees list anyway.

### Decision criteria

- Option A when the goal is addressing: the layer routes, `bd` answers.
- Option B only if a cross-project reporting need appears that per-project `bdg` calls cannot meet.
- Option C only while devtree count stays tiny; the known-devtrees list is already a cheap cache.

## Related artifacts

- `HANDOFF-20260920-beads-shared-server-devtree.md` — the shared-server `bd` wrapper this spec routes into (one Dolt socket per devtree).
- `README.md` — the devtree definition, the human-first constraint, and the tooling inventory.
- `docs/beads-refs/` — the `bd` data model, how-to, and tag vocabulary, including the `issue_prefix` and `external:<project>:<capability>` mechanics this spec leans on.
- `_SPECS/devtree-daemons/SPEC.md` — the `<devtree>/.state/` convention and the one-server-per-devtree pattern.
- `EXPLORATION-*.md` in this directory — the pre-spec design record (resolver-core, registry, routing-vs-aggregate, bd-wrapper-interaction).

## Global Open Questions
