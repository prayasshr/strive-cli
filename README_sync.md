# 🚀 Strive-Sync (v1.0.0-beta)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0--beta-orange.svg)]()
[![Built by](https://img.shields.io/badge/Built_by-Striving_Designs-black.svg)]()

> [!IMPORTANT]
> **Project Status: Beta**
> This tool is part of the `strive-cli` suite and is currently in a "Mission Readiness" testing phase.

**Strive-Sync** is a parallel Git synchronization tool for multi-repository environments. It reduces the steps for keeping dozens of repositories in sync to a single command.

If you work in a microservices architecture or a distributed workspace, `strive-sync` saves you from the manual `git pull` and `npm install` loop.

---

## ✨ Features

- 🏎️ **Parallel Execution**: Syncs all repositories concurrently.
- 🎛️ **Mission Control Dashboard**: Real-time visual tracking for sync status, dirty states, and updates.
- 🧠 **Workspace Pivoting**: Run from anywhere. `strive-sync` detects sub-directories and pivots to the workspace root.
- 📦 **Smart Dependency Sync**: Detects lockfile changes and runs the correct install command (`npm`, `yarn`, `pnpm`, or `bun`).
- 🎯 **Pinpoint Controls**:
  - `--only <repo>`: Sync ONLY the specified repository.
  - `--branch <name>`: Override the default branch across the workspace.
  - `--dry-run` (`-d`): Simulation mode to preview changes.
  - `--no-install` (`-n`): Skip dependency installations.
- 🛡️ **Secure Architecture**: POSIX-compliant directory parsing, dynamic Git upstream tracking, and secure `mktemp` allocation to prevent auth hangs.
- ⚙️ **Low Friction**: Zero configuration needed by default.

## 🚀 Usage

Navigate to any directory containing multiple Git repositories (or a sub-folder of one of those repositories) and run:

```bash
strive-sync
```

### 🎛️ Options & Flags

| Flag | Short | Description |
| :--- | :--- | :--- |
| `--only <repo>` | `-o` | Sync ONLY the specified repository. |
| `--exclude <repo>` | `-e` | Skip a specific repository. |
| `--branch <name>` | `-b` | Override the target branch (default tries `main` then `master`). |
| `--dry-run` | `-d` | Simulate the sync process without making changes. |
| `--no-install` | `-n` | Skip automatic dependency installation (npm/yarn/pnpm/bun). |
| `--force` | `-f` | Force re-installation of dependencies even if lockfiles haven't changed. |
| `--parallel <num>` | `-p` | Max parallel processes handling the downloads (default: 4). |
| `--help` | `-h` | Display the help menu. |

## 🛠️ Configuration (Optional)

`strive-sync` automatically discovers repositories in your workspace. However, if you want strict control, you can create a `.repos` file in your workspace root:

```text
# .repos format: <repo_name>[:<target_branch>]
auth-service:main
frontend-app:master
shared-ui:develop
legacy-api  # Defaults to the global target branch
```
