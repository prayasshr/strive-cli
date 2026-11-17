# 0008. Ship trust fixes in bash before the rewrite

Status: Accepted, 2026-10-30

## Context
v1.3.0 is used every day, and its install path can report success when installs failed. The TypeScript rewrite (0001) will take weeks.

## Decision
Release 1.4.0 on the current bash code with trust fixes only: correct runtime switching, yarn 2+ support, every exit code checked, frozen installs, no merging into feature branches, shared-root dedupe, real exit codes, honest dry run, clean Ctrl-C, plain output off-terminal, `.repos` inline comments, `not-pushed` status, per-repo timing. No new features beyond what daily users need to stay safe.

1.4 is a quiet release. 2.0 is the public launch.

## Consequences
- Some work is done twice (in bash, then in TypeScript). Accepted: daily users are safe now, and the bash fixes become the behavior the rewrite's tests must match.
- 1.4 gets shellcheck and a fixture script, not a full test suite.

## Alternatives
- **Skip 1.4 and go straight to 2.0:** less total work, and weeks of possibly false "success" for daily users. Rejected.
