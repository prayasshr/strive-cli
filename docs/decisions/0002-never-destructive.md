# 0002. Never destructive

Status: Accepted, 2026-10-30

## Context
A sync tool runs across many repos at once, often unattended or by an agent. One bad decision repeated across 20 repos loses real work. v1 could fast-forward a feature branch with the default branch's commits when the feature branch had none of its own, mixing work the developer did not ask for.

## Decision
Strive never:
- runs a git command that writes in a repo with uncommitted changes, an operation in progress, or a detached HEAD;
- merges anything except a fast-forward of the branch's own target;
- changes a branch other than its target (feature branches are reported, never updated);
- rebases, resets, stashes, commits, pushes, or force-updates anything;
- deletes anything without explicit confirmation, and never inside `sync`.

The only writes `sync` makes: fast-forward of the target branch, fast-forward of a local default branch that is not checked out, `git switch` with `--switch`, cloning missing repos, and dependency installs.

## Consequences
- Some repos stay stale until the developer acts. Strive says so ("needs you") with the exact next step.
- Users can run Strive on any workspace at any time without fear, which is the product's core promise.

## Alternatives
- **Auto-stash and pull:** convenient, and occasionally loses or conflicts work. Rejected.
- **Auto-rebase feature branches:** saves a step, and produces conflicts nobody is watching. Rejected; Strive forecasts conflicts instead.
