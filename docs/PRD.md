# Strive CLI: Product Requirements

| | |
|---|---|
| Product | Strive CLI (`strive`) by Striving Designs |
| Status | Draft 4, 2026-10-30 (time tracking removed; tickets first) |
| Owner | Prayas Shrestha |
| Covers | v2.0 to v2.3 |
| Related | `docs/SPEC.md` (exact CLI contract), `docs/decisions/` (ADRs), `AGENTS.md` (rules for building) |

Requirements use MUST (required for the release), SHOULD (expected, may slip with a note), and MAY (optional). Each has an ID; tests, issues and commits reference it.

---

## 1. Summary

**Ready to work. Honestly reported.**

Strive is one command-line tool that gets a developer's workspace ready to work and keeps notes for each piece of work that anyone can pick up. One command makes every repo current, on the right runtime, with dependencies installed, and reports exactly what needs attention. A second set of commands keeps local ticket notes (what the work is, where it stands, what's next) that humans and AI agents can both read and write safely.

It runs on any stack, any repo layout, any git host and tracker, on macOS and Linux (Windows later in 2.x), as a single file with nothing else to install.

## 2. Problem

A developer's day loses time to bookkeeping that tools could do:

- **Morning:** repos are stale. A runtime version changed, lockfiles changed, a new env key appeared. The first build fails with a cryptic error and the first half hour goes to digging.
- **During the day:** nobody remembers which repos have uncommitted work, forgotten stashes or unpushed commits.
- **Picking up work:** branches start from a stale default branch, names drift from the convention, notes start nowhere.
- **Switching context:** what a task is, what was decided and what comes next lives in someone's head, a chat thread, or a scratch file. A week later, neither the developer nor their AI agent knows where the work stopped.
- **Working with AI agents:** agents scrape human-oriented output, hand-edit structured files and get them wrong, and cannot tell real success from printed success.

Existing multi-repo tools (gita, mani, myrepos) run git across repos but stop there. They do not handle runtimes and dependencies, do not report what changed in a way that matters, and are not built for agents.

## 3. Users

| Persona | Situation | Needs most |
|---|---|---|
| **Team developer** (primary) | 5 to 30 repos, often mixed stacks, starts every day by updating them | One safe command, an honest report, nothing broken behind their back |
| **AI agent** (primary) | Runs commands for a developer inside a coding assistant | Stable `--json`, meaningful exit codes, safe writes, no rulebooks to reread |
| **Solo developer** | One repo or many personal ones | Zero setup; notes per task they and their agent can resume |
| **New teammate** | Empty laptop | From nothing to every repo ready in one command |

Humans and agents are equal users. Anything a human can see, an agent can get as JSON.

## 4. Goals and non-goals

**Goals**
1. Make "ready to work" one command for any developer on any stack.
2. Never report success that was not verified.
3. Give agents a first-class, stable interface.
4. Keep ticket notes as plain files the tool maintains, so any person or agent can resume work cold.
5. Be a credible, well-maintained open-source project that represents Striving Designs.

**Non-goals**
- Not a git client. No rebase, reset, stash, commit or push on the user's behalf.
- Not a "run any command in every repo" tool.
- Not a runtime version manager or package manager. Strive drives them.
- Not a monorepo build tool.
- Not a secrets manager. Env support compares key names only.
- Not an issue tracker client. No Jira, Linear or GitHub API calls in core.
- Not a time tracker. No clocks, hour logs or timesheets.
- No accounts, no cloud, no telemetry.
- Git only. Other version control systems are out of scope. Submodules are not updated in 2.x.

## 5. Principles

Every feature is checked against these. A conflict is resolved in this order.

1. **Never destructive.** Strive does not touch uncommitted work, never rewrites history, never deletes without explicit confirmation.
2. **Honest.** Every step's result is verified. A failure says FAILED, why, and where the log is.
3. **Local first.** Core talks only to the filesystem, git, and the user's own tools. Works offline except fetching.
4. **The user's specifics live in the user's config.** Strive ships with no company names, URLs or patterns.
5. **Works with zero config, gets better with config.**
6. **Calm output.** Precise and quiet, like `git status`. No theatrics.

---

## 6. Cross-cutting requirements

