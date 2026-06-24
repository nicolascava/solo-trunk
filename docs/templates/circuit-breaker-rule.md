---
canonical: true
canonical-id: template-circuit-breaker-rule
canonical-version: 2026-06-24
description: Circuit breaker rule for WIP overload recovery
---

# Circuit breaker rule

## Reference

- [Issue gate guide](bet-gate-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)

## The rule

If an issue is not complete when its appetite is exhausted (elapsed business days ≥ appetite, i.e. `burnPct ≥ 100`), it is killed. No extensions. The team can re-shape it and resubmit it through the issue gate, but the issue does not carry over automatically.

## Why this works

Extending issues feels safer but isn't. Every extension:

- Trains the team to treat appetite as a soft boundary
- Blocks the `In progress` column for the next issue in queue (WIP violation)
- Obscures whether the original appetite was realistic (a carried-over issue never gets re-evaluated)

Killing and re-shaping forces an honest answer: was the appetite wrong? Was the scope too large? Did a rabbit hole get missed during shaping? The re-shape conversation produces a better-scoped issue than a silent extension would.

## What "killed" means in practice

`Canceled` is the terminal state for any issue stopped before release. It covers issues eliminated at or before the issue review table and issues stopped mid-execution by the circuit breaker.

Anything that is shippable at appetite end ships. If a scope is complete and provides standalone value, it goes out. The remainder is discarded.

Specifically:
- Completed scopes (behind the feature flag, fully demoable) are deployed
- In-progress scopes that cannot ship alone have their flag left off permanently
- No partial features in production

## How to apply the circuit breaker

When elapsed business days since `Started date` ≥ appetite (read the `Appetite` Number project field (1–5) and `Start date` from the GitHub Project; the clock is set automatically when a draft PR with `Closes #<issue>` is opened):

```bash
/ship-issue <issue-number> --action kill
```

This moves the issue to `Canceled` in the GitHub Project and closes the GitHub Issue. Any scopes that independently shipped before the cancellation are noted in the closing comment on the issue.

## Enforcement

The CTO enforces the circuit breaker. This is not a team vote. If there is pressure to extend, the CTO's answer is no.

The first time a pitch is killed sets the precedent for every pitch after it. If the first application is negotiated away, the rule has no teeth.

## Re-shape process

1. The shaper (or the builder who worked the issue) runs `/shape` to create a revised GitHub Issue with an updated appetite and corrected scope, noting what went wrong.
2. The revised issue goes through the normal issue gate: async sign-off from shaper and decider via an issue comment.
3. The issue gate decides whether to approve it. There is no priority advantage for a previously killed issue.

## FAQ

**Can we extend by just a day or two?**
No. "A couple of days" becomes a week. The appetite boundary must be hard to be useful.

**What if the issue was almost done?**
Shippable scopes ship. The rest is cut. "Almost done" is a signal that the appetite was too small or a rabbit hole was underestimated. The re-shape should address that.

**What if an external dependency caused the delay?**
That is a valid reason to re-shape with a note explaining the blocker. It is not a reason to extend the current issue.

**Who decides what is "shippable"?**
The CTO, in consultation with the builder. When in doubt, do not ship partial work.

**Does the circuit breaker apply to expedite-class issues?**
Yes. Expedite issues have a shortened appetite and are still subject to the circuit breaker. Bypassing WIP limits does not bypass the time box.

## Reference

- [Issue gate guide](bet-gate-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
