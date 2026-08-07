# Codex Agent Notes

This repository already keeps most project-specific agent guidance in Cursor files.
Codex should use those files as the source of truth instead of duplicating them here.

## Before Making Changes

- Read the relevant files under `.cursor/rules/*.mdc`.
- For grammar, parser, or architecture changes, read the relevant `.cursor/skills/*/SKILL.md`.
- Treat Cursor rules as project instructions unless they conflict with an explicit user request or higher-priority Codex/system instructions.

## Common Cursor Rules To Check

- `.cursor/rules/workspace-junctions.mdc` for local `.temp/` and `.notes/` junctions (when present).
- `.cursor/rules/pdm-package-manager.mdc` before Python/package workflow changes.
- `.cursor/rules/auto-commit-message.mdc` before preparing commits.

## Common Cursor Skills To Check

- `.cursor/skills/tree-sitter-bsl-grammar/SKILL.md` for grammar, parser, generated parser files, and corpus/test changes.

# Project Rules for Agents

These rules apply to the whole repository.

## Project Context

`tree-sitter-bsl` is a tree-sitter grammar repository for 1C BSL and, by
`docs/decisions/0001-add-sdbl-query-language-grammar.md`, a separate `sdbl`
grammar for the 1C query language.

The repository owns grammar behavior and parser-facing contracts:

- `grammars/bsl/grammar.js` as the BSL source grammar.
- `grammars/bsl/test/corpus/*.bsl` as the BSL behavioral regression contract.
- `grammars/bsl/src/grammar.json`, `grammars/bsl/src/node-types.json`,
  `grammars/bsl/src/parser.c` and BSL
  binding-facing generated artifacts when BSL grammar generation is part of the
  change.
- `grammars/sdbl/grammar.js` as the planned SDBL source grammar.
- `grammars/sdbl/test/corpus/*.sdbl` as the planned SDBL behavioral regression
  contract.
- `grammars/sdbl/src/grammar.json`, `grammars/sdbl/src/node-types.json` and
  `grammars/sdbl/src/parser.c` as planned SDBL generated artifacts when SDBL
  grammar generation is part of the change.
- `spec/sdbl-syntax/` as the vendored source snapshot for 1C query-language
  syntax.
- Node, Rust and Python bindings only as parser package integration surfaces.

The repository does not own analyzer facts, diagnostics, metadata models, HBK
facts, query tools, report formats or downstream product behavior. Keep those
concerns out of grammar changes unless a later accepted project decision adds a
local contract for them.

Use `spec/IMPLEMENTATION_TODO.md` as the active parser-work ledger. Keep
completed parser-work history under `spec/archive/`. Use
`spec/sdbl-query-language.md` and `spec/sdbl-source-evidence.md` for the durable
SDBL grammar contract and source evidence. `README.md` is user-facing
orientation and package usage documentation, not the implementation ledger. When
README, chat notes, comments or task text conflict with the ledger, reconcile
`spec/IMPLEMENTATION_TODO.md` before implementation.

## Implementation Order

For non-trivial grammar work, follow this order:

1. Read `spec/IMPLEMENTATION_TODO.md` and the relevant
   `grammars/bsl/grammar.js` rules.
   For SDBL work, also read `spec/sdbl-query-language.md`,
   `spec/sdbl-source-evidence.md` and the relevant `grammars/sdbl/grammar.js`
   rules once that file exists.
2. Add or update focused corpus cases before changing grammar behavior.
3. Implement only the active syntax behavior and its direct verification.
4. Regenerate parser artifacts when the grammar changes.
5. Update `spec/IMPLEMENTATION_TODO.md`, README or release notes when the
   durable parser contract, validation command or public node shape changed.

Keep implementation small and grammar-specific. Do not introduce broad
compatibility layers, hidden fallbacks, generic parser pipelines or downstream
consumer adapters just to make a syntax case pass.

## Grammar Rules

Test and implement concrete BSL syntax behavior, not broad approximations.

