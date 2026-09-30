# Cross-devtree task routing — exploration brief

## Motivation

`bd` (beads) has no notion of "multiple devtrees on one machine".
Per-project isolation works out of the box via `.beads/` walk-up discovery,
but there is no way to address another project, or another devtree, from a shell.

This exploration matures the design of an addressing layer — `bdg` / `bdt` —
that resolves a typed target into a single beads workspace, then routes there.

In scope: the addressing grammar, name resolution, the cross-devtree registry,
and how the layer coexists with a beads shared-server wrapper.

Out of scope: reimplementing `bd`; the Dolt shared-server topology itself
(see `HANDOFF-20260920-beads-shared-server-devtree.md`).

## Topics

- (frozen) `resolver-core` — resolve a typed target to exactly one beads workspace.
- (frozen) `registry` — discover devtrees/projects and keep the index fresh.
- (frozen) `routing-vs-aggregate` — pure routing vs. a cross-project reporting path.
- (frozen) `bd-wrapper-interaction` — how routing composes with the Nix-wrapped `bd`.
