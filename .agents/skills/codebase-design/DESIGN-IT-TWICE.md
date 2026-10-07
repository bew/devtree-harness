# Design It Twice

When the user wants to explore alternative interfaces for a chosen deepening candidate,
use this parallel sub-agent pattern.
Based on "Design It Twice" (Ousterhout): your first idea is unlikely to be the best.

Uses the vocabulary in <./SKILL.md>: **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Before spawning sub-agents, write a user-facing explanation of the problem space
for the chosen candidate:
- The constraints any new interface would need to satisfy
- The dependencies it would rely on, and which category they fall into (see <./DEEPENING.md>)
- A rough illustrative code sketch to ground the constraints, not a proposal,
  just a way to make the constraints concrete

Show this to the user, then immediately proceed to Step 2.
The user reads and thinks while the sub-agents work in parallel.

### 2. Spawn sub-agents

Spawn 3–4 sub-agents in parallel.
Agents 1–3 always; agent 4 only when a cross-seam dependency needs designing around.
Each MUST produce a **radically different** interface for the deepened module.

Prompt each sub-agent with a separate technical brief:
file paths, coupling details, dependency category from <./DEEPENING.md>,
what sits behind the seam.
The brief is independent of the user-facing problem-space explanation in Step 1.
Give each agent a different design constraint:
- Agent 1: "Minimize the interface: aim for 1–3 entry points max.
  Maximise leverage per entry point."
- Agent 2: "Maximise flexibility: support many use cases and extension."
- Agent 3: "Optimise for the most common caller: make the default case trivial."
- Agent 4 (cross-seam deps): "Design around ports & adapters for cross-seam dependencies."

Include both <./SKILL.md> vocabulary and repo's GLOSSARY.md vocabulary (if available)
in the brief so each sub-agent names things consistently with the architecture language
and the project's domain language.

Each sub-agent outputs:
1. Interface (types, methods, params, plus invariants, ordering, error modes)
2. Usage example showing how callers use it
3. What the implementation hides behind the seam
4. Dependency strategy and adapters (see <./DEEPENING.md>)
5. Trade-offs: where leverage is high, where it's thin

### 3. Present and compare

Present designs sequentially so the user can absorb each one, then compare them in prose on:
- **Depth**: entry-point count, the params and concepts a caller must learn,
  and how much logic sits behind the seam vs. passes through.
- **Locality**: where change concentrates.
- **Seam placement**: what varies across the seam.

After comparing, give your own recommendation: which design you think is strongest and why.
If elements from different designs would combine well, propose a hybrid.
Be opinionated: the user wants a strong read, not a menu.
