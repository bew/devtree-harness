# bd-wrapper-interaction — exploration

## Findings

- The beads shared-server handoff specifies a Nix-wrapped `bd` that finds the devtree root by cwd walk-up, ensures `<devtree>/.state/dolt.sock` is live, and execs real `bd` with connection info.
- Socket mode has no auto-start in `bd` itself; the wrapper owns server lifecycle, so bypassing it loses the server.
- `bdg`/`bdt` route by `cd`-ing into the target, then exec'ing `bd`; after the `cd`, a cwd-based wrapper resolves the **target** devtree, which is what routing needs.

## Design crux

How `bdg`/`bdt` compose with the wrapped `bd` without duplicating or fighting devtree/socket resolution.

## Candidate directions

- (settled) **Front-end only.** `bdg`/`bdt` resolve the target, `cd` into it, and exec `bd` from `PATH`. They know nothing about Dolt or sockets.
- (rejected) **Bypass the wrapper.** Would duplicate the wrapper's lifecycle logic and lose auto-start.

## Decisions

- (settled) **Exec `bd` from `PATH`.** `bdg`/`bdt` never call the unwrapped binary; the Nix wrapper runs and owns the shared-server socket.
- (settled) **The shared-server wrapper is out of scope for this spec**, referenced as an external artifact (`HANDOFF-20260920-beads-shared-server-devtree.md`). This spec defines routing only.

## Open threads — none
