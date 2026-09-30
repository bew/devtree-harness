# registry — exploration

## Findings

- (updated) The registry is two-tier: a per-devtree project registry, read both inside and outside a devtree; and a global known-devtrees list, read only from outside. The registry is a harness-wide concept, not a `bdg` detail.
- The bare name is the project `issue_prefix`; `bd` exposes `--json` on every command, so prefixes can be read via `bd info --json` rather than hand-parsing `config.yaml`.
- A devtree holds an arbitrary tree of projects, so enumeration means walking for `.beads/` dirs.
- `devtree root --json` yields `{name, path}`, where name is the directory basename.

## Design crux

Where the set of devtrees comes from, and how the index stays fresh without a daemon,
so bare-name resolution outside a devtree is trustworthy.

## Candidate directions

- (active) **Global state dir + materialized cache, auto-refreshed.**
- (rejected) **Live scan per run** — no cache; rejected in favor of a cached index to keep `bdg` fast.

## Decisions

- (superseded) **Registry state lives under `$XDG_STATE_HOME/devtree-global/`.** Superseded by the two-tier model below: only the global known-devtrees list lives there.
- (superseded) **Materialized cache with auto-refresh.** Superseded: the per-devtree project registry is lazy-only (no scan, no auto-refresh); the known-devtrees list prunes dead entries on read.
- (settled) **Project identity is `issue_prefix` only.** Only beads-initialized projects are addressable; no directory-name fallback.
- (settled) **Two-tier registry.** A devtree keeps its own project registry under `<devtree>/.state/`; a global known-devtrees list (name + path only) lives under `$XDG_STATE_HOME/devtree-global/`. Resolving across devtrees reads each listed devtree's registry on demand.
- (settled) **Lazy-only devtree project registry.** No scan and no TTL; a project stays absent until devtree-aware tooling interacts with it inside that devtree. `devtree registry refresh` rebuilds a devtree's index explicitly.
- (settled) **Registration is a shared harness primitive.** `devtree registry lazy-register` is the single idempotent upsert all devtree-aware tooling calls on interaction; it adds the current project to its devtree's registry and the current devtree to the known-devtrees list.

### Freshness model

Why: lazy registration resolves the devtree edge exactly when it is natural — you are inside a devtree when a project there is touched.
The known-devtrees list is pruned on read, so deletion needs no daemon.
The per-devtree registry never scans, so an untouched project is invisible until an explicit `refresh`.

## Open threads

- (resolved) Each tier is a single JSON index; registration is the shared `devtree registry lazy-register` primitive, not private to `bdg`/`bdt`.
