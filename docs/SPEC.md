# Strive CLI: Specification

| | |
|---|---|
| Spec version | 2.0-draft.3 (2026-10-30) |
| Covers | `init`, `sync`, `status`, `tickets` (v2.0); `standup` (v2.1, preview) |
| Requirements | `docs/PRD.md`. IDs in brackets, e.g. [SYNC-09], point there. |

This document is the contract. Code and tests follow it. If the code and this document disagree, this document wins; if this document is wrong or silent, change it first, then the code.

Names in examples (`acme`, `api-service`, `PROJ-142`) are placeholders.

---

## 1. Command line

### 1.1 Grammar

```
strive [global flags] <command> [subcommand] [arguments] [flags]
```

- Flags may appear anywhere after `strive`. `--` ends flag parsing.
- Long flags use `--kebab-case`. Short forms exist only where listed.
- `strive` with no command prints the overview (1.5).
- `strive help [command]` and `strive <command> --help` print help. Help goes to stdout and exits 0.
- An unknown command or flag exits 2 and suggests the closest match.

### 1.2 Commands and aliases

| Command | Alias | Since | Stability |
|---|---|---|---|
| `strive init` | | 2.0 | stable |
| `strive sync` | | 2.0 | stable |
| `strive status` | | 2.0 | stable |
| `strive tickets` | `strive t` | 2.0 | stable |
| `strive standup` | | 2.1 | preview in 2.1 |
| `strive help status <name>` | | 2.0 | stable |

Preview commands may change flags and JSON shapes in the next minor release. Stable ones change only in a major release.

### 1.3 Global flags

| Flag | Meaning |
|---|---|
| `--json` | Print one JSON document to stdout (section 3). Nothing else goes to stdout. |
| `--plain` | No live view and no colors; one line per item. Default when stdout is not a terminal. |
| `--quiet`, `-q` | Print only the summary, "needs you" items and failures. |
| `--verbose` | Also print each subprocess command line, and the log path for every item. |
| `--cwd <dir>` | Run as if started in `<dir>`. |
| `--yes`, `-y` | Answer yes to confirmations. Never asked for in non-interactive runs; without it, a confirmation there exits 2. |
| `--no-color` | Disable color. `NO_COLOR` (any value) does the same. |
| `--version`, `-v` | Print `strive <version>` and exit 0. |
| `--help`, `-h` | Print help and exit 0. |

### 1.4 Environment variables

| Variable | Meaning |
|---|---|
| `NO_COLOR` | Disable color. |
| `STRIVE_CONFIG` | Path of the user config file (default in 4.4). |
| `STRIVE_STATE_DIR` | Override the state folder (4.5). Used by tests. |

Precedence for every setting: flag, then environment, then workspace config, then user config, then built-in default.

### 1.5 Overview (`strive` with no command)

```
Strive CLI 2.1.0 · Ready to work. Honestly reported.

Workspace  ~/code (5 repos, from .repos)

  init      Save the repo list so runs start instantly
  sync      Every repo current, right runtime, deps installed
  status    Where you left things
  tickets   Notes for each piece of work (alias: t)
  standup   Facts for your standup

Run `strive <command> --help` for details.
```

### 1.6 First run with nothing to work on [INIT-03]

When the workspace has no repo list, no config, and discovery finds no repos, `strive` and `strive sync` print this and exit 3:

```
No repos here yet. To get started:

  Your team has a shared workspace?   strive init --from <git url>
  Your repos are somewhere else?      cd to that folder and run strive sync
  Starting fresh?                     git clone <url>, then strive sync
```

### 1.7 Status help [CORE-22]

`strive help status <name>` prints two or three plain sentences: what the status means, why Strive left the repo alone (if it did), and the command that usually fixes it. Every status in 5.4 and 7.2 has an entry.

---

## 2. Exit codes [CORE-09]

| Code | Meaning |
|---|---|
| 0 | Done. Everything is ready. |
| 1 | Something failed (a fetch, merge, clone, install, write, or validation). |
| 2 | Bad usage or invalid config. Nothing was changed. |
| 3 | Done, nothing failed, but something needs the user. |
| 130 | Interrupted (Ctrl-C). |

When a run has several outcomes, the highest-priority code wins: 130, then 2, then 1, then 3, then 0.

---

## 3. Output [CORE-06, CORE-07, CORE-08]

### 3.1 Modes

| Mode | When | Behavior |
|---|---|---|
| Live | stdout is a terminal, no `--plain`/`--json` | Rows redraw in place while work runs; the final screen equals the plain output. |
| Plain | stdout is not a terminal, or `--plain` | No control codes, no color. Rows print as items finish, then the summary. |
| JSON | `--json` | One JSON document on stdout at the end. Progress and warnings go to stderr only with `--verbose`. |

### 3.2 Text style

- Statuses are lowercase words (`updated`, `dirty`). Meaning never depends on color.
- Colors: green for ok, yellow for needs you, red for failed, dim for details.
- No emoji. No ASCII art. No battery or "mission" wording.
- Durations: `850ms`, `12s`, `1m04s`. Paths relative to the workspace root when inside it.
- Errors use this shape:

