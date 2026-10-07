# Spec the `devtree` CLI surface

Write spec for whole `devtree` CLI. Routing spec delegates `registry lazy-register`/`refresh` to "the devtree CLI"; daemons spec adds `init`/`procs` family. CLI today has only `root --json`. No spec defines surface or state placement (`<devtree>/.state/`, `$XDG_STATE_HOME/devtree-global/`). Needed so routing and daemons share one contract.

## Open questions

- Project-registry + known-devtrees JSON schema (fields, identity = `issue_prefix`).
- Language: stay Python or fold into Rust `wk` frontend.
- Who owns `.state/` conventions vs other specs that consume it.
- `devtree init` scope: marker + `process-compose.yaml` seed only, or wider scaffolding.

## Artefacts

- `tooling/devtree/devtree` — current impl (`root` only).
- `tooling/devtree/devtree.bats`, `tooling/devtree/package.nix`, `flake.nix` — package wiring.
- `_SPECS/cross-devtree-task-routing/SPEC.md` — registry contract, resolution rules.
- `_SPECS/devtree-daemons/SPEC.md` — `devtree init` + `procs` family.
