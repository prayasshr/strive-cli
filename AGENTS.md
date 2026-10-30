# AGENTS.md

Rules for any AI agent (and any person) working on Strive CLI. Read this whole file before changing anything.

## 1. Read first

| File | What it holds |
|---|---|
| `docs/PRD.md` | What Strive must do and why. Requirements have IDs (SYNC-09, TIX-13). |
| `docs/SPEC.md` | Exactly how: commands, flags, statuses, exit codes, JSON, file formats. |
| `docs/decisions/` | Why the big choices were made. Don't reopen them without new information. |
| `docs/v1.4-plan.md` | The next release: the work list for the bash 1.4 fixes. |

If the code and the SPEC disagree, the SPEC wins. If the SPEC is wrong or silent, stop and say so. Propose the SPEC change first; write code after it is agreed.

## 2. Where things are

| Path | What |
|---|---|
| `bin/strive-sync`, `lib/*.sh` | v1 (bash). Fixes only, for the 1.4 line. Retires after 2.0. |
| `src/` | v2 (TypeScript). Not created yet. Layout in `src/README.md` once it exists. |
| `test/` | v2 tests: unit, git fixtures, end to end. |
| `docs/` | PRD, SPEC, decisions. |
| `.agents/` | Private notes. Git-ignored. Never reference it from public files. |

## 3. Commands

v2 (once `src/` exists): `pnpm install`, `pnpm test`, `pnpm lint`, `pnpm typecheck`, `pnpm build` (npm package), `pnpm build:bin` (Bun binaries).

v1: `shellcheck bin/strive-sync lib/*.sh`, then the fixture script in `test/v1/` (added with 1.4).

## 4. Hard rules

1. **Never claim success you did not verify.** Every process you run in Strive's code has its exit code checked [CORE-10]. The same applies to your own work: show real test output, never "tests should pass".
2. **Every behavior change has a test**, named after its requirement ID: `it("SYNC-09 never changes a feature branch", ...)`.
3. **Tests use temporary fixtures only.** Create bare remotes and clones in a temp folder. Never run tests or Strive against a developer's real repos, except `strive sync --dry-run` when the human asks.
4. **Never destructive** (decision 0002). No code path in `sync` may rebase, reset, stash, commit, push, force-update, delete, or write in a dirty repo.
5. **Generic only.** No company names, internal URLs, ticket key formats, repo names or people's names in code, docs, tests or examples. Use `acme`, `PROJ-142`, `api-service`, `web-app`, `Ana`, `Bo`.
6. **Node APIs only** (`node:*`). No Bun-only APIs (decision 0001).
7. **Ask before adding a runtime dependency.** Dev dependencies are fine.
8. **Contracts are contracts.** Exit codes, statuses, flags and JSON shapes change only with a SPEC change, and JSON changes follow SPEC 3.3.
9. **Cross-platform.** Use `node:path`, pass arguments as arrays (no shell strings) except for user-defined custom install commands, and expect Windows in CI.
10. **Don't commit or push unless the human asks.** When you suggest a commit message, use conventional commits and the requirement ID: `feat(sync): report not-pushed pinned branches (SYNC-11)`.

## 5. Style

- TypeScript `strict`. Small modules with one job each. Plain names.
- Comments are short and say why, not what.
- User-facing text follows SPEC 3.2: calm, lowercase statuses, no emoji, every error has a fix line.
- Docs: short sentences, plain words, no em dashes.

## 6. Definition of done

- [ ] The requirement IDs it covers are named in the tests and the commit message.
- [ ] Tests added or updated, and passing. Output shown.
- [ ] `pnpm lint` and `pnpm typecheck` clean.
- [ ] SPEC or PRD updated in the same change if behavior changed.
- [ ] `git grep` finds no company-specific strings.
- [ ] `CHANGELOG.md` not edited by hand (release-please writes it).

## 7. Working on v1 (bash, 1.4 line)

- Target bash 3.2 (macOS default): no associative arrays, no `mapfile`, no `${var,,}`.
- `shellcheck` clean.
- Test on fixtures in a temp folder. On real repos, dry run only, and only when the human asks.
- `~/.strive/bin/strive-sync` may be a symlink to this repo, so edits go live immediately for anyone using it. Work on a branch; keep `main` working.