**Install and platforms**
- CORE-01 MUST ship as a single executable with no runtime dependency, for macOS (arm64, x64) and Linux (arm64, x64). SHOULD add Windows (x64) during 2.x.
- CORE-02 MUST install via Homebrew tap and a one-line install script. SHOULD add npm, and Scoop or winget, during 2.x.
- CORE-03 MUST require only git on the user's machine. Other tools (package managers, version managers) are used when present and reported clearly when needed but missing.

**Workspace**
- CORE-04 MUST find the workspace root by walking up from the current folder to the first folder holding a Strive file (`.repos`, `.strive/config.yml` or `.strive/tickets.yml`); with none, the current folder is the workspace. A bare `.strive/` folder is not a marker, because v1 installed tools into `~/.strive/bin`.
- CORE-05 MUST accept `--cwd <dir>` on every command.

**Output**
- CORE-06 MUST render a live view only when stdout is a terminal; otherwise plain lines with no terminal control codes. `--plain` forces plain.
- CORE-07 MUST support `--json` on every command. JSON MUST carry a schema id and version; changing a shape incompatibly is a major version change.
- CORE-08 MUST honor `NO_COLOR` and `--no-color`. Meaning MUST never depend on color or emoji alone.
- CORE-22 Messages MUST be understandable by a developer in their first week: plain words first, the exact command to run second. Every status MUST have a short explanation available through `strive help status <name>`.
- CORE-09 MUST use the same exit codes everywhere: 0 done and ready; 1 something failed; 2 bad usage or config; 3 done, nothing failed, something needs the user; 130 interrupted.

**Safety and honesty**
- CORE-10 MUST check the exit status of every process it runs. A non-zero exit is reported as a failure with a reason and log path, never as success.
- CORE-11 MUST never prompt for credentials or hang on auth; auth failures are reported as auth failures.
- CORE-12 MUST stop cleanly on Ctrl-C: no new work starts, running child processes are terminated, one summary prints, and the exit code is 130.
- CORE-13 MUST write files atomically (temp file, then rename) and refuse to overwrite a file that changed since Strive read it.
- CORE-14 MUST be non-interactive unless stdout is a terminal and the action is a confirmation or an explicit picker. `--yes` answers confirmations.

**Privacy**
- CORE-15 MUST not send data anywhere. No telemetry, no update checks without opt-in.
- CORE-16 MUST never print secret values (env values, tokens).

**State and logs**
- CORE-17 MUST keep state and logs under `$XDG_STATE_HOME/strive/` (platform equivalent on Windows), never in the workspace unless asked.
- CORE-18 SHOULD keep per-run logs for 14 days and prune older ones.

**Performance**
- CORE-19 Strive's own overhead (excluding network and installs) SHOULD stay under 1 second for 20 repos.
- CORE-20 MUST run repos in parallel with a sensible default and a `--parallel` override.
- CORE-21 Network and install steps MUST have timeouts, so a dead network or a hung install cannot block a run forever.

---

## 7. Features

### 7.1 `strive init` (v2.0)
- INIT-01 MUST write the discovered repo list to `.repos`, without overwriting an existing one unless confirmed.
- INIT-02 (v2.1) `init --from <git url or folder>` MUST copy a team's shared workspace files (`.repos`, `.strive/config.yml`, `.strive/tickets.yml`) into the current folder, asking before replacing any, so a new teammate goes from nothing to `strive sync` in two commands.
- INIT-03 When Strive finds no repos and no workspace files, it MUST show the next steps (clone a repo, `init --from`, or move to the right folder) instead of an error.

### 7.2 `strive sync` (v2.0)
Makes every repo current, on the right runtime, with dependencies installed, and reports what came in.

**Repos**
- SYNC-01 MUST read repos from, in order: `--only`, `.strive/config.yml`, `.repos`, then discovery (depth 5, skipping dependency and build folders).
- SYNC-02 `.repos` MUST support blank lines, full-line and inline `#` comments, surrounding whitespace, CRLF, `name:branch` pins, and an optional clone URL.
- SYNC-03 MUST treat entries that share one git root as one repo, and MUST never run git operations in parallel on working copies that share one repository (same root, or linked worktrees).
- SYNC-04 MUST support `--exclude`.

