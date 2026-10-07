---
name: improve-codebase-architecture
description: |-
  Scan a codebase for deepening opportunities, present them as a visual HTML report,
  then grill through whichever candidate the user picks.
  Load only when the user explicitly asks to review or improve a codebase's architecture.
  Examples: "improve this codebase's architecture", "find deepening opportunities here".
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**:
refactors that turn shallow modules into deep ones.
The aim is depth — smaller interfaces that are easier to test, reason about, and change.

This skill is _informed_ by the project's domain model and built on a shared design vocabulary:
- Load the `codebase-design` skill for the architecture vocabulary
  and its principles (the deletion test, "the interface is the test surface",
  "one adapter = hypothetical seam, two = real").
  Prefer its terms in every suggestion,
  and avoid vague stand-ins like "component", "service", or "unit".
- The domain language in `GLOSSARY.md` gives names to good seams.
  ADRs in `docs/adr/` record decisions this skill should not re-litigate.

## Process

### 1. Explore

**Weight recent churn.**
Deepening a module pays off by making future changes to it easier,
so put extra weight on the parts of the codebase that have recently changed.
Decide *where* to look before you look:
- If the user named a direction (a module, a subsystem, a pain point),
  take it, and skip the inference below.
- Otherwise, walk back a good stretch of the commit history to find the codebase's hot spots,
  then let those paths pull your attention first:
  `git log --since="6 months ago" --name-only`, and notice the paths that recur.
  If the changes are scattered with no clear hot spot, widen the net.

Read the project's domain glossary (`GLOSSARY.md`, if it exists)
and any ADRs in the area you're touching first.

Then spawn a subagent with the `task` tool to walk the codebase.
Don't follow rigid heuristics; explore organically and note where you experience friction:
- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow**, with an interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability,
  but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: imagine deleting it.
If complexity vanishes, it was a pass-through — collapse it.
If complexity reappears across its callers, the complexity is real —
deepen the module so a smaller interface hides it.

### 2. Present candidates as an HTML report

Write a single-file HTML report to `/tmp/archi-review-<timestamp>.html`
so nothing lands in the repo.
The file loads Tailwind and Mermaid from CDNs, so rendering it needs network access.
When the report is ready, mention its path to the user; don't open it for them.

The report uses **Tailwind via CDN** for layout and styling,
and **Mermaid via CDN** for diagrams where a graph/flow/sequence
reliably communicates the structure.
Mix Mermaid with hand-crafted CSS/SVG visuals: use Mermaid when relationships are graph-shaped
(call graphs, dependencies, sequences), and hand-built divs/SVG when you want something more
editorial (mass diagrams, cross-sections, collapse animations).
Each candidate gets a **before/after visualisation**.
Be visual.

For each candidate, render a card.
Its fields and badge row are specified in <./HTML-REPORT.md>.

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Use the domain glossary (`GLOSSARY.md`) for domain names,
and the `codebase-design` architecture vocabulary for the architecture.**
If `GLOSSARY.md` defines "Order," talk about "the Order intake module,"
not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR,
only surface it when the friction is real enough to warrant revisiting the ADR.
Mark it clearly in the card
(e.g. a warning callout: _"contradicts ADR-0007, but worth reopening because…"_).
Don't list every theoretical refactor an ADR forbids.

See <./HTML-REPORT.md> for the full HTML scaffold, diagram patterns, and styling guidance.

Do NOT propose interfaces yet.
After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, walk the decision tree with them, one branch at a time:
- What constraints pin the design (deadlines, compatibility, team conventions)?
- What does the deepened module depend on, and which dependency category fits the new seam?
- What is the shape of the deepened module: its single interface, and what sits behind the seam?
- Which tests survive the change, and which become waste once interface-level tests cover them?

Ask one question at a time.
Push back on vague answers instead of accepting them.
Keep going until the interface is concrete enough to write down.

Side effects happen inline as decisions crystallize;
call the `domain-modeling` skill to keep the domain model current as you go:
- **Naming a deepened module after a concept not in `GLOSSARY.md`?** Add the term to `GLOSSARY.md`.
  Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term during the conversation?** Update `GLOSSARY.md` right there.
- **User rejects the candidate with a load-bearing reason?** Offer an ADR, framed as:
  _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_
  Only offer when the reason would actually be needed by a future explorer
  to avoid re-suggesting the same thing; skip ephemeral reasons
  ("not worth it right now") and self-evident ones.
- **Want to explore alternative interfaces for the deepened module?**
  load the `codebase-design` skill
  and use its design-it-twice parallel subagent pattern.
