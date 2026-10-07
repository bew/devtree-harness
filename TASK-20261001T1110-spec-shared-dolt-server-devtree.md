# Spec the per-devtree shared Dolt server

Write spec for beads shared server. Topology locked in handoff: one Dolt server per devtree, Unix socket at `<devtree>/.state/dolt.sock`, wrapper auto-starts on first use. Never spec'd. `wk` wrapper refs handoff only. Missing pieces: server lifecycle, auto-start (unsupported in socket mode, must build), socket-path discovery with no repo-tracked file. Blocks `wk` server-attach implementation.

## Blockers

- Socket-path discovery undecided (BEADS_DIR vs `config.local.yaml` vs env-only) — every `bd` call depends on it.
- Auto-start unsupported in socket mode — we own the spawn.

## Open questions

- Discovery mechanism: `BEADS_DIR` (env, highest precedence, conflates config+workspace) vs gitignored `config.local.yaml` (in repo dir, untracked) vs env-only (`BD_DB`/`dolt.*`, maybe no env override exists).
- Auto-start owner: wrapper lazy-spawn vs `devtree procs-ensure`.
- `issue_prefix` collision policy at project creation (bd refuses, never prevents).

## Artefacts

- `HANDOFF-20260920-beads-shared-server-devtree.md` — topology decision + open questions this spec must close.
- `_SPECS/wk-beads-wrappers/SPEC.md` — `wk` wrapper attaches the server; depends on this spec.
- `_SPECS/devtree-daemons/SPEC.md` — one-server-per-devtree pattern, `.state/` convention.
- `docs/beads-refs/` — `bd` config precedence, `issue_prefix`, labels.
