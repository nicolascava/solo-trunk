---
canonical: true
canonical-id: template-shaping-prioritization-guide
canonical-version: 2026-05-28
description: Shaping and prioritization guide for the issue review table
---

# Shaping prioritization guide

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [Agent skill map](agent-skill-map.md)

## Purpose

Shaped Kanban documents the issue gate and the build flow with precision, but leaves "which problem do we shape next?" implicit. This guide closes that gap. It defines when shaping happens, which roadmap signals determine what to shape, and how to avoid common failure modes.

## When shaping happens

Shaping is continuous. There is no cycle boundary to wait for. A shaper can pick up a new shape candidate any time the `Being shaped` column is empty.

In practice:
- **Immediately after an issue passes the issue gate.** The shaping slot is free; run `/shape-next` to select the next candidate.
- **Any time a high-impact problem is identified.** If the `Being shaped` WIP limit is already reached, the problem goes to the external roadmap as `Backlog` and will be prioritized in the next run.

## Shape candidates

A row in the external roadmap is a shape candidate when **all** of the following hold:

| Field | Condition |
|-------|-----------|
| `Pipeline state` | `Backlog` |
| Linked GitHub Issue | none; a linked issue means the item is already shaped |
| `Appetite` OR `Type` | `Appetite` is unset, **OR** `Type = Spike` (unknowns always need shaping regardless of appetite) |

Items with a linked GitHub Issue already have a shaped issue; they belong at the issue gate, not the shaping queue.

## Shape rank

Candidates are ranked by:

```
Shape rank = Priority score + Proximity bonus
```

Where **Priority score** is the value in the external roadmap (Impact − (Effort − 1) × 0.5 + urgency bonus from due date), and **Proximity bonus** is an additional shaping-specific urgency signal:

| Due date distance | Proximity bonus |
|-------------------|----------------|
| ≤ 28 days (or past) | +1.0 |
| 29 – 56 days | +0.5 |
| > 56 days or missing | 0 |

Ties are broken by Priority score descending, then Issue ID ascending.

The CLI implementation is `packages/scripts/shape-queue.ts`:

```bash
bun packages/scripts/shape-queue.ts [--top N] [--json]
```

## Capacity rule

Do not shape more candidates than you expect to need for the next two issue decisions. Pessimism wins: if you expect two approved issues in the next month, shape at most four issues (2x issue slots). Over-shaping creates a false sense of optionality and dilutes the adversarial review in `/shape`.

## Anti-patterns

**No shaping backlog.** Unchosen shape candidates stay in the external roadmap as `Backlog` rows with no linked GitHub Issue. They are not moved to a separate list, not labeled "deferred," and not carried forward in any state other than their current roadmap row. The queue is recomputed fresh from the external roadmap each time.

**No auto-selection.** The `/shape-next` skill surfaces the ranked list but requires a human to pick the item. Strategic judgment (not score alone) drives the shaping decision.

**No shaping while In progress is at WIP limit.** Shaping competes for the same senior attention as circuit-breaker decisions and scope calls. If you are on-call for an `In progress` issue in trouble, hold shaping until the issue resolves.

## Tooling

| Tool | Purpose |
|------|---------|
| `bun packages/scripts/shape-queue.ts` | Compute and display the ranked queue from the external roadmap |
| `/shape-next` | Interactive: runs the CLI, presents the queue, prompts for selection, hands off to `/shape` |
| `/shape <idea>` | Full shaping ritual: capture → calibration → adversarial review → create GitHub Issue |

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [Agent skill map](agent-skill-map.md)
