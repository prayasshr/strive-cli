# 🚀 Strive CLI (v1.0.1)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**Striving Designs** | Built by **[Prayas Shrestha](https://github.com/prayasshr)**

**Strive CLI** is a collection of developer tools for keeping complex workflows fast and predictable. Built for microservices and monorepos, these tools allow teams to stop managing environments and start building.

## 🧰 The Toolbox

Currently, the Strive CLI suite includes:

### `strive-sync` (Available Now)
A visual, parallel Git sync tool for multi-repository environments. Auto-detects each repo's default branch, syncs in parallel, and keeps `node_modules` out of the way until you actually need them.

👉 **[Read the full documentation for strive-sync](README_sync.md)**

### `strive-env` (Coming Soon)
Synchronized environment variable management across your team.

### `strive-start` (Planned)
The orchestrator. Spin up your local development environment, tailored to the specific services you need, with one command.



### Manual Installation

Choose the installation method that best fits your workflow and security preferences.

### Option 1: Global Installation (Requires Sudo)
This is the recommended approach for most users. It installs the CLI tools to `/usr/local/bin`, making them available system-wide.

```bash
# Clone the repository
git clone https://github.com/prayasshr/strive-cli.git
cd strive-cli

# Install globally
sudo ./install.sh
```

### Option 2: Local Installation (Non-Sudo)
If you prefer not to use `sudo` or don't have root access, you can install the tools to your local home directory (`~/.strive/bin`).

```bash
# Clone the repository
git clone https://github.com/prayasshr/strive-cli.git
cd strive-cli

# Install locally
./install.sh --user
```

> [!NOTE]
> For the local installation, you may need to add `~/.strive/bin` to your `PATH`. The installer will provide specific instructions if this is required.
>
> To manually add it, append the following line to your shell profile (~/.zshrc or ~/.bashrc):
> ```bash
> export PATH="$HOME/.strive/bin:$PATH"
> ```
> Then restart your terminal or run: `source ~/.zshrc` (or `source ~/.bashrc`).

## 🤝 Contributing

We welcome contributions. Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to help make Strive CLI better.

---

<p align="center">
  <b>Built by Prayas Shrestha</b><br>
  <a href="https://strivingdesigns.com">strivingdesigns.com</a>
</p>
