---
name: repo-progress-work
description: |
  Use when making any progress on a beads task — a small step, a decision, or a
  partial result — not only when finishing it. Covers reporting progress, adding
  comments, and closing. Repo tasks are tracked in beads (`bd`). Not for in-session
  scratch work.
metadata:
  maintainers: [bew]
---

# repo-progress-work

## Goal

Keep a beads issue's record current while you work on it, even in small increments.

## Steps

1. **Work** — do the task.
2. **Report** — keep the issue as the record, at any size of progress:
   - `bd comment <id> "..."` for a small step, a partial result, or a decision.
   - `bd note <id> "..."` to append to the issue's own notes.
3. **Close** — `bd close <id> --reason="..."`; pass several ids to close a batch at once.

## Rules

- Report progress on the issue, not only in chat.
- A partial step or a decision is worth a comment.
- Never run `bd edit` — it opens `$EDITOR` and blocks.

## Guidelines

- `bd close <id> --suggest-next` shows what the close unblocked.
- `bd defer <id>` for work that should wait.
- `bd supersede <old> <new>` when a task replaces another.