```
error: <what went wrong>
  <why, one line>
  fix: <the command or action that fixes it>
```

### 3.3 JSON rules

- Every document has `"schema": "strive.<name>/<major>"` and `"strive": "<cli version>"`.
- Keys are camelCase. Times are ISO 8601 with offset. Durations are `...Ms` integers. Paths are absolute.
- A field that has no value is `null`, never missing.
- Adding a field is not a breaking change. Removing or renaming a field, or changing its type or meaning, is: it bumps the schema major and the CLI major.
- Status classes are `"ok"`, `"needsYou"`, `"failed"`.
- On exit 2, the document is:

```json
{ "schema": "strive.error/1", "strive": "2.0.0",
  "error": { "code": "config_invalid", "message": "…", "file": "/abs/.strive/config.yml", "fix": "…" } }
```

---

## 4. Workspace and files

### 4.1 Workspace root [CORE-04]

Starting at the current folder (or `--cwd`), walk up toward the filesystem root. The first folder containing any of these **files** is the workspace root:

1. `.repos`
2. `.strive/config.yml`
3. `.strive/tickets.yml`

A `.strive/` folder alone is not a marker (older versions installed tools into `~/.strive/bin`). If nothing is found, the current folder is the workspace root.

### 4.2 `.repos` [SYNC-02]

Plain text, UTF-8, LF or CRLF.

```
# one repo per line
api-service                                   # follow the remote default branch
web-app:feat/new-nav                          # pinned to a branch
design-tokens  git@github.com:acme/tokens.git # cloned if missing
```

Grammar per line, after trimming whitespace:

```
line   = empty | "#" comment | entry [ whitespace "#" comment ]
entry  = path [ ":" branch ] [ whitespace url ]
```

- `path` is relative to the workspace root, uses `/`, and contains no `:` or whitespace.
- `branch` is a git branch name (git forbids `:` in branch names, so the first `:` splits).
- `url` is anything `git clone` accepts.
- A `#` only starts a comment at the start of a line or after whitespace.
- Duplicate paths: exit 2.

When Strive edits `.repos` (`tickets start`, `tickets done`), it changes only the affected line's branch part and keeps every comment, blank line and order. New entries are appended.

### 4.3 `.strive/config.yml` (optional)

```yaml
schema: 1
repos:                          # optional: adds repos and sets options per repo
  api-service:
    install: make setup         # custom install command (section 6.4)
    watch: [Makefile, setup.cfg]  # files whose change triggers the custom install
  legacy-app:
    skip: true                  # listed but never synced
  payments:
    branch: release/2.x         # pin (same as payments:release/2.x in .repos)
    url: git@github.com:acme/payments.git
    remote: upstream            # default: origin
sync:
  parallel: 6                   # default: number of CPUs, max 8
  install: true                 # default: true
  ignoreUntracked: false        # default: false (untracked files count as dirty)
  timeouts:
    fetch: 60                   # seconds, default 60
    install: 900                # seconds, default 900
  notes:
    migrations: ["**/migrations/**", "db/migrate/**", "prisma/migrations/**", "alembic/versions/**"]
runtime:
  manager: auto                 # auto | mise | asdf | fnm | nvm | volta | pyenv | none
workdays: [mon, tue, wed, thu, fri]   # used by standup
```

Repos listed in `.repos` and in `config.yml` are merged by path. A setting in `config.yml` overrides `.repos` for that repo. Unknown keys: exit 2.

### 4.4 User config

`~/.config/strive/config.yml` (or `$XDG_CONFIG_HOME/strive/config.yml`; `%APPDATA%\strive\config.yml` on Windows; or `$STRIVE_CONFIG`). Same `sync`, `runtime` and `workdays` keys as workspace config; no `repos`.

### 4.5 State and logs [CORE-17, CORE-18]

