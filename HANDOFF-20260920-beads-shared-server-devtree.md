# Handoff: beads shared-server socket + devtree-aware `bd` wrapper

## Context

Project: `devtree-harness` (repo: https://github.com/bew/devtree-harness).
Session investigated why `bd list` took ~3s on a repo with 2 dummy issues (root cause:
embedded-Dolt mode, running `bd` 1.0.3), then designed a shared-server topology to fix
perf and give clean perso/work isolation across devtrees.

Decision direction locked in this session: run **one Dolt server per devtree**, over a
**Unix domain socket** stored at `<devtree>/.state/dolt.sock`, with a **Nix-wrapped `bd`**
that auto-starts the server on first use if not already running.

Not yet decided: where the socket path gets communicated to `bd` per-project, given the
constraint that this must NOT live in a repo-tracked config file.

## What was done

- Diagnosed the 3s `bd list` latency as embedded-Dolt cold start, not query cost — confirmed
  by `bd version` showing `1.0.3; embedded`. Beads' own benchmarks show ~200ms `bd list` at
  10k issues in server mode, so 3s for 2 issues is 100% startup tax, not data volume.
- Identified three beads backend modes: embedded (current), server (per-project or shared),
  proxied-server (remote/hosted Dolt, not relevant here).
- Established that shared-server mode isolates projects logically via mandatory unique
  `issue_prefix` per project, enforced at query time (`bd` filters every query by prefix) —
  not physical separation, but `bd` cannot cross-read between prefixes, and a prefix
  collision is detected and refused rather than silently merging data.
- Established that "registering" a project to a shared server is just two independent facts,
  not a protocol: (a) discovery — where's the server (host/port or socket path), and
  (b) identity — the project's `issue_prefix`, set once via `bd init --prefix <name>`.
- Confirmed `--server-socket` is a supported, documented flag, explicitly recommended for
  sandboxed environments (beads docs name Claude Code) where file-permission isolation beats
  network allowlists — good fit for agent-driven workflows.
- Confirmed a hard limitation: **auto-start is not supported in socket mode**. `bd`'s own
  orchestrator (`bd dolt start` / `gt dolt start`) only knows how to launch TCP servers. Any
  auto-start-on-first-use behavior for socket mode has to be built by us, not `bd`.
- Pulled the full config precedence chain from beads' configuration reference (source of
  truth: `cmd/bd/main.go`, `cmd/bd/config.go`, `internal/configfile/`), which is the key
  input for the open "don't store connection info in the repo" question:
  1. CLI flags (highest)
  2. Env vars (`BD_*`, legacy `BEADS_*`)
  3. `config.yaml`, searched in order: `~/.beads/config.yaml` → `~/.config/bd/config.yaml`
     → `<repo>/.beads/config.yaml` (walked up from cwd) → `$BEADS_DIR/config.yaml` (highest
     of the yaml tier, used when `BEADS_DIR` points at a different workspace)
  4. Built-in defaults
  - `config.local.yaml` next to project `config.yaml` is merged in last, explicitly meant for
    uncommitted machine-specific overrides.
  - `db` (connection target) has env override `BD_DB`; `dolt.*` namespace (includes
    `dolt.shared-server`) is YAML-only, read before the database opens.

## What remains

- **Blocking** — decide the socket-path discovery mechanism for `bd init`/`bd` invocations
  inside a devtree project (see Open Questions below; this is the actual next design step).
- **Blocking** — write the reference doc in `devtree-harness` describing: devtree state dir
  layout (`<devtree>/.state/`), one-Dolt-server-per-devtree topology, prefix-naming
  convention to avoid collisions across projects in the same devtree.
