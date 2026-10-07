# Promote "devtree root" to project-global docs

`devtree root` (and its own beads scope) used across the cross-devtree task routing spec but not defined project-globally.
Add a definition to `README.md`: the devtree root is the directory carrying the `.devtree-root` marker, and it may carry its own `bd` scope.
Trigger: spec review flagged the term as used but undefined.

## Artefacts

- `README.md` — target doc; holds the devtree definition.
- `tooling/devtree/devtree` — resolves the root by walking up for `.devtree-root`.
- `_SPECS/cross-devtree-task-routing/SPEC.md` — spec that uses the term.
