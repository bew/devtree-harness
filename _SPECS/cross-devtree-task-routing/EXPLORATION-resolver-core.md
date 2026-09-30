# resolver-core — exploration

## Findings

- `bd` resolves a workspace by walking up for `.beads/`; it has no concept of multiple devtrees.
- Devtree root detection is already solved: `.devtree-root` marker plus `devtree root --json`, which prints `{name, path}`.
- `issue_prefix` is assigned per project at init time by `beads-devtree-init` (`--prefix`, interactive prompt); it is the identity `bd` filters every query on.
- Addressing candidate grammar from the originating handoff: `bdg <devtree>:<project>`, `bdg <project>`, `bdg <devtree>`, and `bdt` (devtree pre-resolved from cwd).
- Gas City's `gc bd --rig <name>` establishes the ceiling for cross-devtree routing: chdir + exec, no cross-rig joining.

## Design crux

Resolve a user-typed target into exactly one beads workspace to route into,
across an open-ended set of devtrees that `bd` itself knows nothing about,
deterministically and never silently ambiguous.

## Candidate directions

- (rejected) **Qualified-only** — drop bare-name resolution entirely, require `devtree:project`. Simplest and collision-free, but loses the ergonomics the layer exists to provide.
- (rejected) **Enforced disjoint namespaces** — guarantee globally-unique project prefixes (and keep the devtree-name and prefix axes disjoint) at creation time. Superseded: forces a global naming constraint and still needs a resolver for unmanaged projects.

## Decisions

- (settled) **Two-mode resolution: cwd-scoped vs registry-scoped.**
  Inside a devtree, a bare project name resolves within the cwd devtree only; other devtrees are never consulted and no collision check runs.
  Outside any devtree, a bare project name resolves across every known devtree's project registry: a unique match resolves, a collision is rejected and the qualified `<devtree>:<project>` form is required.

### Two-mode resolution

Why: inside a devtree the cwd is an unambiguous scope, so global collision checking buys nothing and only adds latency and failure modes.
Outside, there is no scope, so the registry is the only source and ambiguity must be surfaced, never guessed.

### Bare devtree name

Confirmed behavior: `bdg <devtree>` targets that devtree's root scope.

### Name/prefix clash

- (settled) **Devtree name wins.** When a name `X` is both a devtree name and a project prefix somewhere, `bdg X` resolves the devtree; the project is reached via `<devtree>:X`.
  Keeps the coarse address stable; the qualified form is the project escape hatch.

### No global prefix-uniqueness enforcement

- (settled) Project prefixes may collide across devtrees; this is not checked at creation time.
  Collisions are handled entirely at resolution time, and only from outside a devtree.

### `bdt` is strictly cwd-scoped

- (settled) `bdt` resolves the devtree from cwd and reads only that devtree's project registry; it never touches the known-devtrees list.
  It is the cwd-scoped form of `bdg`.

## Open threads

- (resolved) Bare devtree-name resolution is global: `bdg <devtree>` works from inside another devtree too.
- Registry format, refresh, and discovery mechanism — deferred to the `registry` topic.
- Pure routing vs. an aggregate/reporting path — deferred to the `routing-vs-aggregate` topic.
- Coexistence with a Nix-wrapped `bd` that owns the shared-server socket — deferred to the `bd-wrapper-interaction` topic.
