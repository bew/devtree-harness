# devtree-harness

A personal dev productivity harness for my many personal and work projects.
This repo is the harness meta-layer: it holds the tooling, decisions, and eventual NixOS configs.

## The devtree

A devtree is a root directory with arbitrary structure.
It gathers multiple projects together, along with task tracking for those projects.
Task items can reference any item in the devtree, across project boundaries.

Perso and work each get their own devtree, so the two contexts never mix.

## Human-first constraint

This harness serves a human first, not only AI agents.
Every capability must be usable manually: plain commands, short invocations, no overwhelming tooling surface.

Agent support is a layer on top, never the reason the tooling exists.

## Scope

This repo aims to contain:

- Harness decisions and their rationale
- Custom tooling
- Nix package definitions for the harness itself
- NixOS modules and configs for optional tooling around the harness

## Harness packages

Each exposed on flake `packages.<system>.*`.

- `devtree`: CLI over the devtree itself.
  For now only `devtree root --json`, which resolves the enclosing devtree root by walking up for the `.devtree-root` marker and prints `{name, path}`.

## Status

Early scoping: the harness is being designed, and decisions are not final yet.

----

## Analysis of my current practices

Observed on work MacOS system, across `~/work` and `~/self`.

### Common

- Two devtrees, each a non-git container aggregating many independent git repos (~50 in total).
- Pattern: a group directory holds one or more repos plus loose docs/data.
  Bundling projects this way is a good practice, not a requirement.
- Naming conventions are devtree-specific (see below).
- Planning and notes are loose markdown/text at group roots, often date-prefixed.
- Secrets (`.pem`, `*_AES_KEY.txt`, `prod_secrets.txt`) sit in plaintext at group roots.
- Per-project environments already use direnv and Nix flakes.
- Discovery/navigation: I use diralias + zoxide-with-fzf hooked into zsh for easy navigation between projects

### Specific to `self` devtree

- Groups are categories: `brain_work`, `brain-tech-resources`, `config-projects`, `my-projects`, `opensource-projects`, `playgrounds`.
- `brain_work/` (!! currently unmaintained) is a PARA + Johnny-Decimal note store (`05. Weeklies`, `10. Projects`, `20. Areas`, `30. Resources`, `99. Archive`).
  Weekly notes are dated (`YYYY-MM-DD Week NN.md`) alongside a `THIS WEEK.md`, with `_assets/` and per-section `Archives/`.