**Git**
- SYNC-05 MUST skip a repo with uncommitted changes (untracked files included unless configured otherwise) without running any git command that writes. Repos mid-rebase or mid-merge, or not on a branch, MUST be left alone and reported.
- SYNC-06 Target branch MUST be: pinned branch, else `--branch`, else the remote default branch.
- SYNC-07 MUST fetch the target branch and the default branch.
- SYNC-08 On the target branch, MUST only fast-forward. Diverged is reported, never resolved.
- SYNC-09 On any other branch, MUST NOT change that branch. SHOULD update the local default branch when it fast-forwards and is not checked out. MUST report commits behind; from v2.1, also whether a rebase would conflict (when git supports the check).
- SYNC-10 `--switch` MUST move clean repos to the target branch before syncing.
- SYNC-11 A pinned branch that does not exist on the remote MUST be reported as not pushed, not as a failure.
- SYNC-12 A missing repo MUST be reported missing; from v2.1, one with a clone URL MUST be cloned.

**Runtime and dependencies**
- SYNC-13 MUST install dependencies by default when needed; `--no-install` disables, `--force-install` forces.
- SYNC-14 "Needed" MUST mean: the dependency folder is missing, or a manifest or lockfile changed in the commits pulled by this run, or the lockfile differs from the one recorded at the last successful install. A first run with dependencies present records a baseline instead of reinstalling everything.
- SYNC-15 Installs MUST use frozen-lockfile mode and MUST NOT modify lockfiles.
- SYNC-16 MUST run installs under the runtime version the repo asks for, through the user's version manager. A missing version MUST fail with the command that fixes it.
- SYNC-17 MUST support in v2.0: Node (npm, pnpm, yarn 1, yarn 2+, bun) and a per-repo custom install command. MUST add Python (uv, poetry, pip) in v2.1. SHOULD add Ruby, Go, Rust and PHP by v2.3.
- SYNC-18 MUST support version managers mise, nvm, fnm and Volta in v2.0, and asdf and pyenv in v2.1.

**Report**
- SYNC-19 MUST give each repo exactly one status from the SPEC's list and its duration.
- SYNC-20 For updated repos, SHOULD report what came in: commit count, runtime version changes, dependencies added or removed, new `.env.example` keys, and adapter-specific notes.
- SYNC-21 MUST end with a summary and a "needs you" list, each item with its next action.
- SYNC-26 When several repos fail or need attention for the same reason (no SSH key, network down, a missing runtime version), the summary MUST group them into one item with one fix, listing the repos.
- SYNC-22 MUST record each run (per-repo status and timing) in state for measured performance numbers.

**Modes**
- SYNC-23 `--dry-run` MUST fetch, change nothing else, and predict the same statuses a real run would produce. `--offline` skips fetching.
- SYNC-24 (v2.1) `--pick` MUST offer an interactive repo and option picker on a terminal.

**Compatibility**
- SYNC-25 The `strive-sync` command MUST keep working through 2.x, mapping v1 flags to v2, falling back to the bundled v1.4 script when `strive` is not installed.

### 7.3 `strive status` (v2.0)
- STAT-01 MUST list per repo: branch, uncommitted file count, stashes, unpushed commits, branches without an upstream, and local branches already merged upstream.
- STAT-02 MUST be read-only and offline by default; `--fetch` MAY refresh remote state first.
- STAT-03 MUST exit 3 when anything is uncommitted or unpushed.

### 7.4 `strive tickets` (v2.0)
Local notes for each piece of work: what it is, where it stands, what was decided, and what comes next. Plain markdown files the tool maintains, so a person or an AI agent can pick up any ticket cold.

**Storage and config**
- TIX-01 Each ticket MUST be a folder with a `README.md`: YAML frontmatter plus body sections in a fixed order. Extra files are allowed.
- TIX-02 The tickets folder MUST default to `.strive/tickets/` and be configurable.
- TIX-03 `.strive/tickets.yml` MUST define: id pattern, link template, statuses, types (with their branch prefix), priorities, lifecycle milestones, sections, branch name pattern, and custom fields. Without the file, built-in defaults apply.
- TIX-04 `init` MUST offer presets: simple, jira, linear, github.
- TIX-05 Strive MUST ship with no company-specific values; all of them live in the user's config.

**Writing**
- TIX-06 All changes MUST be possible through commands; agents never need to edit files by hand.
- TIX-07 Every write MUST keep frontmatter in schema order, bump `updated`, and recompute derived values (`link`).
- TIX-08 Hand edits MUST be tolerated: `fmt` repairs formatting, `check` reports anything invalid.
- TIX-09 Notes MUST be append-only and dated; they are never rewritten.

