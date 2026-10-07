---
name: repo-tasks
description: |
  Use when the user asks about this repo's tasks or backlog — what to work on next,
  listing/searching/showing issues, priorities, dependencies, tags — or wants a task
  created, refined, or triaged. Repo tasks are tracked in beads (`bd`). Not for
  in-session scratch work.
metadata:
  maintainers: [bew]
---

# repo-tasks

## Goal

Answer questions about this repo's tasks and keep them triaged and up to date.

## When this applies

Repository-level work items — bugs, features, chores — that persist across sessions and are shared.
This covers finding, creating, refining, and triaging them.
The agent's own intermediate steps within a session are not repo tasks;
use the normal todo tool for those.

## Steps

1. **Find** — inspect the backlog:
   - `bd ready` for unblocked tasks ready to pick up.
   - `bd blocked` for an overview of tasks waiting on a dependency.
   - `bd list --status=open`, or `bd query "status=open AND priority<=2"` for compound filters.
   - `bd show <id>` for one task; `bd show <id> --thread` for its comments;
     `bd show <id> --children` for its children.
   - `bd dep tree <id> --direction=both` for what blocks it and what it blocks.
   - `bd search <query>` to find tasks by text.
   - `bd memories` to recall stored project facts.
2. **Create** — file a new task:
   `bd create --title="..." --description="..." --type=task`.
   Types are `task`, `bug`, `feature`, `chore`, `epic`, `decision`, `spike`, `story`, `milestone`.
   Priority is optional and defaults to `2`.
3. **Refine** — small updates are welcome; you do not need to capture everything at once:
   - `bd note <id> "..."` appends to the issue's notes; `bd comment <id> "..."` adds to its thread.
   - `bd update <id> --description=... --design=... --acceptance=...` extends the task's
     own content.
   - `bd update <id> --spec-id=<spec>` links a spec you just wrote.
   - If a refinement names a concrete next action that is its own unit of work, file it as a
     child or a dependency task rather than burying it in a comment.
4. **Link** — record relationships with typed dependencies:
   `bd dep add <issue> <depends-on>` means `<issue>` is blocked by `<depends-on>`.
   Add `-t <type>` for other links: `blocks`, `tracks`, `related`, `parent-child`,
   `discovered-from`, `until`, `caused-by`, `validates`, `relates-to`, `supersedes`.
   `bd link <id1> <id2>` is shorthand, and `bd dep relate <a> <b>` is bidirectional.
5. **Tag** — label a task with `bd tag <id> <label>` or `bd label add <label> <id...>`.
   The tag vocabulary is ours and lives in `docs/beads-refs/tags.md` (no fixed set yet).
6. **Remember** — store a durable project fact with `bd remember "<insight>"`.
   Pass `--key <key>` to update an existing memory in place.

## Rules

- Repo tasks live only in beads.
- Never track repo tasks in markdown files or the todo tool.
- The todo tool is for in-session steps only.
- Never run `bd edit` — it opens `$EDITOR` and blocks.
- Priority is optional; when set it is 0-4 (or P0-P4), never words like "high".

## Guidelines

- Start from `bd ready` before picking up work; use `bd blocked` for the blocked overview.
- Always give a `--description` explaining why the task exists.
- Refining a task a little at a time is fine — a comment or a note counts as an update.
- Use the global `--json` flag when another tool consumes the output.