# improve-codebase-architecture

Imported copy of an upstream skill, then reworked in this repo.

## Provenance

- Source: https://github.com/mattpocock/skills
  (`skills/engineering/improve-codebase-architecture`)
- Upstream commit: `d80fa0f4ebe0c5714af0adf8670336065233ecc6`
- Imported: 2026-09-30
- Import is a faithful copy; content rework happens in rounds after import.

## Local changes

- Reformatted both docs to one sentence per line (semantic line breaks),
  switched the cross-file reference to `<./HTML-REPORT.md>`,
  and dropped blank lines after colon-led lead-ins.
- Reconciled the candidate-card spec: `HTML-REPORT.md` is now the single source
  for card fields, with `SKILL.md` just pointing to it;
  the field is **Wins** (≤6-word bullets in architecture vocabulary);
  the mixed dependency labels were replaced with codebase-design's four dependency categories,
  and a **Dependency** line was added to the card.
- Fixed the deletion-test direction in `SKILL.md`:
  vanishing complexity means a pass-through (collapse it),
  reappearing complexity means the module earns its keep (deepen it).
- Fixed the hot-spot scan in `SKILL.md`:
  replaced `git log --oneline` (which shows no paths)
  with `git log --since="6 months ago" --name-only`.
- Disambiguated the two vocabularies:
  the project's domain glossary (`GLOSSARY.md`) is never confused
  with the `codebase-design` architecture vocabulary;
  bare "glossary" and the `/codebase-design` slash form were removed.
- Pointed both docs at `codebase-design` as the vocabulary source
  (dropped the two drifting positive term lists);
  only vague stand-ins (component, service, unit) are discouraged,
  and semantic-heavy synonyms (API, signature, boundary, layer, wrapper) are explicitly allowed.
- Inlined the grilling loop; retained the `domain-modeling` call for domain-model updates.
- Dropped the "self-contained" claim for the HTML report:
  it is a single file, but it loads Tailwind and Mermaid from CDNs
  and so needs network access.
- Simplified the report path: fixed at `/tmp/archi-review-<timestamp>.html`,
  with no `$TMPDIR`/`%TEMP%` resolution and no auto-open
  (the path is mentioned to the user instead).
- Minor accuracy fixes in `SKILL.md`: called the artefact a skill (not a command),
  replaced the misfitting "YAGNI" label with "Weight recent churn",
  and guarded the initial `GLOSSARY.md` read with "if it exists".
- Removed the Codex-only `agents/openai.yaml` (and the `agents/` dir); it has no effect in OpenCode.
- Fixed the frontmatter for OpenCode: dropped the unsupported `disable-model-invocation` field
  and made the `description` explicitly user-triggered with example phrases.
- Wrapped all prose to a 100-character line width across both docs (and this README).
- Kept semantic-heavy synonyms (API, signature, boundary, layer, wrapper) allowed in the report,
  with an explicit note that this deliberately overrides codebase-design's ban.
- Replaced Claude-isms with OpenCode terms: load the skill (not "Call the Skill tool"),
  spawn a subagent via `task` (not "sub-agent"), and dropped the unsupported `AI-navigability` aim.
- Fixed the HTML report spec: corrected the Mermaid `classDef` example, required
  `id="candidate-N"` on candidate articles for the Top-recommendation anchor,
  replaced "glossary term" with "vocabulary term", and scoped the closing vocabulary rule
  with "except the synonyms allowed above".