Folder: `$XDG_STATE_HOME/strive/` (default `~/.local/state/strive/`; `%LOCALAPPDATA%\strive\state\` on Windows; or `$STRIVE_STATE_DIR`).

```
runs/<run-id>.json              last 100 runs: per-repo status and timing [SYNC-22]
logs/<YYYY-MM-DD>/<run-id>/<repo>.log    full output of every subprocess, kept 14 days
installs.json                   per repo root: lockfile hash and time of last successful install
```

`run-id` is `YYYYMMDD-HHMMSS-<4 hex>`. Strive never writes state into the workspace.

### 4.6 Writing files [CORE-13]

Every file Strive changes is written to a temp file in the same folder, then renamed over the original. Immediately before the rename, Strive checks the original's size and modification time against what it read; if either changed, it aborts that write with exit 1 and says which file changed.

---

## 5. `strive sync`

### 5.1 Synopsis

```
strive sync [repo...] [--exclude <repo>]... [--branch <name>] [--switch]
            [--no-install] [--force-install] [--dry-run] [--offline]
            [--pick] [--parallel <n>] [--report <file.md>]
```

| Flag | Meaning | Req |
|---|---|---|
| `repo...` | Only these repos (paths as listed). | SYNC-01 |
| `--exclude <repo>` | Skip this repo. Repeatable. | SYNC-04 |
| `--branch <name>` | Target branch for repos without a pin. | SYNC-06 |
| `--switch` | Switch clean repos to their target branch first. | SYNC-10 |
| `--no-install` | Do not install dependencies. | SYNC-13 |
| `--force-install` | Install dependencies in every repo, needed or not. | SYNC-13 |
| `--dry-run` | Fetch, then report what would happen. Nothing else changes. | SYNC-23 |
| `--offline` | Do not fetch. Implies nothing new can arrive. | SYNC-23 |
| `--pick` | Interactive picker for repos and options (terminal only, else exit 2). From v2.1. | SYNC-24 |
| `--parallel <n>` | Max repos at once. Installs run at most `max(1, n/2)` at once. | CORE-20 |
| `--report <file>` | Also write a markdown report of the run. | |

### 5.2 Repo list [SYNC-01, SYNC-03]

1. If `repo...` is given, use those.
2. Else merge `.repos` and `config.yml` repos (4.3).
3. Else discover: folders up to depth 5 below the workspace root containing `.git`, without descending into `node_modules`, `.venv`, `venv`, `vendor`, `target`, `dist`, `build`, `.next`, `.cache`, `Pods`.

Then remove `--exclude` entries and `skip: true` repos (reported as `skipped`).

**Grouping.** For each entry resolve `git rev-parse --show-toplevel` and `--git-common-dir`:
- Entries with the same top level are one repo. It is shown once, named after the first entry, with the others listed as aliases.
- Git steps run once per repo. Dependencies are per folder: the repo's folder and each alias folder are checked and installed on their own (section 6), each with its own lockfile and the nearest runtime version file up to the repo root. A subfolder with its own manifest (e.g. `web-app/ui`) only gets installs because it is listed.
- Repos with the same common dir (linked worktrees) are separate repos but run one after another, never in parallel.

### 5.3 Per-repo steps

All git commands run with `GIT_TERMINAL_PROMPT=0`, `GIT_SSH_COMMAND="ssh -o BatchMode=yes"` (unless the user already set `GIT_SSH_COMMAND`), and the fetch timeout. [CORE-11]

1. **Exists?** Folder missing: status `missing`. From v2.1, if a URL is known, `git clone <url> <path>` instead (status `cloned`, then continue as a fresh repo). [SYNC-12]
2. **Busy?** A rebase, merge, cherry-pick, revert or bisect in progress: status `busy`. Stop.
3. **Dirty?** `git status --porcelain` non-empty (ignoring untracked files if `ignoreUntracked`): status `dirty`. Stop. No git command that writes runs. [SYNC-05]
4. **Detached?** HEAD not on a branch: status `detached`. Stop.
5. **Target.** Pinned branch, else `--branch`, else the remote default branch: `refs/remotes/<remote>/HEAD`, or if that is unset, `git ls-remote --symref <remote> HEAD`. Strive never changes the remote's HEAD setting. [SYNC-06]
6. **Switch.** With `--switch` and current branch ≠ target: `git switch <target>` (creating it to track `<remote>/<target>` if needed). [SYNC-10]
7. **Fetch.** Fetch the default branch and, if different, the target branch. If the target branch does not exist on the remote, status `not-pushed`: the default branch is still fetched, step 8 and 10 are skipped, step 9 runs. Skipped with `--offline`. [SYNC-07, SYNC-11]
8. **Decide and move**, comparing `HEAD` with `<remote>/<target>`:

| Situation | Action | Status |
|---|---|---|
| On target, equal | none | `ready` |
| On target, behind | `git merge --ff-only <remote>/<target>` | `updated` |
| On target, ahead | none | `ahead` |
| On target, both have new commits | none | `diverged` |
| On another branch | Never touch it. If a local default branch exists, is not checked out anywhere and fast-forwards: `git fetch <remote> <default>:<default>`. Count commits behind `<remote>/<default>`. If behind, run the conflict forecast. | `ready` if not behind, `behind` if the forecast is clean or unavailable, `will-conflict` if it conflicts |

   Conflict forecast (v2.1; before that, `behind` is reported without it): `git merge-tree --write-tree --name-only HEAD <remote>/<default>` (git 2.38+). Exit 1 means conflicts; the conflicted paths are reported. On older git the forecast is skipped and noted. [SYNC-09]

9. **Dependencies.** See section 6. A failed install makes the repo `failed` (step `install`) even if git succeeded.
10. **What came in.** For `updated` repos, compare the commit before and after (section 5.5). [SYNC-20]

The commit before step 8 is saved and used for all "changed in this run" checks (never `HEAD@{1}`).

### 5.4 Statuses [SYNC-19]

| Status | Class | Meaning | "Needs you" action text |
|---|---|---|---|
| `ready` | ok | Already current | |
| `updated` | ok | Fast-forwarded | |
| `ahead` | ok | Has local commits the remote doesn't; nothing to pull | |
| `behind` | ok | On another branch; the default branch moved; a rebase would not conflict | |
| `not-pushed` | ok | Pinned branch doesn't exist on the remote yet | |
| `cloned` | ok | Was missing; cloned | |
| `skipped` | ok | Excluded by flag or config | |
| `will-conflict` | needsYou | On another branch; rebasing onto the default branch would conflict | `Rebase <branch> onto <default>; conflicts expected in <n> files` |
| `dirty` | needsYou | Uncommitted changes; nothing was touched | `Commit or stash your changes, then sync again` |
| `diverged` | needsYou | Local and remote both have new commits | `Rebase or merge <branch> with <remote>/<branch>` |
| `detached` | needsYou | Not on a branch | `Switch to a branch, then sync again` |
| `busy` | needsYou | A rebase, merge or similar is in progress | `Finish or abort the <operation> in progress` |
| `missing` | needsYou | Folder not found and no clone URL | `Clone it, add a URL in .repos, or remove the line` |
| `failed` | failed | A step failed; `failedStep` is `fetch`, `merge`, `switch`, `clone` or `install` | the error's fix line |

Action texts are written for someone in their first week: what happened in plain words, then the command. Final wording lives with the `strive help status` entries (1.7) and is reviewed as user-facing copy. Example for `diverged`: `Your branch and the remote both have new commits. When ready: git pull --rebase`.

**Failure reasons.** Every `failed` repo, and every `missing` or runtime problem, gets a `failureReason`: `auth` (git could not authenticate), `network` (host unreachable or DNS), `timeout`, `runtime-missing` (wanted runtime version not installed), `tool-missing` (package or version manager not found), `lockfile-mismatch` (frozen install refused because the lockfile is out of date), `not-found` (remote repo or branch gone), or `other`.

### 5.5 What came in [SYNC-20]

For `updated` repos, between the saved before-commit and the new `HEAD`:

| Item | How |
|---|---|
| Commits and authors | `git log --format=%an <before>..HEAD` |
| Runtime version | Any runtime version file (6.3) whose content changed: old and new value |
| Dependencies | Adapter compares the manifest before and after: names added and removed |
| Env keys | `.env.example`, `.env.sample`, `.env.template`: key names added and removed. Values are never read into output. [CORE-16] |
| Notes | New files matching `sync.notes.migrations` globs; anything an adapter reports |

### 5.6 Text output

```
  api-service   main         updated  +12 commits · node 20 → 24 · deps installed (npm ci 41s)   52s
  web-app       feat/search  behind   main +14 · rebase would not conflict                       3s
  billing       main         ready                                                             2s
  docs-site     main         dirty    3 files changed, not touched                             0s

4 repos in 54s · 3 ok · 1 needs you · 0 failed

Needs you
  docs-site   Commit or stash your changes, then sync again
```

Failure detail adds two indented lines: the last line of the failing command's output and the log path.

**Grouping [SYNC-26].** In the "Needs you" list and the failure list, repos with the same `failureReason` (and, for `runtime-missing`, the same tool) are combined into one item when there are two or more:

```
Failed
  12 repos   git could not log in (no SSH key set up for github.com)
             fix: https://docs.github.com/authentication/connecting-to-github-with-ssh
             api-service, web-app, billing, … (9 more)

Needs you
  4 repos    need Node 24, which is not installed
             fix: nvm install 24
             api-service, web-app, docs-site, admin
```

The per-repo rows above the summary are unchanged; only the summary groups.

**Dry run** text: the first line is `dry run: fetched only, nothing else changed`; action statuses read `would update`, `would clone`, `would install`; the summary ends with `(dry run)`.

### 5.7 JSON (`strive.sync/1`)

```json
{
  "schema": "strive.sync/1",
  "strive": "2.0.0",
  "workspace": "/home/dev/code",
  "runId": "20261103-083012-a1f3",
  "dryRun": false,
  "startedAt": "2026-11-03T08:30:12-07:00",
  "durationMs": 54012,
  "summary": { "repos": 4, "ok": 3, "needsYou": 1, "failed": 0 },
  "repos": [
    {
      "name": "api-service",
      "path": "/home/dev/code/api-service",
      "aliases": [],
      "status": "updated",
      "class": "ok",
      "failedStep": null,
      "failureReason": null,
      "message": null,
      "action": null,
      "branch": "main",
      "target": "main",
      "defaultBranch": "main",
      "git": { "before": "3f2a91c", "after": "8be0d47", "commits": 12, "authors": ["Ana", "Bo"],
               "ahead": 0, "behind": 0, "forecast": null, "conflictFiles": [] },
      "runtime": { "file": ".nvmrc", "wanted": "24", "manager": "nvm", "changedFrom": "20" },
      "deps": { "status": "installed", "adapter": "node", "tool": "npm", "command": "npm ci",
                "reason": "lockfile changed", "durationMs": 41020 },
      "changes": { "depsAdded": ["zod"], "depsRemoved": [], "envAdded": ["PAYMENTS_KEY"],
                   "envRemoved": [], "notes": [] },
      "log": "/home/dev/.local/state/strive/logs/2026-11-03/20261103-083012-a1f3/api-service.log",
      "durationMs": 52001
    }
  ],
  "needsYou": [
    { "repos": ["docs-site"], "status": "dirty", "failureReason": null,
      "action": "Commit or stash your changes, then sync again" }
  ],
  "failures": []
}
```

`needsYou` and `failures` hold the grouped items (5.6): each has `repos` (one or more), `status`, `failureReason` and `action`.

`deps.status` is one of `installed`, `unchanged`, `skipped` (disabled), `none` (nothing to install), `failed`. `git.forecast` is `null`, `"clean"`, `"conflict"` or `"unavailable"`. In a dry run every field describes the predicted result.

### 5.8 Exit codes

1 if any repo is `failed`; else 3 if any is `needsYou`; else 0.

### 5.9 Interrupt [CORE-12]

On Ctrl-C: start no new repo; send SIGTERM to every running child process group, SIGKILL after 5 seconds; mark unfinished repos `failed` with message `interrupted`; print the summary once; exit 130. A second Ctrl-C exits immediately.

### 5.10 Picker (`--pick`)

A checklist of repos (all selected) and options (`--switch`, install, `--force-install`, `--dry-run`), pre-set from the flags given. Arrow keys move, space toggles, enter runs, `q` or Esc exits 0 without running.

---

## 6. Runtimes and dependencies

### 6.1 When to install [SYNC-13, SYNC-14]

With install enabled, a repo's dependencies are installed when any of these is true:

1. `--force-install`.
2. The dependency folder (6.2) is missing.
3. A manifest or lockfile changed between the before-commit and `HEAD` in this run.
4. `installs.json` has a record for this repo and the lockfile hash differs from it.

With no record and the dependency folder present (first run), Strive records the current hash and installs nothing (`deps.reason: "baseline recorded"`). After every successful install, the hash is recorded.

Installs never run in `dirty`, `busy`, `detached`, `diverged` or `failed` repos.

### 6.2 Adapters [SYNC-15, SYNC-17]

An adapter detects an ecosystem and returns: lockfiles, manifest files, dependency folder, install command, runtime version files, and manifest dependency names. A repo can match more than one adapter (e.g. Node and Python); each runs, one after another.

**Node** (detected by `package.json`)

| Tool | Chosen when | Install command | Deps folder |
|---|---|---|---|
| pnpm | `packageManager: pnpm@…`, else `pnpm-lock.yaml` | `pnpm install --frozen-lockfile` | `node_modules` |
| yarn 2+ | `packageManager: yarn@2+`, else `yarn.lock` + `.yarnrc.yml` | `yarn install --immutable` | `node_modules` or `.pnp.cjs` |
| yarn 1 | `packageManager: yarn@1…`, else `yarn.lock` | `yarn install --frozen-lockfile --non-interactive` | `node_modules` |
| bun | `packageManager: bun@…`, else `bun.lock` or `bun.lockb` | `bun install --frozen-lockfile` | `node_modules` |
| npm | `packageManager: npm@…`, else `package-lock.json` or `npm-shrinkwrap.json` | `npm ci` | `node_modules` |

- `packageManager` wins over lockfiles. Several lockfiles and no `packageManager`: the order above decides, with a note.
- No lockfile: `npm install --no-package-lock` (never creates a lockfile), with a note.
- Manifest: `package.json` (`dependencies`, `devDependencies`, `optionalDependencies`, `peerDependencies`).
- Runtime version files: `.nvmrc`, `.node-version`, `.tool-versions` (`nodejs`), `mise.toml` / `.mise.toml` (`node`).

**Python** (detected by `pyproject.toml` or `requirements.txt`; from v2.1)

| Tool | Chosen when | Install command | Deps folder |
|---|---|---|---|
| uv | `uv.lock` | `uv sync --locked` | `.venv` |
| poetry | `poetry.lock` | `poetry install` | the Poetry env |
| pip | `requirements.txt` and an existing `.venv/` or `venv/` | `<venv>/bin/python -m pip install -r requirements.txt` | the venv |

- pip without an existing virtualenv: `deps.status: "none"`, note `no virtualenv; not installing into the system Python`.
- Runtime version files: `.python-version`, `.tool-versions` (`python`), `mise.toml` (`python`).

**Custom** (from `repos.<path>.install` in config). Runs the command with the platform shell (`sh -c`, or `cmd /c` on Windows) in the repo folder. Change detection uses `watch` files; without `watch`, it runs only with `--force-install` or when its record is missing.

### 6.3 Runtime versions [SYNC-16, SYNC-18]

The install command runs under the version the repo asks for:

| Manager | Used when (with `runtime.manager: auto`) | How the command runs |
|---|---|---|
| mise | `mise` on PATH and the repo has `mise.toml`, `.mise.toml` or `.tool-versions` | `mise exec -- <cmd>` |
| asdf (v2.1) | `asdf` on PATH and `.tool-versions` | `asdf exec <cmd>` |
| fnm | `fnm` on PATH and `.nvmrc`/`.node-version` | `fnm exec --using=<file> -- <cmd>` |
| nvm | `$NVM_DIR/nvm.sh` exists and `.nvmrc`/`.node-version` | `bash -c '. "$NVM_DIR/nvm.sh" --no-use && nvm exec --silent <version> <cmd>'` |
| Volta | `volta` on PATH and `package.json` has `volta` | `<cmd>` (Volta's shims select the version) |
| pyenv (v2.1) | `pyenv` on PATH and `.python-version` | `PYENV_VERSION=<version> pyenv exec <cmd>` |
| none | no version file | `<cmd>` with the current PATH |

Checked in the order listed; the first match is used. If a version file exists but no manager can provide that version: when the runtime on PATH already matches, run with it; otherwise `failed` (step `install`) with a fix such as `nvm install 24` or `mise install`. Strive never installs runtimes itself in 2.x.

---

## 7. `strive status`

### 7.1 Synopsis

```
strive status [repo...] [--exclude <repo>]... [--fetch]
```

Read-only. Offline unless `--fetch` (which fetches like `sync` step 7 and changes nothing else). [STAT-02]

### 7.2 Per repo [STAT-01]

| Field | How |
|---|---|
| Branch | Current branch, or `detached` |
| Uncommitted | Number of entries in `git status --porcelain` |
| Stashes | `git stash list` count |
| Unpushed | Commits on any local branch not on any remote: `git rev-list --count --branches --not --remotes` |
| Merged branches | Local branches, except the current and default ones, that are merged into `<remote>/<default>` or whose upstream is gone |

A repo needs attention (class `needsYou`) when uncommitted, stashes or unpushed is above zero, or it is `busy`.

### 7.3 Output

```
  web-app     feat/search   2 unpushed · 1 stash
  docs-site   main          3 uncommitted
  billing     main          old/retry merged, safe to delete
  2 others clean
```

JSON (`strive.status/1`):

```json
{ "schema": "strive.status/1", "strive": "2.0.0", "workspace": "/home/dev/code",
  "summary": { "repos": 5, "clean": 2, "needsYou": 2 },
  "repos": [ { "name": "web-app", "path": "/home/dev/code/web-app", "branch": "feat/search",
               "uncommitted": 0, "stashes": 1, "unpushed": 2, "busy": null,
               "mergedBranches": [], "class": "needsYou" } ] }
```

Exit 3 if any repo needs attention, else 0. [STAT-03]

---

## 8. `strive init`

```
strive init [--force]
strive init --from <git url | folder> [--force]
```

- **Without `--from`** [INIT-01]: discovers repos (5.2 step 3) and writes `.repos` in the current folder, one line per repo.
- **With `--from`** (v2.1) [INIT-02]: copies the team's shared workspace files into the current folder. From a git URL, Strive makes a shallow clone into a temp folder, copies the files, and deletes the clone. Files copied when present: `.repos`, `.strive/config.yml`, `.strive/tickets.yml`. Nothing else. Then it prints `Next: strive sync`.
- If a file exists, Strive asks before replacing it. `--force` or `--yes` skips the question; non-interactive without them exits 2.

A team's shared workspace is a small git repo holding those files. Teams keep clone URLs in its `.repos` so `strive sync` can clone everything for a new teammate.

---

## 9. `strive tickets` (alias `strive t`)

### 9.1 Files [TIX-01, TIX-02]

```
<tickets dir>/
  PROJ-142/
    README.md          the ticket
    01-research.md     optional extra files
```

- The tickets dir is `dir` from `tickets.yml`, default `.strive/tickets`, relative to the workspace root.
- Folder name = ticket id. A leading `_` is allowed and ignored when reading the id.
- Files without frontmatter are **legacy**: listed, never failed. [TIX-18]

### 9.2 `tickets.yml` [TIX-03]

```yaml
schema: 1
dir: .strive/tickets
id: "PROJ-[0-9]+"            # regex for ids, or "slug" for ids made from titles
link: "https://acme.atlassian.net/browse/{id}"   # optional; fills the link field
statuses: [todo, in-progress, in-review, qa, done, blocked]
workflow:
  start: in-progress         # status set by `start`
  done: done                 # status set by `done`; tickets in it are not active
priorities: [P1, P2, P3]     # optional; empty or missing removes the field
types:
  story: {}
  bug:   { branchPrefix: fix }
  task:  {}
defaultType: story
milestones: [started, review_opened, merged, closed]
sections:
  - Summary
  - Scope
  - { name: Root cause, types: [bug] }
  - Implementation
  - Verification
  - Next steps
fields:                      # custom frontmatter fields
  points: { type: number }
  design: { type: url }
branch: "{prefix}/{id}-{slug}"   # prefix = type's branchPrefix, else "feat"
```

Without `tickets.yml`, the `simple` preset applies.

Field types: `string`, `number`, `date`, `url`, `list`, `{ enum: [...] }`. `milestones` must include the names used by `start` (`started`) and `done` (`closed`), or those commands skip setting them.

**Presets** (`tickets init --preset <name>`):

| Preset | `id` | `link` | Statuses | Priorities |
|---|---|---|---|---|
| `simple` | `slug` | none | todo, doing, done | none |
| `jira` | `[A-Z][A-Z0-9]+-[0-9]+` | `https://<site>.atlassian.net/browse/{id}` | todo, in-progress, in-review, qa, done, blocked | highest, high, medium, low, lowest |
| `linear` | `[A-Z]+-[0-9]+` | `https://linear.app/<team>/issue/{id}` | backlog, todo, in-progress, in-review, done, canceled | urgent, high, medium, low |
| `github` | `[0-9]+` | `https://github.com/<owner>/<repo>/issues/{id}` | open, in-progress, in-review, closed | none |

`<site>`, `<team>`, `<owner>/<repo>` come from `--link` or are left as placeholders with a note. Every preset uses the types, milestones and sections shown above unless stated.

### 9.3 Ticket file

```markdown
---
# identity
id:        PROJ-142
title:     "Search results pagination"
link:      https://acme.atlassian.net/browse/PROJ-142
type:      story
status:    in-review
priority:  P2
assignee:  Ana
repos:     [web-app]

# dates
started:       2026-11-03
review_opened: 2026-11-05
merged:        null
closed:        null

updated:       2026-11-05

# more
branch:    feat/PROJ-142-search-results-pagination
review:    https://github.com/acme/web-app/pull/88
points:    3
---

# PROJ-142: Search results pagination

## Summary

## Scope

## Implementation

## Verification

## Next steps

1. Address review comment on page size

## Notes

- 2026-11-05: Reviewer asked to move page size into config
```

**Frontmatter rules**
- Groups and order: identity (`id`, `title`, `link`, `type`, `status`, `priority`, `assignee`, `repos`), dates (each milestone in config order, then `updated`), more (`branch`, `review`, `parent`, `blocked_by`, `blocks`, then custom fields in config order).
- Values in a group are aligned to the longest key in that group plus one space.
- `link` is present only when configured, `priority` only when priorities exist. Milestones are always present (`null` until they happen). Empty "more" fields are omitted.
- **Derived, never set by hand** [TIX-07]: `updated` (date of the last write) and `link` (from the template).

**Body rules**
- `# <id>: <title>`, then config `sections` in order (type-limited sections only for those types), then `## Notes`. Section bodies are free text; humans and agents may edit them by hand.
- Notes are `- YYYY-MM-DD: text` lines, appended. [TIX-09]

### 9.4 Ticket id inference [TIX-21]

Where a ticket command's `<id>` is optional and omitted:
1. The current folder's git branch: the longest existing ticket id contained in the branch name wins.
2. Otherwise exit 2: `error: which ticket?` with a fix showing the id argument.


### 9.5 Commands

| Command | Does | Req |
|---|---|---|
| `strive t` | Active tickets with their next step (same as `list --active`). | |
| `t init [--preset <name>] [--link <template>]` | Writes `.strive/tickets.yml` (asks before replacing) and creates the tickets dir. Never edits `.gitignore`. | TIX-04 |
| `t new <id> "title"` / `t new "title"` (slug ids) `[--type t] [--repo a,b] [key=value...]` | Creates the ticket from config. Id must match the pattern and not exist. | |
| `t start <id> ["title"] [--repo a,b] [--type t] [--no-branch]` | Creates the ticket if missing; sets status to `workflow.start` and `started` to today if null; per repo, creates and checks out the branch (9.6); pins it (4.2). | TIX-13 |
| `t done [<id>]` | Sets status to `workflow.done` and `closed` to today if null; removes pins equal to the ticket's branch. | TIX-14 |
| `t set [<id>] key=value...` | Sets fields. Dates accept `YYYY-MM-DD`, `today`, `yesterday`, `null`. Lists take `a,b`. Derived fields and `id` cannot be set (exit 2). | TIX-15 |
| `t note [<id>] "text"` | Appends a dated note. | TIX-15 |
| `t next [<id>] "step" ["step"...]` | Replaces the Next steps list (it is current state, not history). | TIX-15 |
| `t write [<id>] "<Section>" [text \| -]` | Replaces a section's body with the text or stdin. Not allowed for Notes. | TIX-06 |
| `t show [<id>]` | The ticket: fields, next steps, the last 5 notes. | TIX-16 |
| `t list [--active] [--status s] [--since date]` | Tickets sorted by `updated`, newest first. | TIX-16, TIX-17 |
| `t check [<id>]` | Validates against config. Exit 1 if anything is invalid. | TIX-08, TIX-18 |
| `t fmt [<id>] [--check]` | Rewrites into canonical form. With `--check`, changes nothing and exits 1 if anything would change. | TIX-08 |
| `t migrate --from <dir> --map <file.yml> [--dry-run]` | Later, if users ask: converts tickets from another format (9.8). | TIX-19 |

Every write goes through 4.6 and recomputes derived fields. All commands support `--json`.

### 9.6 Branch creation in `start`

Per repo in `--repo` (or the ticket's `repos`): fetch the default branch, then:
- Branch exists locally: switch to it if the repo is clean; otherwise leave it and report `not switched: uncommitted changes`.
- Branch does not exist: if clean, `git switch -c <branch> <remote>/<default>`; if dirty, `git branch <branch> <remote>/<default>` and report `created, not switched: uncommitted changes`.
- Never pushes. Sets the ticket's `branch` field.

### 9.7 JSON

`strive.ticket/1` (`show`):

```json
{ "schema": "strive.ticket/1", "strive": "2.1.0",
  "id": "PROJ-142", "path": "/home/dev/code/.strive/tickets/PROJ-142/README.md", "legacy": false,
  "fields": { "title": "Search results pagination", "status": "in-review", "started": "2026-11-03" },
  "nextSteps": ["Address review comment on page size"],
  "sections": { "Summary": "…", "Scope": "…" },
  "notes": [ { "date": "2026-11-05", "text": "Reviewer asked to move page size into config" } ] }
```

`strive.tickets/1` (`list`): `{ schema, strive, tickets: [ { id, path, legacy, title, status, type, updated, started, closed, nextStep } ] }`.

`strive.check/1` (`check`): `{ schema, strive, valid, invalid, legacy, problems: [ { id, path, rule, message } ] }`.

### 9.8 Migration (later, if users ask)

The map file names how old keys become new ones:

```yaml
fields:   { key: id, url: link, pr: review }
sections: { "Status / Next steps": "Next steps" }
drop:     []            # old fields to remove
```

`migrate` reads every ticket in `--from`, applies the map, validates against `tickets.yml`, and writes into the configured dir (in place if it is the same dir). `--dry-run` prints what would change and writes nothing. Unknown fields are kept if declared in `fields`, else reported and the ticket is skipped.

---

## 10. `strive standup` (preview in 2.1) [STAND-01]

```
strive standup [--since <date>] [--author <email>]
```

- Since: the start of the last working day before today (`workdays`), or `--since`.
- Commits: in every workspace repo, all local branches, author = `--author` or `git config user.email`.
- Tickets: those whose status changed or that got notes in the range.
- Next: the first next step of every active ticket.

```
Since Fri 2026-10-30

Commits
  web-app      feat/PROJ-142   3 commits   Pagination API, tests, review fixes
  api-service  main            1 commit    Bump zod

Tickets
  PROJ-142   in-review   2 notes · status in-progress → in-review

Next
  PROJ-142   Address review comment on page size
```

JSON `strive.standup/1`: `{ schema, strive, since, commits: [ { repo, branch, sha, subject, date } ], tickets: [ { id, status, statusChanges: [], notes: [] } ], next: [ { id, step } ] }`.

---

## 11. Compatibility: the `strive-sync` command [SYNC-25]

Through all of 2.x, `strive-sync` remains. If `strive` is on PATH it runs `strive sync` with flags mapped; otherwise it runs the bundled v1.4 script and prints one line: `strive 2 is available: brew install strivingdesigns/tap/strive`.

| v1 flag | v2 equivalent |
|---|---|
| (no `-i`) | `--no-install` |
| `-i`, `--install` | install on (default) |
| `-f`, `--force` | `--force-install` |
| `-m`, `--main` | `--switch` |
| `-a`, `--audit` | `--report AUDIT.md` |
| `-d`, `--dry-run` | `--dry-run` |
| `-o`, `--only <repo>` | `<repo>` |
| `-e`, `--exclude <repo>` | `--exclude <repo>` |
| `-b`, `--branch <name>` | `--branch <name>` |
| `-p`, `--parallel <n>` | `--parallel <n>` |
| `-y`, `--yes` | no picker |
| (terminal, no `-y`) | `--pick` (from 2.1; in 2.0 it runs without the picker) |
| `-v`, `-h` | `--version`, `--help` |

Removed in 3.0, announced one minor release before.

---

## 12. Platforms

- macOS 13+ and Linux (glibc and musl), arm64 and x64. Windows 10+ (x64) later in 2.x.
- git 2.30 or newer. The conflict forecast needs 2.38; older versions skip it with a note.
- On Windows, paths in `.repos` still use `/`; output shows native paths.
- Not supported in 2.x: submodules (never updated, noted when present), version control systems other than git.

---

## Changes to this spec

| Version | Date | Change |
|---|---|---|
| 2.0-draft.1 | 2026-10-30 | First draft. |
| 2.0-draft.3 | 2026-10-30 | Time tracking removed (clock, hours, day files, time log). Tickets in 2.0. Windows, npm, Python, cloning, picker and conflict forecast moved to later releases. |
| 2.0-draft.2 | 2026-10-30 | Time moved out of tickets to top-level `in`/`out`/`clock`/`log`/`hours` with day files; `init --from`; first-run guidance; grouped failures and `failureReason`; `help status`. |
