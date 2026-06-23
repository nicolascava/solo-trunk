---
canonical: true
canonical-id: template-agent-skill-map
canonical-version: 2026-06-22
description: Agent skill-to-task mapping reference
---

# Agent command map

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [Communication channels guide](communication-channels-guide.md)
- [Multi-surface intake guide](multi-surface-intake-guide.md)

## Purpose

This document maps each Shaped Kanban phase to the Claude Code command that drives it. Commands marked "gap" do not yet exist. Their proposed CLIs and side effects are listed so each can be built as a standalone PR, TDD-first.

## Phase map

| Phase | Command | Status | Reads | Writes |
|-------|-------|--------|-------|--------|
| Bootstrap CI checks (lint/style/type/test) for a customer repo | `/setup-ci` | exists | `docs/customers/<slug>/client.json`, `git` remote | prints template path + secret commands (no file writes) |
| Bootstrap CI doc-sync for a client | `/setup-sync-ci` | exists | `docs/customers/<slug>/client.json` | prints CI snippet + secret commands (no file writes) |
| Pick what to shape next | `/shape-next` | exists | external roadmap | none (hands off to `/shape`) |
| Shape an issue | `/shape` | exists | external roadmap, conversation context | GitHub Issue body (creates/updates via `gh`); native issue type (via `set-issue-type.ts`); GitHub Project `Issue size (days)` and `Status=Shaped` |
| Rank the roadmap | `/roadmap` | exists | external roadmap | external roadmap (reorders rows) |
| Run the issue review table (required gate before Ready to work) | `/betting-table` | exists | GitHub Project board (Shaped issues) | GitHub Issue comment (issue gate sign-off with `Priority:` line recording P# / Rank); GitHub Project (moves chosen issues to Ready to work, sets board Rank field) |
| Run the issue gate quality sign-off | (async GitHub Issue sign-off) | intentional gap; async process, not a skill | shaped GitHub Issues | human decision |
| Start an issue in progress | `/start-issue` | exists | GitHub Issue, GitHub Project | GitHub Project (moves issue to In progress, sets `Started date`) |
| Bulk-import issues from external roadmap | `/import-issues` | exists | external roadmap rows | GitHub Issues (via `gh issue create`) |
| Plan a week | `/weekly-plan` | exists | `docs/tasks.csv`, external roadmap, issues | weekly plan doc, client email (Default: Monday at 9:00 AM EST) |
| Generate stakeholder status update | `/status-update` | exists | `git` history, GitHub PRs, monorepo deliverables | client-ready status update doc (Default: Monday at 9:00 AM EST) |
| Generate status update slides | `/status-slides` | exists | `git` history, GitHub PRs, monorepo deliverables | Slidev-compatible markdown presentation |
| Post daily async update | `/daily-standup` (client-facing) · [daily-status-update-guide.md](daily-status-update-guide.md) (internal 3P) | exists | issues, scope Issues; `git` history for client variant | status comment on issue; 3P message posted in `#daily-status` |
| Sync scope Issues | `/update-issues` | exists | GitHub Issues | GitHub Issues (status updates) |
| Open a PR for a scope | `/pr` | exists | current branch diff | GitHub PR |
| Ship or kill an issue | `/ship-issue` | exists | GitHub Issue, GitHub Project | GitHub Project (moves to Shipped/Killed), GitHub Issue (closed) |
| Close an already-solved issue | `/close-solved-issue` | exists | GitHub Issue, GitHub Project | GitHub Project (moves to Shipped), GitHub Issue (closed) |
| Compute flow metrics | `/flow-metrics` | exists | GitHub Issues (Done/Killed via `gh`) | none (advisory output) |
| Run retrospective | `/retro` | exists | `git` log, PR history | retrospective doc in `docs/retros/` |
| Triage stakeholder feedback | `/create-issue` | exists | scanner output, external roadmap, `client.json` | external roadmap (new row), GitHub Issues (native issue type via `set-issue-type.ts`), scanner reaction or triage note |
| Classify a GitHub Issue for scheduling | `/triage` | exists | GitHub Issue, GitHub Project | GitHub Project (`Priority`, `Effort`, and `Impact` fields); GitHub Issue (native issue type via `set-issue-type.ts`) |

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [Communication channels guide](communication-channels-guide.md)
- [Multi-surface intake guide](multi-surface-intake-guide.md)
