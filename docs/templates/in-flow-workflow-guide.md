---
canonical: true
canonical-id: template-in-flow-workflow-guide
canonical-version: 2026-06-04
description: In-flow daily workflow guide for engineers
---

# In-flow workflow guide

## Reference

- [Circuit breaker rule](circuit-breaker-rule.md)
- [Issue gate guide](bet-gate-guide.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [WIP limits policy](wip-limits-policy.md)

## Purpose

This guide describes the day-to-day workflow inside an `In progress` issue. It is the tactical companion to:

- [Circuit breaker rule](circuit-breaker-rule.md): what happens when appetite runs out
- [Issue gate guide](bet-gate-guide.md): what comes before `In progress`
- [GitHub coordination conventions](github-coordination-conventions.md): Issues, labels, and branch naming

## Two principles that hold everything together

1. **The issue ships as a whole.** There is one completion gate: the user scenarios in the issue pass and the no-gos hold. Progress within the appetite is continuous integration to trunk, not milestone-by-milestone sign-off.
2. **The trunk is always deployable.** Every change reaches `main` behind a feature flag that is off by default. Branches live for hours or a few days, never the full appetite window. The circuit breaker becomes a flag decision, not a revert.

## Roles

| Role | Responsibility inside In progress |
|------|-----------------------------|
| CTO | Enforces circuit breaker; intervenes on 24h+ blockers |
| Shaper | Presents the issue at kickoff; available for clarifications during the first two days |
| Builder | Integrates to trunk daily behind the feature flag, ships the issue at appetite end |
| Ops lead | Handles ops-class interrupts; does not participate in In progress issues |

## Pulling an issue into In progress

Work is pull-based. The builder runs `/start-issue` when the `In progress` column is below the WIP limit and a `Ready to work` issue is available:

```bash
/start-issue <issue-number>
```

The skill:
1. Checks the WIP limit via `wip-check.ts` (counts `In progress` issues on the live board; limit = 3); refuses if `In progress` is at capacity
2. Moves the issue to `In progress` in the GitHub Project; sets `Start date` to today (first-touch: skips if already set)
3. Computes and writes `End date = addBusinessDays(Start date, appetite)` (appetite is the Number 1–5 from the `Appetite` project field); this is both the roadmap endpoint and the appetite hard stop

## Kickoff (Day 1)

The shaper presents the issue to the builder. The session is 45–60 minutes, synchronous, because issue context transfer is bandwidth-intensive.

The kickoff covers:
- **Problem and appetite.** What are we solving, and how much time are we willing to spend? The appetite is fixed. Scope is variable.
- **Solution sketch and rabbit holes.** Where might this go wrong? What did the shaper deliberately leave out (no-gos)?
- **Open questions.** Not tasks; open questions the builder will resolve during the build.

What the builder does NOT do at kickoff:
- Break the work into a task list
- Estimate sub-tasks
- Assign tickets

What the builder DOES set up at kickoff:
- **A thread on the issue** for async discussion
- **A feature flag** in the application's flag system, off in every environment, named after the issue

## Daily appetite-burn check

Check each morning whether the issue's appetite is still intact:

- Read `Start date` from the GitHub Project (set by `/start-issue` when the issue is pulled into `In progress`)
- Read the `Appetite` Number project field (1–5 business days)
- Compute elapsed business days and burn percentage (elapsed/appetite × 100)
- If `burnPct ≥ 100`, the circuit breaker has fired: apply it

When `burnPct` crosses 80%, cut work that cannot land in the remaining appetite.

## Trunk-based integration

Every builder works on short-lived branches off `main`.

- **Branch names:** `<handle>/<short-description>`. See [GitHub coordination conventions](github-coordination-conventions.md).
- **Lifetime:** 1–2 days maximum.
- **Merging:** Open a PR, get one review, merge the same day or the next morning.
- **CI:** Every PR runs the full test suite. A red `main` is a stop-the-line event; fix or revert within 30 minutes.
- **Behind a flag:** All issue code is gated by the issue's feature flag, off everywhere except local dev.
- **Database changes:** Schema migrations are backwards-compatible (additive). Backfill scripts are separate. The flag controls whether the new schema is read.

## Blocker escalation

Status updates happen as comments on the issue, not in meetings.

| Duration blocked | Action |
|------------------|--------|
| < 2 hours | Solve it. Don't ping anyone. |
| 2 hours | Post on the issue with what you tried and what's blocking. Tag the builder. |
| 24 hours | Tag the CTO. They intervene (technical help, work cut, or shaper recall). |
| Cannot resolve within appetite | The work is cut to protect the circuit-breaker date. |

## Midpoint check

Run one check at roughly the halfway point of the appetite (at ~50% burn).

Questions:
- What is still unfinished at the halfway point?
- Should any work be cut now to protect the circuit-breaker date?

## Demo

Hold a demo to stakeholders (CTO, relevant observers) when the issue is at ~80% burn.

After the demo:
- Cut work that cannot land in the remaining appetite; default: cut
- Stakeholder wording or minor UX feedback is addressed before shipping; structural changes become a new issue

## Shipping (100% burn)

When the issue is done (user scenarios pass and no-gos hold), run `/ship-issue`:

```bash
/ship-issue <issue-number> --action ship
```

Flip the issue's feature flag on in production. Monitor. Post a shipping note on the issue covering what shipped, what was cut, and any known limitations.

## Circuit breaker (100% burn, not done)

When `burnPct ≥ 100` and the issue is not done, apply the [circuit breaker](circuit-breaker-rule.md):

```bash
/ship-issue <issue-number> --action kill
```

Shippable scopes (already done, behind the flag) may still ship. In-progress scopes: the flag stays off. Close the scope Issues with a note that they were killed. The issue can be re-shaped with a corrected appetite.

## Worked example

| Day | What happens |
|-----|--------------|
| Day 1 | Builder runs `/start-issue`. Sets `Start date` and computes `End date` (e.g. 2026-05-12 for appetite=5 starting 2026-05-06). Kickoff with shaper. Feature flag created. |
| Day 2 | Builder discovers 4 scopes. Records them as a task list in the issue body. |
| Day 3 | Two scopes checked off. One scope still unstarted; potential cut. Scope check (~50% burn for appetite=5). |
| Day 4 | Unstarted scope cut. Three remaining scopes progressing. Burn at ~80%. |
| Day 5 | All three scopes checked off. Flag enabled in staging. Demo to CTO. |
| Day 5 | `/ship-issue --action ship`. Flag flipped on in production. Shipping note posted. Issue closed. |

## What to do when things go sideways

| Situation | Response |
|-----------|----------|
| A scope is still unchecked past the halfway point | Flag it at the scope check. Default action: cut. |
| `main` is red after a merge | Whoever broke it fixes or reverts within 30 minutes. No work continues on top of red. |
| A stakeholder demands a new scope | "Let's shape it as the next issue." Add to external roadmap backlog. Do not add to the current issue. |
| An issue is going to miss the appetite | Apply the circuit breaker. Ship what's done. Kill the rest. Re-shape with corrected appetite. |
| An ops interrupt asks for build help | Refuse. The ops lead handles it. |

## Reference

- [Circuit breaker rule](circuit-breaker-rule.md)
- [Issue gate guide](bet-gate-guide.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [WIP limits policy](wip-limits-policy.md)
