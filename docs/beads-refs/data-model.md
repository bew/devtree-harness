# Beads data model (core)

Beads (`bd`) is a local issue tracker backed by Dolt, one database per repository.
This ref describes the core data model used in this harness, grounded on `bd` 1.0.3.
Advanced concepts — molecules, wisps, gates, swarms, federation — are out of scope.

## Issue (bead)

The unit of work is an **issue**, also called a **bead**.
Each issue has a stable ID of the form `<prefix>-<suffix>` (for example `devtree-harness-a3f8e9`);
the prefix belongs to the database and can be changed with `bd rename-prefix`.

An issue carries these fields:

- `title` — short summary.
- `description` — what and why.
- `design`, `acceptance` — design notes and acceptance criteria.
- `notes` — running notes appended over time (see `bd note`).
- `spec-id`, `external-ref` — links to a spec document or an external tracker.
- `type`, `status`, `priority` — classification (see the sections below).
- `assignee` — who owns it.
- `labels` — free-form tags.
- `parent` — hierarchical container, if any.
- `dependencies` — typed links to other issues.
- `comments` — a conversation thread separate from `notes`.
- `estimate`, `due`, `defer` — scheduling metadata.
- `metadata` — arbitrary custom key=value pairs.

## Types

Built-in types (`bd types`): `task` (default), `bug`, `feature`, `chore`, `epic`, `decision`,
`spike`, `story`, `milestone`.
`bd create --type` advertises a subset but accepts the others.
Aliases: `enhancement`/`feat` → `feature`, `dec`/`adr` → `decision`.
Custom types: `bd config set types.custom "type1,type2,..."`.

## Statuses

Built-in statuses (`bd statuses`): `open` (active, default), `in_progress` (wip),
`blocked` (wip), `deferred` (frozen), `closed` (done), `pinned` (frozen), `hooked` (wip).
Categories are `active`, `wip`, `done`, `frozen`.

An issue blocked by a dependency keeps status `open`; find those with `bd blocked`,
not `--status=blocked`.
Custom statuses: `bd config set status.custom "name:category,..."`.

## Priority

Priority is an ordinal from 0 to 4, where 0 is the highest.
The `--priority` flag is typed as a string but only accepts `0-4` or `P0-P4`; words like
`high` are rejected.
The default is `2`.

- Set it: `bd priority <id> <value>` or `bd update <id> --priority=P1`.
- Filter: `bd list --priority=P0`, `--priority-min`, `--priority-max`.

## Labels (tags)

Labels (also called tags) are free-form strings with no built-in vocabulary.

- `bd tag <id> <label>` — shorthand for adding one label.
- `bd label add|remove|list|list-all` — manage labels across issues.
- `bd update <id> --add-label=x --remove-label=y --set-labels=a,b`.
- `bd create --labels=a,b` — comma-separated at creation.
- `bd label propagate <parent> <label>` — copy a parent's label to its children.

The harness convention for labels lives in `tags.md`.

## Dependencies

Dependencies are typed and directional.
`bd dep add <issue> <depends-on>` makes `<issue>` depend on `<depends-on>`, i.e.
`<depends-on>` blocks `<issue>`.
The default type is `blocks`.

Dependency types (`-t`): `blocks`, `tracks`, `related`, `parent-child`, `discovered-from`,
`until`, `caused-by`, `validates`, `relates-to`, `supersedes`.

- `bd link <id1> <id2>` — shorthand, `<id2>` blocks `<id1>`.
- `bd dep relate <a> <b>` / `unrelate` — bidirectional `relates-to`.
- `bd dep add <issue> <depends-on> -t related`.
- `bd create ... --deps 'discovered-from:bd-20,blocks:bd-15'`.
- Cross-project: `bd dep add <issue> external:<project>:<capability>`.

Inspect with `bd dep list`, `bd dep tree`, `bd dep cycles`.

## Hierarchy (parent / children)

Hierarchy links an issue under a parent with `--parent <id>` on create or update;
`bd update <id> --parent=""` clears it.

- `bd children <parent>` — all children, including closed ones.
- `bd list --parent <id>` — children filtered by the usual list flags.
- `epic` is the type for a large container of related issues; `bd epic` manages epics.

## Comments, notes, memories

Three distinct ways to record information:

- **Comment** — a message on the issue's conversation thread.
  `bd comment <id> "..."`; read with `bd show <id> --thread`.
- **Note** — text appended to the issue's own `notes` field.
  `bd note <id> "..."` (shorthand for `bd update <id> --append-notes`).
- **Memory** — a durable project fact, independent of any issue.
  `bd remember "<insight>" [--key <key>]`; `bd memories [search]`; `bd recall <key>`;
  `bd forget <key>`.
  Memories are surfaced by `bd prime`.

## Glossary

- **bead / issue** — one tracked work item.
- **prefix** — the database-wide ID prefix (e.g. `devtree-harness`).
- **ready** — open, with no active blockers; see `bd ready`.
- **blocked** — has an unresolved blocking dependency; see `bd blocked`.
- **dependencies** — issues this one depends on (its blockers).
- **dependents** — issues that depend on this one.
- **triage** — classifying an issue: type, priority, labels, parent, dependencies.
- **ephemeral / wisp** — short-lived, TTL-compacted issue; advanced, out of scope here.