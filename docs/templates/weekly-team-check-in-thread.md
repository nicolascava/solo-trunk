---
canonical: true
canonical-id: template-weekly-team-check-in-thread
canonical-version: 2026-05-12
description: Start-of-week async thread to the engineering team asking about priority clarity, blockers, and anything else worth surfacing
---

# Weekly team check-in thread

## Reference

- [Communication channels guide](communication-channels-guide.md)
- [Daily status update guide](daily-status-update-guide.md)
- [Feedback intake guide](feedback-intake-guide.md)

## Purpose

This template provides a short, recurring async thread the technical lead posts at the start of each work week to the customer's engineering team. It is an inbound check-in: it asks the team three questions rather than reporting status. The goal is to surface blockers, unknowns, and priority confusion early in the week so they can be addressed before they slow delivery.

This template complements the outbound `/status-update` and `/weekly-plan` flows. Those push information out to stakeholders; this thread pulls information in from engineers.

## When to use it

Post this thread at the start of each work week, typically Monday morning in the team's primary timezone. Post it in the team's main engineering channel (default: `#engineering`) as a threaded message so all replies stay in one place and remain visible to the whole team.

Frequency can be adjusted in the client instantiation file. For teams with a strong daily-status habit, once every two weeks may be sufficient.

## The message

Copy and paste this block as-is. Replace `<Team>` with the customer's team name or a direct greeting, and `<week of YYYY-MM-DD>` with the Monday date of the current week.

```
Hi <Team>, quick check-in for the week of <week of YYYY-MM-DD>.

1. Are the priorities for this week clear? Anything that feels ambiguous or underspecified?
2. Any blockers or unknowns I can help support or unblock?
3. Anything else worth mentioning - technical debt, concerns, process friction, or anything on your mind?

Replying in this thread is best; it keeps everything visible to the whole team and easier to follow up on.
```

The three numbered questions map directly to the three check-in purposes: priority alignment, active support, and open-ended signal. Keep all three every time; dropping one removes a safety net.

## Per-platform notes

The message above is plain text with no formatting or emoji, so it renders well on any platform without changes.

**Slack/Discord:** Post in `#engineering` (or the client-equivalent channel). Use the platform's native reply thread so all answers are nested under the original message.

**Google Chat:** Start the message as a new thread in the relevant Space. Instruct the team to use "Reply" (not a new message) so responses stay in the same thread.

**Microsoft Teams:** Post in the team's Engineering or General channel. Use the "Reply" button under the post rather than posting a new message.

**Email-only clients:** Send to the engineering distribution list or a shared inbox. Ask the team to reply-all so responses remain visible to everyone.

## Following up

Once replies arrive, handle each type:

| Reply type | Action |
|------------|--------|
| Priority unclear | Clarify in the thread, then update the issue or roadmap CSV with the resolution |
| Active blocker | Assign yourself or an appropriate resource; track the dependency in the issue |
| Unknown/risk | Capture it via `/create-issue` if it warrants a roadmap item; otherwise resolve in the thread |
| General signal | Acknowledge in the thread; decide if a follow-up issue or ops Issue is warranted |

Close out the thread by end of week with a brief summary of actions taken, or a note that there were no blockers to report.

## Adopting this in a client repo

Create a thin instantiation file at `docs/customers/<slug>/docs/weekly-team-check-in.md` that opens with:

```markdown
This is the <Client Name>-specific instantiation of [Weekly team check-in thread](../../templates/weekly-team-check-in-thread.md). Read the template for the full rationale. This document records the <Client Name>-specific configuration.
```

Then record only the client-specific details:

- Channel name and platform (default: `#engineering`)
- Posting day and time (default: Monday, start of business in team's primary timezone)
- Who is responsible for posting (default: technical lead)
- Cadence (default: weekly; override to bi-weekly if daily-status habit is strong)
- Any custom greeting or opening line agreed with the team

To diverge from the template content itself, fork into `docs/customers/<slug>/.canonical-overrides/templates/weekly-team-check-in-thread.md` and follow the canonical-override convention in `docs/templates/README.md`.

## Anti-patterns

| Anti-pattern | What to do instead |
|--------------|-------------------|
| Sending the check-in as individual DMs to each engineer | Post in the shared engineering channel so the whole team sees the questions and answers |
| Posting a new message for each reply instead of threading | Always reply within the same thread to keep the conversation traceable |
| Merging this check-in into the outbound status update | Keep them separate: the status update pushes information to stakeholders; this thread pulls information from engineers |
| Treating it as a performance or accountability check | Frame it as support: "what can I help with?" not "what did you do?" |
| Skipping weeks without notice | If you skip, post a brief note in the channel so the team knows it is intentional |
| Asking follow-up questions across multiple new top-level messages | Reply within the thread so the context stays together |

## Reference

- [Communication channels guide](communication-channels-guide.md)
- [Daily status update guide](daily-status-update-guide.md)
- [Feedback intake guide](feedback-intake-guide.md)
