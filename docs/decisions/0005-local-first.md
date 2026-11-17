# 0005. Local first

Status: Accepted, 2026-10-30

## Context
Strive runs inside people's work: private repos, internal trackers, company conventions. Trust requires that it sends nothing anywhere and that the public project contains nothing specific to any company.

## Decision
- Strive's only network traffic is what the user's own tools do: git fetch and clone, and package managers installing.
- No telemetry. No update checks unless the user opts in.
- Secret values (env values, tokens) are never printed or stored.
- Every company-specific value (ticket key patterns, tracker URLs, statuses, repo lists) lives in the user's config files. Strive's code, docs, tests and examples use neutral placeholders only (`acme`, `PROJ-142`, `api-service`).
- Remote services (issue trackers, CI, code review) are not part of core. They may come later as optional plugins.

## Consequences
- No usage data to guide decisions. Adoption is measured from public signals: stars, issues, downloads.
- Integrations people may want (e.g. pulling a ticket title from a tracker) wait for a plugin system.

## Alternatives
- **Opt-out telemetry:** common, and it erodes trust in a tool that touches private code. Rejected.