**Workflow**
- TIX-13 `start` MUST create the ticket, create the branch from a freshly fetched default branch using the configured pattern, and pin it in `.repos` when a sync workspace exists.
- TIX-14 `done` MUST set the closed milestone and remove the pin.
- TIX-15 `set`, `note`, `next` and `write` MUST change fields, append notes, replace the next steps, and replace a free-text section.
- TIX-21 Commands that take a ticket id SHOULD infer it when omitted, from the current git branch name.

**Reading**
- TIX-16 `show` and `list` MUST support `--json`. `show --json` MUST give an agent everything needed to resume: fields, sections, next steps and recent notes.
- TIX-17 `list` MUST compute from files on every run; any markdown index is regenerated, never hand-maintained.
- TIX-18 `check` MUST validate every ticket against the config and report legacy files (no frontmatter) separately from invalid ones.

**Migration and independence**
- TIX-19 `migrate` MAY convert tickets from another frontmatter format using a field mapping, with a dry run. Not in 2.0; built if users ask.
- TIX-20 Tickets MUST work without sync, without `.repos`, and outside a git repo.

### 7.5 `strive standup` (v2.1)
- STAND-01 MUST list the user's commits across workspace repos since the last working day, the tickets touched (status changes and new notes), and the next steps of active tickets, as text and `--json`.

### 7.6 Later commands (v2.2 to v2.3)
Requirements are written before each release starts:
`strive doctor` (machine readiness), `strive env` (key drift between `.env` and `.env.example`), `strive review` (a branch in its own worktree, ready to run), `strive clean` (merged branches and disk use, confirmed deletes).

---

## 8. Success metrics

**Trust (every release)**
- Zero known cases of reported success without verified success.
- Every status and exit code covered by a fixture test on every supported OS.

**Usefulness**
- The author's daily routine and at least one teammate run Strive daily with no manual follow-up checks.
- A measured, published number from real runs (for example, "20 repos ready in 41 seconds"), not an estimate.

**Adoption, 12 months after v2.0**
- 500 GitHub stars.
- 25 issues or pull requests from people the author does not know.
- 3 outside contributors with merged changes.
- Release downloads and npm installs tracked monthly.

---

## 9. Releases

| Version | Scope | Public? |
|---|---|---|
| 1.4.0 | Trust fixes to the current bash `strive-sync` | Quiet |
| 2.0.0-alpha | Core, output contract, release pipeline, `tickets` | Private (the author uses it daily) |
| 2.0.0 | `sync` (Node, custom install), `status`, `strive-sync` wrapper, brew and install script, macOS and Linux | Launch |
| 2.1.0 | What came in, Python, asdf and pyenv, `init --from` and cloning, conflict forecast, live view and picker, `standup` | Announce |
| 2.2.0 | `doctor`, `env`, Windows, npm | Announce |
| 2.3.0 | `review`, `clean`, Ruby/Go/Rust/PHP adapters | Announce |

New commands ship as **preview** for one minor release: their flags and JSON may change. After that they are stable.

## 10. Open questions

1. Should Strive offer to install a missing runtime version (e.g. run `mise install`) behind a flag? Not in 2.x; revisit with user feedback.
2. Windows version managers (nvm-windows, fnm on Windows): test coverage and support level before Windows ships.

**Closed:** time tracking is out of scope (draft 4); ticket ids are inferred from the branch; the install script is served from GitHub until the site exists; Strive never edits `.gitignore`, so committing `.strive/` is the user's choice.

## 11. Glossary

| Term | Meaning |
|---|---|
| Workspace | The folder Strive works in: found via `.strive/` or `.repos`, or the current folder |
| Target branch | The branch a repo should be on and current with |
| Default branch | The remote's HEAD branch, e.g. `main` |
| Ready | Current with the target, right runtime, dependencies installed |
| Adapter | Strive's support for one ecosystem: how to detect it, its lockfiles, version file and install command |
| Version manager | A tool that selects runtime versions, e.g. mise, nvm, pyenv |
| Needs you | A state Strive will not resolve itself, such as uncommitted changes or a branch that diverged |
| Ticket | A folder of notes for one piece of work, whether or not it exists in a tracker |
