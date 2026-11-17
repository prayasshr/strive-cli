# 0006. Tickets as tool-maintained markdown notes

Status: Accepted, 2026-10-30 (revised the same day: time tracking removed)

## Context
Developers lose the thread of their work: what a task is, what was decided, what comes next. AI agents make this worse and better at once: they can resume work instantly if the context is written down in a predictable place, and they make a mess when they hand-edit structured files. A ticket-folder system used daily with agents showed the pattern works (one folder per ticket, frontmatter plus fixed sections, "next steps" so anyone can resume cold) and where it breaks: agents hand-editing structured parts, dates drifting, and a generated index going stale. Its hour log turned out to be the most painful part and the least useful to most developers.

## Decision
- Tickets are plain markdown files with YAML frontmatter, in the user's workspace, readable and editable by anyone.
- Strive owns the structured parts: frontmatter order, derived values (`updated`, `link`), and the dated notes. Every write recomputes them.
- Free-text sections may be edited by hand or through `strive t write`. "Next steps" is current state and is replaced; notes are history and are only appended.
- Nothing is stored that can be computed (no committed index).
- All vocabulary (ids, statuses, types, sections, fields) comes from `tickets.yml`, with presets.
- **No time tracking.** No clocks, hour logs or timesheets. It is a different product with a small audience, and it was the part users disliked most.

## Consequences
- Files diff cleanly in git and survive without Strive.
- Strive must parse and rewrite markdown it did not write, so `fmt` and `check` must be robust to hand edits.
- People who need timesheets use a time tracker. Custom fields can still hold an estimate or points.

## Alternatives
- **SQLite or JSON store:** easier to query, and opaque to people and to git review. Rejected.
- **Sync with a tracker's API:** out of scope for core (0005).
- **Built-in time tracking:** tried in an earlier draft; removed.