- `brain-tech-resources/` (!! currently unmaintained) is a flat markdown knowledge base, one file per topic named `Tool, usage notes.md`, with its own `Archives/` and a `Tech stacks @ Work/` subfolder.
- Some personal knowledge about work (structure, company, hiring process I've setup) lives in `brain_work` and `brain-tech-resources`, while work code lives in the `~/work` devtree.
- `config-projects/` holds personal machine and tooling config, one repo per concern: `dotfiles`, `macos-config`, `nixed-os-configs`, `my-nix-templates`, `diralias`.
  All are Nix-flake based, with `justfile`s and `.envrc` where relevant.
- `my-projects/` holds active personal software, one repo each (`devtree-harness`, `ghh`, `github-helpers`), in mixed languages.
- `opensource-projects/` holds upstream clones and forks (`nixpkgs`, `nix-darwin`, `opencode`, `wezterm`, `tmux-resurrect`, `nvim-stuff`), sometimes several copies of the same upstream (`wezterm`, `wezterm-alt`, `wezterm-oss-2`).
- `playgrounds/` holds throwaway `try-*` experiments, often with a local `venv/`.
- Naming uses category prefixes: `brain-*` for knowledge stores, `try-*` for experiments, numeric `NN.` prefixes inside `brain_work`.
- Repos stay independent (each its own git, `.envrc`, and flake where relevant), and the devtree root is not itself a repo.

Observed structure (sample):
```text
~/self
├── brain_work/            # repo using PARA + Johnny-Decimal notes (git)
├── brain-tech-resources/  # flat markdown KB (git)
├── config-projects/       # one repo per concern: dotfiles, macos-config, ...
│   ├── dotfiles/
│   ├── macos-config/
│   └── nixed-os-configs/
├── my-projects/           # active software: ghh, github-helpers
├── opensource-projects/   # upstream clones for opensource work/contributions: nixpkgs, wezterm*
└── playgrounds/           # try-* experiments
```


### Specific to `work` devtree

- Groups are use cases (`ucNN`, with decimal sub-cases like `uc35.5`) and shared buckets (`common-infra-stuff`, `common-libs-stuff`, `it-stuff`, `monitoring-stuff`), plus `api-tests-with-bruno`, `notes/`, and `playgrounds/`.
- Repos use a `commando-*` prefix for company apps and services, though not universally (`hercule-legacy`/`hercule-v2`, `risk-tools`, `kyc-tools`, `payoff-simulations`).
- A common project shape dominates: `pyproject.toml` + `src/` + `tests/` + `justfile` + `deployment/` + `.envrc`; many are Streamlit apps, with `yoyo.ini` DB migrations and ruff/pytest/dmypy caches.
- Infra repos carry `terraform/` with CI split between GitHub Actions (`.github/`) and GitLab (`.gitlab-ci.yml`).
- Nix flakes appear only in some repos (`commando-nix`, `commando-dev-infra`, `commando-mcp-servers-infra`); `devenv` appears once, in `playgrounds/`.
- Several repos carry their own `AGENTS.md`, and specs live either in a `specs/` dir or as loose `spec-*.md` at repo/group level.
- Group roots collect loose artifacts (dated CSVs, zips, xlsx, import logs) alongside plaintext secrets (`*.pem`, `prod_secrets.txt`, `*_AES_KEY.txt`).
- `.vimsession` files and `TODO_*`/`FIXME_*` pseudo-task files appear per repo.
- Ticketing uses JIRA; team and project docs use Confluence.
- `~/work/.autoenv.zsh` activates the devtree: adds shared `scripts/` to `PATH`, defines env/profile helpers (`prd-admin`, `stg-admin`, `sso`, `rmtf`), aliases.

Observed structure (sample):
```text
~/work
├── .autoenv.zsh           # devtree activation
├── ucNN-projectname-stuff/ # use-case group: repos + loose artifacts
│   ├── commando-some-project-name/ # repo for a project
│   └── *.csv  *.pem # some additional files related to the project but out of the git repo
├── common-*-stuff/        # shared buckets: many independent repos
│   ├── commando-deployment-helpers/ # repo
│   └── commando-infra-db-manager/ # repo
├── it-stuff/  monitoring-stuff/  api-tests-with-bruno/ # more repo (not bundled)
├── notes/                 # plain text notes
└── playgrounds/           # throwaway experiments or mini-projects
```

## Gaps

- Devtree config: hierarchy and naming are devtree-specific and currently implicit, so nothing can consume them programmatically.
- Task tracking: none in use, planning lives in loose files.
- Docs and reference: `notes/` and `brain-tech-resources` are separate stores, so a coherent doc strategy is still open.
- Work ticketing/docs: JIRA/Confluence is not accessible locally or to agents without complex MCPs.
- Secrets: plaintext sprawl at group roots has no handling scheme (ignore rules, encryption, central store).
- Environment activation: `.autoenv.zsh` is hand-written and shell-only, and only covers the devtree root.

## Tooling needed

- A devtree config file as the source of truth for hierarchy and naming, consumable by custom tooling.
- Tree-scoped definitions, at devtree, bundle, and project level, with hash-based allow/reload:
  - tool env, e.g. a Nix-managed `PATH` entry
  - shell-specific aliases, functions, and helpers
- A way to expose more than diffed environment variable changes when entering a scope.
- Possibly a direnv fork ("treeenv", naming TBD) that auto-detects envrc files in upper directories, not just the current project.
- A text- and git-based task tracker that can reference any item in the devtree, across nested repos.
  Explore beads even for work, with on-demand sync of important items to JIRA.
- A way to sync Confluence (team and project docs) into the devtree, read-only at least to start.
  This needs its own whole project design.
- Devtree-defined skills and tools for AI agents.
- Cross-repo discovery and indexing for navigation and search.
- A generic `repo-init` devtree wrapper that sequences per-concern init steps, one of which is `beads-devtree-init` (a thin wrapper over `bd init`).
