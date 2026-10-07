# codebase-design

Design vocabulary for deep modules.
This copy is derived from an external skill and reworked locally.

## Provenance

- Upstream: https://github.com/mattpocock/skills — `skills/engineering/codebase-design`
- Imported at commit: `d80fa0f4ebe0c5714af0adf8670336065233ecc6` (2026-09-17)
- Imported into this repo: 2026-09-30

## Local changes on top of upstream

Applied in rounds; newest last.

- Removed `agents/openai.yaml` (Codex-only metadata, unused here).
- Reflowed the docs to semantic line breaks.
- Converted cross-file references to angle-bracket form:
  `<./SKILL.md>`, `<./DEEPENING.md>`, `<./DESIGN-IT-TWICE.md>`.
- Rewrote the `description` trigger to follow crafter trigger-style rules;
  dropped the unsupported "AI-navigable" clause.
- Added a trigger for preparing a software-feature impl, excluding scripts.
- Fixed the Ousterhout framing:
  reject the line-count ratio as a gameable proxy,
  and note his real definition matches depth-as-leverage.
- Scoped "exactly one Interface" and "the interface is the test surface" to the external seam,
  leaving room for private internal seams.
- Added a coverage-equivalence precondition before deleting old unit tests in `DEEPENING.md`.
- Reworded the "test must change" claim to separate internals-coupled churn
  from legitimate contract changes.
- `DESIGN-IT-TWICE.md`: made the sub-agent count explicit (3–4, fourth only for cross-seam deps)
  and gave the Step 3 comparison a concrete rubric.
- Wrapped prose to a 100-character line width across the docs.
