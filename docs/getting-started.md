# Getting started with Strive

> This guide describes Strive 2.1, which is planned and not yet released. Today's release is the `strive-sync` command (see `README_sync.md`).

## What Strive does, in one minute

Your team's code lives in several repos. Every morning they need to be up to date, on the right language version, with their packages installed. Strive does that with one command. It never touches work you haven't committed, and it tells you plainly what needs you.

It also keeps a notes file for each piece of work: what it is, what you decided, and what comes next. You, a teammate, or an AI agent can pick up any ticket cold.

Three things to remember:

1. **`strive sync` gets you ready.** Run it every morning.
2. **Strive never breaks your work.** If it can't do something safely, it skips it and tells you.
3. **"Needs you" means you act.** Everything else is handled.

## Day one (about 15 minutes)

**1. Install**

```
brew install strivingdesigns/tap/strive
```

No Homebrew? Use the install script from the README.

**2. Get your team's workspace**

Ask your lead for the team's workspace link, then:

```
mkdir ~/code && cd ~/code
strive init --from <the link>
```

That copies the team's repo list and settings. If your team doesn't have a shared workspace, clone the repos you need into `~/code` and run `strive init`.

**3. Get everything ready**

```
strive sync
```

The first run clones every repo and installs everything, so it takes a while. When it finishes, read the **Needs you** list at the bottom. On day one it usually says one of these:

| It says | Do this |
|---|---|
| git could not log in | Set up your SSH key for your git host (the line includes the link) |
| needs Node 24 (or Python 3.12, ...), which is not installed | Run the command shown, e.g. `nvm install 24` or `mise install` |
| a tool is not installed | Install it with the command shown |

Fix those, then run `strive sync` again, until it ends with `0 need you`. You're ready to work.

Don't understand a status? Ask Strive:

```
strive help status diverged
```

## Your day

| When | Command | What it does |
|---|---|---|
| Morning | `strive sync` | Updates every repo, installs what changed, and shows what came in overnight |
| Standup | `strive standup` | Your commits since the last working day, tickets that moved, and what's next |
| New ticket | `strive t start PROJ-142 "Short title" --repo web-app` | Creates the ticket's notes and a branch from fresh code |
| Decided something | `strive t note "Page size goes in config"` | Adds a dated note to the ticket on your current branch |
| Pausing work | `strive t next "Re-request review"` | Sets where to pick up, for you or an agent |
| Before you leave | `strive status` | Warns about anything not committed or not pushed |
| Ticket finished | `strive t done` | Closes it and sets the repo back to following main |

## Cheat sheet

```
strive sync          get ready
strive status        what did I leave unfinished?
strive t             my active tickets and their next step
strive t start ID    begin a ticket
strive t note "..."  remember a decision
strive t next "..."  where to pick up
strive t done        finish a ticket
strive standup       what did I do?

Add --help to any command. Add --json when a script or an AI agent is reading.
```

## Where your files are

```
~/code/
  .repos                  the team's repo list
  .strive/
    config.yml            settings
    tickets.yml           how your team names tickets
    tickets/PROJ-142/     one folder per ticket, a README.md inside
  api-service/  web-app/  ...
```

Everything is plain text. You can open any file in your editor.

## Using an AI agent

Agents use the same commands with `--json`, and can trust the exit code:

| Exit code | Meaning |
|---|---|
| 0 | All ready |
| 1 | Something failed |
| 2 | The command was wrong |
| 3 | Something needs you |

Two things to tell your agent:
- "Run `strive sync --json` and tell me what needs me."
- "Run `strive t show --json`, continue from the next steps, and update them with `strive t next` when you stop."
