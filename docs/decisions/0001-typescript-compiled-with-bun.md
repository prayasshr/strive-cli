# 0001. TypeScript, compiled to a single binary with Bun

Status: Accepted, 2026-10-30

## Context
Strive must run for every developer on macOS, Linux and Windows with nothing else to install, and it must be testable enough that "honest output" can be proven. The v1 tool is bash: no Windows, hard to test, and its silent install failures shipped unnoticed. The maintainer writes TypeScript daily.

## Decision
- Write Strive in TypeScript, using only Node APIs (`node:*` modules). No Bun-only or Deno-only APIs.
- Develop and test on Node (22+), with pnpm, vitest, tsc and eslint.
- Build release binaries with `bun build --compile` for macOS, Linux and Windows.
- Publish the same code to npm, where it runs on the user's Node.

## Consequences
- Users get one file with no runtime to install. JS developers can also use npm.
- Binaries are large (roughly 50 to 100 MB). Accepted: invisible after `brew install`.
- Two runtimes to keep compatible (Node for npm and tests, Bun for binaries). CI runs the test suite on Node and a smoke test on every compiled binary.

## Alternatives
- **Go:** ~10 MB binaries and the most mature release tooling (GoReleaser). Rejected because the maintainer would own a codebase in a language he does not write daily; for a solo project, being able to read and fix every line matters more.
- **Rust:** same benefits as Go, harder language. Rejected.
- **Bash:** zero dependencies on macOS and Linux. Rejected: no Windows, weak testing, painful JSON and YAML.
- **Plain Node package only:** would require Node on every machine, failing non-JS developers.
