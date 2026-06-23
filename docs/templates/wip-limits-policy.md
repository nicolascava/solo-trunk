---
canonical: true
canonical-id: template-wip-limits-policy
canonical-version: 2026-05-30
description: WIP limits policy reference
---

# WIP limits policy

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)

## Purpose

WIP (work in progress) limits are the primary flow-control mechanism in Shaped Kanban. This document defines the default limits, how they are enforced, and when to override them.

## Default limits (AI-native team)

| Stage | Default limit | Rationale |
|-------|--------------|-----------|
| Being shaped | 3 | Multiple agent workstreams can shape in parallel. |
| In progress | 3 | Multiple agent workstreams can build in parallel. |
| In review | 2 | Human review/verification is the scarce resource. Capped to create back-pressure and prevent the review queue from accumulating. |

These defaults are calibrated for an AI-native team where one human orchestrates multiple agents. The binding constraint is not raw throughput (agents are fast) but human judgment at the `In review` stage. Keeping `In review` at 2 ensures no more than two issues await human sign-off at any time.

`In review` and `Merged` are the only stages where a human is the bottleneck. `In progress` and `Being shaped` run at agent speed and can safely be wider.

## Enforcement

WIP limits are enforced by `packages/scripts/src/wip-check.ts`, which counts issues by Status on the live GitHub Project board:

```bash
# Check before starting a new In progress issue
bun packages/scripts/src/wip-check.ts --stage build --client nca

# Check before starting a new In review issue
bun packages/scripts/src/wip-check.ts --stage review --client nca

# Check before starting a new Being shaped issue
bun packages/scripts/src/wip-check.ts --stage shape --client nca
```

The `/start-issue` skill calls `wip-check.ts` automatically before advancing an issue to `In progress`. If the limit is reached, the script exits with code 1 and prints the current WIP count.

Custom limits:
```bash
bun packages/scripts/src/wip-check.ts --stage build --client nca --build-limit 4 --review-limit 3
```

## When to override

**Never increase In review WIP as a workaround.** The `In review` limit is the primary flow signal. If `In review` is full, the right action is to complete or skip a review, not to raise the cap.

**Team-size scaling.** For teams with more human reviewers, scale the `In review` limit proportionally:

| Team size | Being shaped limit | In progress limit | In review limit |
|-----------|-------------|-------------|--------------|
| 1 human + agents | 3 | 3 | 2 |
| 2 humans + agents | 4 | 4 | 3 |
| 3+ humans + agents | 4--6 | 4--6 | team size |

Increase incrementally. Watch kill rate and lead time; if either rises, lower the limit.

## WIP minimum for Being shaped

Maintain at least 1 issue in `Being shaped` at all times (when backlog is non-empty). An empty `Being shaped` column means `In progress` will run dry next. The `/shape-next` skill surfaces the top candidate when `Being shaped` is empty.

## Relationship to flow metrics

WIP limits directly affect lead time (Little's Law: lead time = WIP/throughput). Lower WIP at the human-gated stage (`In review`) keeps lead time short even when agent throughput is high. Track the effect via `/flow-metrics`.

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [Flow metrics guide](flow-metrics-guide.md)
