# 🚀 Strive-Sync (v1.0.1)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.1-brightgreen.svg)]()
[![Built by](https://img.shields.io/badge/Built_by-Striving_Designs-black.svg)]()

> [!IMPORTANT]
> **Project Status: Stable**
> This tool is part of the `strive-cli` suite.

**Strive-Sync** is a parallel Git synchronization tool for multi-repository environments. It reduces the steps for keeping dozens of repositories in sync to a single command.

If you work in a microservices architecture or a distributed workspace, `strive-sync` saves you from the manual `git pull` and `npm install` loop.

---

## ✨ Features

- 🏎️ **Parallel Execution**: Syncs all repositories concurrently.
- 🎛️ **Mission Control Dashboard**: Real-time visual tracking for sync status, dirty states, and updates.
- 🧠 **Smart Branch Detection**: Automatically detects each repo's default branch from its remote HEAD reference — no hardcoding of `main` or `master`.
- 📦 **Opt-in Dependency Sync**: Use `--install` to run the correct package manager (`npm`, `yarn`, `pnpm`, or `bun`) when lockfiles change. Off by default so you're never surprised mid-development.
- 🎯 **Pinpoint Controls**:
  - `--only <repo>`: Sync ONLY the specified repository.
  - `--branch <name>`: Override the detected branch across all repos.
  - `--dry-run` (`-d`): Simulation mode to preview changes.
  - `--install` (`-i`): Opt-in to automatic dependency installation.
  - `--force` (`-f`): Force dependency install regardless of lockfile diffs.
- 🛡️ **Secure Architecture**: POSIX-compliant directory parsing, dynamic Git upstream tracking, and `mktemp`-based temp directories to prevent auth hangs.
- 🗂️ **Clean State Storage**: Persists mission memory to `$XDG_STATE_HOME/strive-sync/last_sync` (defaults to `~/.local/state/strive-sync/last_sync`), keeping your home directory clean.
- ⚙️ **Zero Config**: Runs out of the box — no configuration needed.

## 🚀 Usage

Navigate to any directory containing multiple Git repositories and run:

```bash
strive-sync
```

With dependency install enabled:

```bash
strive-sync --install
```

Force a full re-install of all deps:

```bash
strive-sync --force
```

### 🎛️ Options & Flags

| Flag | Short | Description |
| :--- | :--- | :--- |
| `--only <repo>` | `-o` | Sync ONLY the specified repository. |
| `--exclude <repo>` | `-e` | Skip a specific repository. |
| `--branch <name>` | `-b` | Override the target branch for all repos. |
| `--dry-run` | `-d` | Simulate the sync process without making changes. |
| `--install` | `-i` | Opt-in to automatic dependency installation when lockfiles change. |
| `--force` | `-f` | Force re-installation of dependencies regardless of lockfile diffs. |
| `--parallel <num>` | `-p` | Max parallel processes (default: 4). |
| `--help` | `-h` | Display the help menu. |

## 🛠️ Configuration (Optional)

`strive-sync` automatically discovers repositories in your workspace. For strict control, create a `.repos` file in your workspace root:

```text
# .repos format: <repo_name>[:<target_branch>]
auth-service:main
frontend-app:master
shared-ui:develop
legacy-api  # Defaults to the auto-detected remote HEAD branch
```

## 🏷️ Versioning

`strive-sync` auto-reads its version from the nearest git tag. To release a new version:

```bash
git tag v1.0.2
git push --tags
```

The script will automatically report the correct version on next run — no file edits needed.

## 🗂️ State Files

| File | Location |
| :--- | :--- |
| Last mission record | `~/.local/state/strive-sync/last_sync` |

Respects `$XDG_STATE_HOME` if set in your environment.
