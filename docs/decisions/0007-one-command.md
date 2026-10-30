# 0007. One `strive` command, with `strive-sync` kept as a wrapper

Status: Accepted, 2026-10-30

## Context
v1 installed separate `strive-*` scripts. The planned features are mostly different views of the same data (repos, branches, runtimes, dependencies, tickets), and existing users and scripts call `strive-sync` with v1 flags every day.

## Decision
- One binary, `strive`, with subcommands sharing one engine.
- `strive-sync` remains through all of 2.x: it maps v1 flags to `strive sync` (SPEC section 11), or runs the bundled v1.4 script when `strive` is not installed.
- It is removed in 3.0, announced one minor release ahead.

## Consequences
- One install, one version, one set of flags and outputs to learn.
- The wrapper and the v1.4 script are maintained (fixes only) until 3.0.

## Alternatives
- **Separate binaries per tool:** duplicate code and release overhead for a solo maintainer. Rejected.
- **Break `strive-sync` at 2.0:** simpler, and breaks daily users' mornings. Rejected.
