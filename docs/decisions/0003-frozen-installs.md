# 0003. Frozen-lockfile installs, and when to install

Status: Accepted, 2026-10-30

## Context
"Ready to work" includes installed dependencies. In v1, `npm install` could rewrite `package-lock.json`, which made the repo dirty, so every later sync skipped it. v1 also decided "lockfile changed" with `HEAD@{1}`, which is wrong whenever the last reflog entry was not this sync.

## Decision
- Every install uses its tool's frozen mode (`npm ci`, `pnpm install --frozen-lockfile`, `yarn install --immutable`, `bun install --frozen-lockfile`, `uv sync --locked`, ...). Strive never lets an install modify a lockfile.
- Installs are on by default, because frozen installs are safe.
- An install is needed when: the dependency folder is missing; a manifest or lockfile changed between the commit saved before this run's merge and the new HEAD; or the lockfile's hash differs from the one recorded at the last successful install. A first run with dependencies present records a baseline instead of reinstalling.
- Installs run under the repo's runtime version through the user's version manager, in the same process as the install.

## Consequences
- A lockfile out of sync with its manifest now fails loudly instead of being silently rewritten. That is correct: it is a real problem in the repo.
- `npm ci` deletes and rebuilds `node_modules`, which is slower than `npm install`. Accepted for correctness; it only runs when needed.

## Alternatives
- **Non-frozen installs:** faster in some cases, and they dirty repos. Rejected.
- **Opt-in installs (v1's `-i`):** safer when installs were unsafe; no longer needed. The `strive-sync` wrapper keeps v1's opt-in behavior for existing users.
