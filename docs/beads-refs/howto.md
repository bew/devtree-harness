# Beads howto

Practical procedures for using `bd` in a repository.
Companion to `data-model.md`; examples assume beads is initialized and you are in the repo.

## Find and triage work

Start from the work that is actually available:

- `bd ready` — open issues with no active blockers (excludes in_progress, blocked,
  deferred, hooked).
- `bd blocked` — issues waiting on a dependency.
- `bd list --status=open`, `bd list --label=needs-review`, `bd list --pretty`.
- `bd query "status=open AND priority<=2 AND updated>7d"` — compound filters.
- `bd show <id>`, `bd show <id> --thread`, `bd show <id> --children`.
- `bd dep tree <id> --direction=both` — what blocks it and what it blocks.
- `bd children <epic>` — everything under a parent.
- `bd stale`, `bd count`, `bd status` — overviews.

Triage by classifying as you learn: set `--type`, `--priority`, labels, and a `--parent`.

## Create a task

- `bd create --title="..." --description="..." --type=task`
- `bd create --title="..." -d "..." --type=bug --priority=P1 --labels=needs-review --parent <epic>`
- `bd q "quick capture"` — create and print only the ID.
- `bd create --dry-run` — preview without writing.

`--description` is the why; add `--acceptance`, `--design`, or `--spec-id` when you already
know them.
Priority is optional and defaults to `2`.

## Refine a task

- Replace content: `bd update <id> --description="..."`, `--design`, `--acceptance`.
- Link a spec: `bd update <id> --spec-id=<spec>`.
- Append running context: `bd note <id> "..."` (issue's notes field).
- Discuss or record decisions: `bd comment <id> "..."` (thread).
- Re-classify: `bd update <id> --type=... --priority=... --add-label=...`.

If refining reveals a concrete next action that is itself a unit of work, file it as a child
or a dependency task instead of burying it in a comment.

## Link tasks (dependencies)

- `bd dep add <issue> <depends-on>` — `<issue>` is blocked by `<depends-on>`.
- `bd dep add <issue> <depends-on> -t related` — any typed link.
- `bd link <id1> <id2> [--type=...]` — shorthand (`<id2>` blocks `<id1>`).
- `bd dep relate <a> <b>` — bidirectional `relates-to`.
- `bd create ... --deps 'discovered-from:bd-20,blocks:bd-15'`.

Inspect with `bd dep list <id> --direction=down|up`, `bd dep tree <id>`, `bd dep cycles`.

## Tag a task

- `bd tag <id> <label>` — add one label.
- `bd label add <label> <id...>`, `bd label remove <label> <id...>`.
- `bd update <id> --add-label=x --remove-label=y --set-labels=a,b`.
- `bd label list <id>` — one issue; `bd label list-all` — every label in the database.
- `bd label propagate <parent> <label>` — copy to children.

Tag vocabulary is ours; see `tags.md`.

## Progress and close

- `bd comment <id> "..."` as you make progress or take a decision.
- `bd update <id> --status=in_progress`; `bd update <id> --claim` also sets you as assignee.
- `bd update <id> --append-notes="..."` to extend the notes field.
- `bd close <id> --reason="..."`; `bd close <id> --suggest-next` shows what it unblocked.
- `bd reopen <id>` — reopen a closed issue.
- `bd defer <id>` / `bd undefer <id>` — park and restore.
- `bd supersede <old> <new>` — mark an issue replaced by another.

## Remember project facts

- `bd remember "<insight>"` — store a durable fact; `--key <key>` updates in place.
- `bd memories [search]` — list or search memories.
- `bd recall <key>` — retrieve one; `bd forget <key>` — remove it.

Memories are surfaced by `bd prime` and are independent of any issue.