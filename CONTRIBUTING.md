# Contributing to Strive CLI

Thank you for considering contributing to the **Strive CLI** suite.

We value clean code, clear terminal output, and utility. Our goal is to build tools that eliminate developer friction.

## How Can I Contribute?

### 🐛 Reporting Bugs
If you find a bug, please create an issue on GitHub. Include:
- Your operating system and terminal environment.
- The version of the specific tool (e.g., `strive-sync --version`) you are using.
- A clear description of the problem and steps to reproduce it.

### ✨ Suggesting Enhancements
Have an idea to make the **Strive CLI** tools better? Create an issue describing your idea, the problem it solves, and how it should work.

### 💻 Contributing Code
If you want to contribute code:
1. **Fork** the repository.
2. **Clone** your fork locally.
3. **Create a branch** for your feature or bug fix (`git checkout -b feature/new-idea`).
4. **Develop** your changes. Keep them focused and clean.
5. **Test** your changes thoroughly. Check the terminal output format.
6. **Commit** your changes with a descriptive message.
7. **Push** to your fork.
8. **Open a Pull Request** against the `main` branch of the official `strive-cli` repository.

## Coding Guidelines

- **Language**: Core scripts are written in standard Bash. Stick to POSIX-compliant or standard Bash features where possible to maintain cross-platform support (macOS/Linux).
- **Style**: Keep the code readable. Use descriptive variable names (`CURRENT_REPO_NAME` instead of `crn`).
- **Feedback**: If your change affects the user experience, ensure the terminal output is clean, aligned, and uses the established color variables (`${CYAN}`, `${GREEN}`, etc.).
- **Performance**: The toolkit's primary value is speed. Avoid synchronous blocking operations inside loops unless necessary. Rely on background processes (`&`) and `wait`.

## Code of Conduct

Please treat everyone with respect. We are a community of builders, and that extends to how we interact with one another. Harassment or abusive behavior will not be tolerated.

---

*Thank you for helping us build better tools.*
