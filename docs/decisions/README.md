# Decisions

Each file records one decision: the situation, what we chose, what it costs, and what we turned down. They stop settled questions from being reopened without new information.

To change a decision, add a new record that replaces the old one and mark the old one `Replaced by 00NN`. Never rewrite an accepted record.

| # | Decision | Status |
|---|---|---|
| [0001](0001-typescript-compiled-with-bun.md) | TypeScript, compiled to a single binary with Bun | Accepted |
| [0002](0002-never-destructive.md) | Never destructive: fast-forward only, never touch uncommitted work or feature branches | Accepted |
| [0003](0003-frozen-installs.md) | Frozen-lockfile installs, and when to install | Accepted |
| [0004](0004-output-contract.md) | Output contract: exit codes, JSON schemas, plain output off-terminal | Accepted |
| [0005](0005-local-first.md) | Local first: no network beyond git and package tools, no telemetry, specifics in user config | Accepted |
| [0006](0006-tickets-as-markdown.md) | Tickets as tool-maintained markdown notes; no time tracking | Accepted |
| [0007](0007-one-command.md) | One `strive` command with subcommands; `strive-sync` kept as a wrapper through 2.x | Accepted |
| [0008](0008-bash-fixes-before-rewrite.md) | Ship trust fixes in bash (1.4) before the rewrite | Accepted |
