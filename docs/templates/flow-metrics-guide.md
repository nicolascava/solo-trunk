---
canonical: true
canonical-id: template-flow-metrics-guide
canonical-version: 2026-06-24
description: Flow metrics tracking and interpretation guide
---

# Flow metrics guide

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)

## Purpose

Flow metrics are the primary health signal for a Shaped Kanban system. They replace the cycle-level retrospective with a continuous, data-driven view of the pipeline's performance.

Run `/flow-metrics` or `bun packages/scripts/src/flow-metrics.ts` each week to compute the current period's metrics.

## The four metrics

### Throughput

**Definition:** Number of issues shipped (moved to the `Shipped` column in the GitHub Project) in the measurement period.

**Unit:** issues per week.

**Why it matters:** Throughput is the most direct signal of delivery health. A sustained drop in throughput means the system is slowing down; usually because WIP is too high, appetites are too large, or the shaping queue is empty.

**Source:** GitHub Issues in the `Shipped` column of the GitHub Project, filtered by close date.

**Target:** At least 1 issue shipped per 2 weeks. Below 1 per month is a signal to investigate.

### Lead time

**Definition:** Median calendar days from `In progress` start (`Started date` in the issue body) to the issue shipping (`Completed date` in the issue body or close date).

**Unit:** days.

**Why it matters:** Lead time measures how long a commitment sits in the system before it delivers value. Long lead time usually means high WIP, large appetites, or a clogged Ready to work queue.

**Target:** < 10 business days for a size-5 (1-week) issue. Smaller appetites proportionally shorter.

### Appetite hit-rate

**Definition:** Percentage of shipped issues that completed within their stated appetite (i.e. elapsed business days from `Start date` to `Completed date` ≤ appetite, where appetite is the Number project field (1–5)).

**Unit:** percentage.

**Why it matters:** Appetite hit-rate measures how accurate the shaping process is. A healthy hit-rate means issues are well-understood before they enter `In progress`. A declining hit-rate means rabbit holes are not being resolved during shaping.

**Target:** ≥ 80%. Below 60% is a signal to tighten the shaping process or revisit appetite calibration.

### Kill rate

**Definition:** Percentage of issues that entered `In progress` and were killed (moved to the `Canceled` column in the GitHub Project) rather than shipped.

**Unit:** percentage.

**Why it matters:** Kill rate measures the circuit breaker's effectiveness. A kill rate that is too low (< 5%) suggests the circuit breaker is not being applied consistently. A kill rate that is too high (> 20%) suggests appetites are systematically too small or issues are entering `In progress` under-shaped.

**Target:** 5–15%. This is a healthy range; it means the circuit breaker is real, and shaping is mostly accurate.

## How to run

```bash
# Current 4-week period
bun packages/scripts/src/flow-metrics.ts

# Custom date range
bun packages/scripts/src/flow-metrics.ts --from 2026-04-01 --to 2026-04-30

# JSON output for scripting
bun packages/scripts/src/flow-metrics.ts --json
```

Output includes throughput, median lead time, appetite hit-rate, and kill rate for the period, plus a summary table of completed or killed issues.

## Weekly review cadence

Run `/flow-metrics` every Friday. The output takes 5 minutes to review. Key questions:

1. Is throughput on trend?
2. Is lead time growing? If so, is it WIP, appetite, or queue depth?
3. Is appetite hit-rate declining? If so, which issues missed, and why?
4. Is kill rate in the healthy range?

This review is the cadence anchor for Shaped Kanban; it replaces the fixed-cycle synchronized rhythm of traditional Shape Up.

## Interpreting the data

| Signal | Likely cause | Suggested action |
|--------|-------------|------------------|
| Throughput declining | WIP too high, or issues too large | Lower WIP limit or split Large issues into Small |
| Lead time growing | Ready to work queue backing up | Pull sooner; check if Ready to work queue is too large |
| Appetite hit-rate < 60% | Under-shaped issues | Add adversarial review step to `/shape`; check rabbit holes |
| Kill rate > 20% | Appetites too small | Recalibrate to Large appetite; review circuit-breaker decisions |
| Kill rate < 5% | Circuit breaker not enforced | Check if killed issues are being silently extended |

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [WIP limits policy](wip-limits-policy.md)
- [Circuit breaker rule](circuit-breaker-rule.md)
