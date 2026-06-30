---
canonical: true
canonical-id: template-shaped-kanban-overview
canonical-version: 2026-06-30
description: One-page Shaped Kanban framework reference
---

# Shaped Kanban overview

## Reference

- [Issue gate guide](bet-gate-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [Circuit breaker rule](circuit-breaker-rule.md)
- [Communication channels guide](communication-channels-guide.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [Multi-surface intake guide](multi-surface-intake-guide.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [CSV state store](csv-state-store.md)
- [Agent skill map](agent-skill-map.md)
- [Adoption checklist](adoption-checklist.md)
- [Shaping prioritization guide](shaping-prioritization-guide.md)
- [WIP limits policy](wip-limits-policy.md)
- [Flow metrics guide](flow-metrics-guide.md)

## What Shaped Kanban is

Shaped Kanban keeps the strategic primitives from Shape Up: appetite, shaping, issue selection, circuit-breaker; and replaces the temporal primitives (fixed cycles, synchronized starts) with continuous-flow mechanics: WIP limits and pull-based starts.

There is no build cycle. Each issue is a self-contained unit with its own appetite clock that starts when it enters `In progress`.

## The pipeline

```
Triage → Ready to be shaped → Being shaped → Shaped → Ready to work → In progress → In review → Merged → Shipped
                                                                                                          ↘ Canceled
```

| Stage | Meaning |
|-------|---------|
| `Triage` | Raw idea, needs assessment. |
| `Ready to be shaped` | Accepted, queued; not yet being shaped. |
| `Being shaped` | Active shaping work. WIP-limited. |
| `Shaped` | Pitch complete, ready for the issue review table. |
| `Ready to work` | Committed, queued; not yet started. |
| `In progress` | In active development. Appetite clock is running. WIP-limited. |
| `In review` | Work done, awaiting review/QA. WIP-limited. |
| `Merged` | Merged, awaiting deploy. |
| `Shipped` | Deployed and live. |
| `Canceled` | Stopped before release. May be re-triaged or re-pitched later. |

All pipeline state lives in the GitHub Project board. The customer's external roadmap (Google Sheets, Notion, or Excel, configured in `client.json`) is the source of truth for prioritization.

## Per-issue appetite

Appetite is set during shaping and belongs to the issue, not a cycle.

| Appetite | Business days | When to use |
|----------|---------------|-------------|
| 1 | 1 business day | Tiny, well-scoped fixes |
| 2 | 2 business days | Small incremental improvements |
| 3 | 3 business days | Well-understood problems |
| 4 | 4 business days | Medium-sized capabilities |
| 5 | 5 business days (1 week) | New capabilities, meaningful user-facing changes |

One week (5 business days) is the ceiling. Work that genuinely needs more must be broken into smaller issues or re-shaped.

The appetite clock starts when the builder runs `/start-issue`, which sets `Start date` and computes `End date = addBusinessDays(Start date, appetite)`. The circuit breaker fires when elapsed business days ≥ appetite.

## Three phases

**Shaping** is continuous, not cycle-bound. The shaper picks the highest-ranked unshaped problem from the external roadmap (see [Shaping prioritization guide](shaping-prioritization-guide.md)), runs `/shape`, and the resulting GitHub Issue enters `Being shaped` state. At most three issues are in `Being shaped` at any time (WIP limit). When shaping is complete the issue moves to `Shaped`.

**Issue approval** has two required steps, both of which must produce a recorded decision before an issue may advance to `Ready to work`.

First, the team runs the **issue review table** (`/betting-table`), a comparative prioritization step that ranks all `Shaped` issues against each other. The person or group with decision authority picks which issues to commit to next. Each chosen issue gets a `Priority:` line recorded in its sign-off comment. This step is a required gate: the `bet-prioritization-check.ts` guard blocks `In progress` pull until that line is present. The discussion may happen in a meeting, a Slack thread, or a GitHub issue comment; what matters is the recorded decision.

Second, each issue must have a per-issue quality sign-off from both the shaper and decider: appetite-vs-impact, rabbit holes, no-gos. This is the async GitHub Issue sign-off described in the [Issue gate guide](bet-gate-guide.md). Issues not chosen at the issue review table stay in `Shaped` or move to `Ready to be shaped`. Issues that fail the quality review return to the shaper for revision.

**Building** is pull-based. When `In progress` is empty (or below limit) and a `Ready to work` issue is available, the builder pulls the highest-priority issue into `In progress` via `/start-issue`. The builder discovers scopes, integrates to trunk, and ships at or before 100% appetite burn. See [In-flow workflow guide](in-flow-workflow-guide.md).

## WIP limits (AI-native team defaults)

| Stage | Limit | Constraint |
|-------|-------|-----------|
| Being shaped | 3 | Agent workstreams |
| In progress | 3 | Agent workstreams |
| In review | 2 | Human judgment |

Enforced by `wip-check.ts` (reads the live GitHub Project board) and the `/start-issue` skill. See [WIP limits policy](wip-limits-policy.md).

## Flow metrics

Track weekly via `/flow-metrics`.

| Metric | Description |
|--------|-------------|
| Throughput | Issues shipped per week |
| Lead time | Median days from Ready to work → Shipped |
| Appetite hit-rate | % of issues shipped within appetite |
| Kill rate | % of In progress issues killed (healthy: 5–15%) |

See [Flow metrics guide](flow-metrics-guide.md).

## Five non-negotiables

1. **Appetite over estimation.** The question is never "how long does this take?" It is "how long are we willing to spend?"
2. **Fixed time, variable scope.** The appetite does not move. Scope is cut to fit.
3. **The circuit breaker.** Pitches at 100% appetite burn are killed, not extended. Re-pitch if still worth doing.
4. **Trunk is always deployable.** Every change lands on `main` behind a feature flag, off by default.
5. **`/start-issue` sets the clock.** Running `/start-issue` sets `Start date` and computes `End date = addBusinessDays(Start date, appetite)`. Do not set these fields manually.

## Artifacts

| Artifact | Form | Lives in |
|----------|------|----------|
| Issue (shaped issue) | GitHub Issue | GitHub Issues |
| Pipeline state | GitHub Project board column | GitHub Projects |
| Appetite | `Appetite` Number project field (1–5 business days) | GitHub Projects |
| Start date | `Start date` project date field | GitHub Projects |
| End date | `End date` project date field | GitHub Projects |
| Severity | `Severity` project field (`SEV1` / `SEV2` / `SEV3` / `SEV4`) | GitHub Projects |
| Priority | `Priority` project field (`P0` / `P1` / `P2` / `P3` / `P4`) | GitHub Projects |
| Focused | `Focused` project field (`Yes` / `No`); per-assignee focus flag; at most one per assignee | GitHub Projects |
| Effort | `Effort` project field (`Low` / `Medium` / `High`) | GitHub Projects |
| Impact | `Impact` project field (`Low` / `Medium` / `High`) | GitHub Projects |
| Rank | `Rank` project field (`High` / `Medium` / `Low`); secondary sort within a Priority level, set at the issue review table | GitHub Projects |
| Prioritized backlog | External roadmap | Google Sheets/Notion/Excel (per `client.json`) |

## Roles

| Role | Responsibility |
|------|---------------|
| Shaper | Shapes issues. CTO, PM, or senior engineer. |
| Decider | Approves issues. CTO + strategic lead at minimum. |
| Builder | Executes the issue, integrates to trunk daily behind the feature flag. |
| Ops lead | Handles ops-class interrupts. |

## Communication and feedback

All work-relevant messages live in public channels. DMs are reserved for sensitive content only (compensation, performance, legal, security pre-disclosure). See [Communication channels guide](communication-channels-guide.md) for the required channel list and channel-by-message-type routing matrix. The weekly stakeholder status update defaults to **Monday at 9:00 AM EST**.

Every piece of stakeholder or customer feedback is triaged within 24 hours:
classified, persisted as an ops issue, backlog row, existing tracked item, or note,
and closed with source triage marking. See [Feedback intake guide](feedback-intake-guide.md)
for the triage decision tree and persistence commands. Use `/create-issue` to
run the full triage loop end to end.

## Agent skill map (summary)

| Phase | Skill | Status |
|-------|-------|--------|
| Pick what to shape next | `/shape-next` | exists |
| Shape an issue | `/shape` | exists |
| Rank the roadmap | `/roadmap` | exists |
| Run the issue review table (required gate) | `/betting-table` | exists |
| Start an issue in progress | `/start-issue` | exists |
| Post daily async update | `/daily-standup` (client-facing) · [daily-status-update-guide.md](daily-status-update-guide.md) (internal 3P) | exists |
| Open a PR | `/pr` | exists |
| Ship or kill an issue | `/ship-issue` | exists |
| Compute flow metrics | `/flow-metrics` | exists |
| Triage stakeholder feedback | `/create-issue` | exists |

See [Agent skill map](agent-skill-map.md) for the full table.

## Reference

- [Issue gate guide](bet-gate-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [Circuit breaker rule](circuit-breaker-rule.md)
- [Communication channels guide](communication-channels-guide.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [Multi-surface intake guide](multi-surface-intake-guide.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [CSV state store](csv-state-store.md)
- [Agent skill map](agent-skill-map.md)
- [Adoption checklist](adoption-checklist.md)
- [Shaping prioritization guide](shaping-prioritization-guide.md)
- [WIP limits policy](wip-limits-policy.md)
- [Flow metrics guide](flow-metrics-guide.md)