- Prefer precise grammar rules over catch-all tokens.
- Do not accept invalid BSL only to avoid `ERROR` nodes.
- Do not accept invalid SDBL only to avoid `ERROR` nodes.
- Keep BSL and SDBL grammar behavior separate until a later accepted decision
  defines embedded query parsing for BSL strings.
- Keep structured preprocessor parsing for `#Если` / `#Область`; do not replace
  it with a generic skipped-line token.
- Use `lezer-bsl` snippets only as candidate input examples. Do not copy Lezer
  AST node names, visitors or failing expectations as the tree-sitter contract.
- Preserve existing node shapes where practical. If a node-shape migration is
  necessary, document it in tests and release notes.
- Keep unknown or intentionally unsupported syntax explicit in the ledger
  instead of hiding it in ad-hoc probes.

## Testing Rules

Test observable parser behavior.

- Corpus tests should describe the syntax contract being protected.
- Expected trees must use the current tree-sitter node style for this project.
- Do not test private helper order or incidental `grammar.js` decomposition.
- Prefer small corpus sections grouped by syntax feature over one large imported
  dump.
- Use deterministic BSL snippets for focused syntax coverage.
- Use real project files only as acceptance corpus inputs and never mutate those
  external checkouts during parser validation.

Normal validation:

- `npm test` verifies that the Node binding loads.
- `tree-sitter test -p grammars/bsl` validates BSL corpus expectations when the
  local CLI works.
- `tree-sitter test -p grammars/sdbl` validates SDBL corpus expectations after
  the SDBL grammar scaffold exists.
- Targeted Node binding probes are acceptable only as temporary diagnostics when
  the tree-sitter CLI is blocked on the current host.

## Worktree Discipline

Generated artifacts, dependency directories and unrelated local changes may
exist in the checkout. Inspect scope before editing or committing, and do not
revert user-owned changes. Keep commits narrow: grammar changes, corpus changes,
generated parser updates and documentation updates should be grouped only when
they belong to the same parser behavior.

<!-- agent-rules:begin | управляется sync-agent-rules.py, правьте dev-utils/agent-rules/ -->

## External project notes

This project may have a `.notes` directory that points to external working notes.

Rules for using `.notes`:

- `.notes` is not automatically authoritative.
- Prefer `.notes/_current.md` as the curated current context.
- Treat other notes as non-authoritative unless they have explicit metadata such as `status: active` or `status: reference`.
- Treat `.notes/00-inbox/`, `.notes/30-someday/`, `.notes/80-completed/`, `.notes/90-archive/`, old plans, drafts and raw imported notes as historical or unprocessed context only.
- Folders `.notes/10-urgent/` and `.notes/20-active/` may hold current task notes; still verify them against the repository before acting.
- Closed tasks live in `.notes/80-completed/`; reference, dumps and historical material live in `.notes/90-archive/`.
- Source code, tests, configs, migrations, build scripts and repository files override external notes.
- If an external note conflicts with repository files, do not silently follow the note. Mention the conflict and prefer the repository.
- Do not perform large changes based only on old notes. First verify against current code and current project instructions.

## Python dependencies: PDM without uv

Dependencies and the lock file go through PDM only (`pdm add`, `pdm update`, `pdm sync`).

`PDM_USE_UV` must stay **unset** in every environment — Windows, WSL and the dev
container alike. The uv resolver does not support PDM's `inherit_metadata` lock
strategy and silently discards it. When that happens, `requires_python` and `groups`
disappear from every entry in `pdm.lock`, so the lock no longer records which group a
package belongs to. Updating a single package rewrites roughly 600 lines.

A mixed setup is the worst case: with uv enabled on one machine and disabled on
another, `pdm.lock` flips between `strategy = ["inherit_metadata"]` and
`strategy = []` on every update, producing conflicts across the whole file.

`PDM_USE_UV` is an environment variable and overrides a per-project `pdm.toml`, so the
setting cannot be pinned inside the repository. Check the environment before locking:

```sh
pdm config use_uv   # must report False
```

<!-- agent-rules:end -->
