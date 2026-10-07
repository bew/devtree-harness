# Promote "devtree-aware tooling" to project-global docs

`devtree-aware tooling` used across the cross-devtree task routing spec but no project-global doc defines it.
Add a definition to `README.md`: tooling that resolves the enclosing devtree and follows harness conventions — e.g. calls `devtree registry lazy-register` on interaction.
Trigger: spec review flagged the term as used but undefined.

## Artefacts

- `README.md` — target doc; holds the devtree definition and tooling inventory.
- `_SPECS/cross-devtree-task-routing/SPEC.md` — spec that uses the term.
