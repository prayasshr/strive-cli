# 0004. Output contract

Status: Accepted, 2026-10-30

## Context
Strive has two kinds of users: people and AI agents. v1 always exited 0, always drew a cursor-moving dashboard (even into pipes), and agents had to strip control codes with `sed` and guess at results.

## Decision
- Exit codes, the same for every command: 0 ready, 1 failed, 2 bad usage or config, 3 needs you, 130 interrupted.
- `--json` on every command. Each document names its schema and major version (`strive.sync/1`). Removing, renaming or changing a field is a breaking change.
- Live view only when stdout is a terminal; plain lines otherwise; never control codes in a pipe.
- Meaning never depends on color.

## Consequences
- Agents and scripts can rely on Strive without parsing prose.
- JSON shapes are a public API and slow to change. New commands start as "preview" for one minor release so their shapes can settle.

## Alternatives
- **Exit 0 unless crashed:** simple, and useless to automation. Rejected.
- **Separate machine-readable command or daemon:** more surface for no gain over `--json`. Rejected.
