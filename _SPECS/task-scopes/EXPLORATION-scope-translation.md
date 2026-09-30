# scope-translation — exploration

How a `:scope` selector typed on the command line is turned into the right `bd` label parameter, and which layer performs the rewrite.

## Findings

- `bd` has no global label flag; label params are per-verb and fall into three classes:
  - filter — `ready`/`list`/`count` take `-l/--label` (AND), `--label-any` (OR), `--label-pattern`, `--label-regex`; `query` uses `label=…`.
  - assign — `create -l/--labels`; `update --add-label`/`--remove-label`/`--set-labels`.
  - none — `close`, `show`, `dep`, `comment`, `note` expose no label param at all.
- So a `:scope` selector is not one rewrite: reads AND a filter, `create` assigns membership, `update` adds it, and on verbs with no label param it cannot be expressed at all.
- Label inheritance exists (`bd create --no-inherit-labels`), so a `scope:` on a parent may propagate to children.
- There is no label-related `bd config` namespace, so a wrapper is the only injection point.
- `bd` has native `-C/--directory` routing; `bdg`/`bdt` are thin over it.
- `bdg`/`bdt` exec `bd` from PATH, so the `bd` wrapper is the universal chokepoint for every invocation — direct or routed.

## Design crux

The trigger is explicit per-invocation: a `:scope` token typed on the command line, nothing persisted.
The host and token shape are settled; the open questions are how a scope segment is told apart from the existing devtree/project `:` addressing, and the per-verb semantics.

## Decisions

- (settled) Explicit per-invocation trigger; no ambient and no persisted active scope.
- (settled) The translation lives in the wrapper layer (`bdg`/`bdt`/`bd`) behind a shared implementation, not in a separate `t` binary.
- (settled) All three rewrite: `bdg`, `bdt`, and the `bd` wrapper each invoke the shared rewrite. NOTE — rewriting inside `bdg`/`bdt` contradicts the routing spec's pure-routing clause ("`bd` runs unmodified … no query interception"); that spec needs an amendment or an explicit exception.
- (settled) Grammar — `bd` (direct): a leading `:scope` token in the forwarded args, e.g. `bd :auth list`. `bdg`/`bdt`: a positional segment on the target, e.g. `bdg self:ghh:auth list`, `bdt ghh:auth list`.
- (settled) Two-segment `bdg` target: devtree names win. `ghh:auth` means devtree `ghh` + project `auth` when `ghh` is a known devtree, else project `ghh` + scope `auth`. (`bdt ghh:auth` is unambiguously project `ghh` + scope `auth` — `bdt` has no devtree segment.)
- (settled) Multiple scopes combine with AND; comma-separated: `bdg self:ghh:auth,ui`, `bdt ghh:auth,ui`. Filters map to repeated `--label scope:X`.
- (settled) Writes assign membership: `create` → `--labels scope:X`; `update` → `--add-label scope:X`.
- (settled) Verbs with no label param (`close`, `show`, `dep`, …): the scope is ignored with a warning (not an error).
- (settled) `bd query` is supported: `bd :auth query "…"` injects `label=scope:X AND …` into the query string.
- (settled) The routing spec (`_SPECS/cross-devtree-task-routing/SPEC.md`) is amended now to permit the scope rewrite in `bdg`/`bdt`.

## Candidate directions

- (settled) **Host = shared module called by each of `bdg`/`bdt`/`bd`.**
- (rejected) **Host = bd wrapper only**, leaving `bdg`/`bdt` as pure routers.
- (rejected) **Dedicated `--scope` flag.**
- (settled) **Token shape = leading `:name` for direct `bd`, positional segment for `bdg`/`bdt`.**
- (settled) **Disambiguation — devtree names win.**
- (settled) **Multi-scope = AND, comma-separated.**

## Open threads

- For direct `bd`, where exactly does the leading `:scope` token sit (first positional, before the verb), and how is it escaped if a literal arg starts with `:`?
- Edge: `bdg work:auth` where `work` is a devtree resolves to devtree `work` + project `auth`, so the devtree root's own scope is not addressable in the two-segment form.
- Warning channel and wording for ignored scopes (stderr, exit status unchanged).
- `show` cannot filter server-side, so scope silently no-ops there — confirm acceptable.