- **Non-blocking** — design the Nix wrapper around `bd`: needs to (a) detect current devtree
  root (likely by walking up for a marker file/dir, TBD — devtree root-detection isn't
  designed yet and isn't beads-specific), (b) check if `<devtree>/.state/dolt.sock` is live,
  (c) start `dolt sql-server --socket <path>` as a background/systemd-user-scoped process if
  not, (d) exec the real `bd` with the right connection env/flags set.
- **Non-blocking** — decide whether the devtree Dolt server is managed as a systemd user
  service (declarative, survives reboots predictably) vs. lazily spawned by the wrapper on
  first invocation (simpler, but the wrapper now owns lifecycle/orphan-process edge cases).
- **Non-blocking** — cross-devtree query story: since `bd` hard-scopes by prefix and has no
  cross-project view, any tooling that wants to query across all projects in a devtree needs
  to either loop `bd` per project or talk to Dolt directly over the socket, bypassing `bd`.
  Not designed yet; flag if the harness's task-tracking layer needs cross-project rollups.

## Open questions

- **How does `bd init`/`bd` learn the devtree's socket path without a repo-tracked file?**
  Blocking. Three real options surfaced this session, given the precedence chain above:
  - **`BEADS_DIR` env var**, set by the Nix wrapper before exec'ing real `bd`, pointed at a
    per-devtree location holding `config.yaml` with `dolt.*` socket settings. Highest-priority
    config location, fully environment-driven, nothing repo-tracked. Cost: every `bd` call
    must go through the wrapper (can't fall back to bare `bd` and still work) and `BEADS_DIR`
    conflates "config source" with "workspace root" per beads' own docs language.
  - **`config.local.yaml`** next to the project's `.beads/config.yaml`, gitignored, written
    once by the wrapper or devtree scaffolding at project-init time, holding the socket path.
    Cost: it's still a file *in the repo directory* (just not tracked) — need to confirm this
    fully satisfies the "not in a repo-stored config file" constraint, or if the constraint
    specifically means "not committed," in which case this qualifies.
  - **Env var only, no file at all** (`BD_DB` or a `dolt.*`-equivalent env var, set by the
    wrapper per-invocation based on detected devtree root). Cleanest fit for "nothing
    repo-stored," fully wrapper-owned, but need to verify a `dolt.*`-namespace socket setting
    actually has an env override — the doc states `dolt.*` is YAML-only (read before DB
    opens), which may mean no env var exists for the socket path specifically and this
    option is blocked without a beads code check.
- **Devtree root detection**: how does the wrapper find `<devtree>/.state/` from an arbitrary
  cwd inside a project? Not a beads question — a devtree-harness question. Needs a marker
  (e.g. `.devtree-root` file, or reuse git-superproject-style walk-up). Non-blocking for the
  beads doc specifically, but blocking for the wrapper implementation.
- **Prefix collision policy**: who assigns `issue_prefix` when the wrapper/scaffolding
  creates a new project in a devtree — derived from directory name, sequential, or manually
  chosen? `bd` refuses on collision but doesn't prevent one at creation time.

## Suggested skills and tools

- None of the user's existing skills are directly applicable; this is net-new reference
  material for `devtree-harness`.

## Key artefacts

- Repo: [devtree-harness](https://github.com/bew/devtree-harness) — target repo for the
  reference doc and wrapper code.
- [Dolt Backend for Beads](https://beads.gascity.com/architecture/dolt) — server modes,
  `--server-socket` flag, auto-start limitation in socket mode.
- [Beads Configuration reference](https://beads.gascity.com/reference/configuration) — full
  precedence chain, `BEADS_DIR`, `config.local.yaml`, YAML-only `dolt.*` namespace.
- [Beads Storage Topology (Gas City internal)](https://docs.gascity.com/reference/internal/beads-topology) —
  prefix-based isolation model on a shared server, useful as a reference implementation
  pattern even though Gas City's "city/rig" nesting doesn't map 1:1 onto devtree's arbitrary
  structure.
- [Beads CHANGELOG](https://github.com/gastownhall/beads/blob/main/CHANGELOG.md) — documents
  the wazero JIT startup-cost fix and embedded-mode removal; worth checking against the
  installed 1.0.3 to see if upgrading alone changes the calculus.
