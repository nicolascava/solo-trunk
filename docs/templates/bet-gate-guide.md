---
canonical: true
canonical-id: template-bet-gate-guide
canonical-version: 2026-06-20
description: Issue gate review guide for Shaped Kanban
---

# Issue gate guide

## Reference

- [Circuit breaker rule](circuit-breaker-rule.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [CSV state store](csv-state-store.md)
- [GitHub coordination conventions](github-coordination-conventions.md)

## Purpose

The issue gate is the decision point that advances a shaped issue from `Shaped` to `Ready to work`. It is the quality check before an issue enters the `In progress` queue. In Shaped Kanban the gate is rolling and async-by-default; no scheduled ceremony is required.

## Who decides

| Role | Responsibility |
|------|---------------|
| Shaper | Shapes the issue and requests sign-off. |
| Decider | Reviews and signs off. Typically the CTO. |

The shaper and the decider must be different people. The decider's sign-off is final.

## Issue review table (required)

Before any shaped issue advances to `Ready to work`, the team runs a comparative
prioritization step called the issue review table. This is a required gate (not
a ceremony) that ranks all `Shaped` issues against each other and records a
decision before any of them may enter `Ready to work`.

Run `/betting-table <client>` to present the ranked list of shaped issues
and record the decision for each one.

Only after the issue review table records a `Priority:` line for an issue may
it advance to `Ready to work`. The `bet-prioritization-check.ts` guard enforces
this before `/start-issue` allows an `In progress` pull.

The issue review table discussion may be sync (a short meeting) or async (a
GitHub issue comment thread or Slack thread). What is mandatory is the
recorded decision in the sign-off comment.

## Default process: async GitHub Issue sign-off

1. The shaper runs `/shape`, which creates or updates the GitHub Issue body with the shaped content, backfills canonical project fields, and moves the issue to `Shaped` in the GitHub Project.
2. The shaper @-mentions the decider in a comment requesting review.
3. The decider reviews the GitHub Issue. If accepted, they post a sign-off comment.
4. The team runs the issue review table and records a `Priority:` line in the same sign-off comment.
5. The shaper moves the accepted issue from `Shaped` to `Ready to work` in the GitHub Project.

Sign-off format as an issue comment:

```
**Issue gate sign-off**
- Shaper: <name> (<date>)
- Decider: <name> (<date>)
- Priority: <P0–P4> / <High|Medium|Low> (issue review table <date>)
```

The `Priority:` line is the machine-checkable proof that the issue review table
ran. Being in the `Ready to work` column is already the decision; no `Decision:` line
is required. The optional `/ <High|Medium|Low>` Rank segment records the
relative order within a Priority level decided at the issue review table.

## Optional weekly huddle

Teams that prefer a lightweight synchronous touchpoint can run a 30-minute weekly issue huddle. This is not a full ceremony; it handles only issues that are contested or have open questions. Uncontested issues advance via async sign-off without attending.

The huddle does not replace the async process. Issues must still have written sign-off as an issue comment before moving to `Ready to work` in the GitHub Project.

## Pitch quality gate

Before signing off, the decider evaluates:

1. **Appetite vs. impact.** Is this worth its appetite (1–5 business days) of `In progress` capacity?
2. **Rabbit holes resolved.** Are the unknowns identified and addressed? Issues with unresolved rabbit holes are returned to the shaper.
3. **No-gos explicit.** What is deliberately out of scope?

## Issue format (shaped body)

The GitHub Issue body follows the canonical shaped-issue template. Print the current body skeleton:

```bash
bun run packages/scripts/src/print-shaped-issue-body.ts
```

The template source of truth is `docs/templates/shaped-issue-template.md`. The GitHub new-issue form is at `.github/ISSUE_TEMPLATE/shaped-issue.yml`; regenerate it with `bun run packages/scripts/src/pull-shaped-issue-template.ts`.

## Deferred issues

An issue that does not pass the gate is returned to the shaper with written feedback as an issue comment. The issue stays in the Shaping stage. The shaper revises and re-requests sign-off.

An issue the decider chooses not to approve right now is moved back to `Ready to be shaped` in the GitHub Project (not killed). A brief note is added as an issue comment. It can be re-shaped for a future issue review.

## Reference

- [Circuit breaker rule](circuit-breaker-rule.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [CSV state store](csv-state-store.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
