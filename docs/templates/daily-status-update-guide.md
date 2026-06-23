---
canonical: true
canonical-id: template-daily-status-update-guide
canonical-version: 2026-05-07
description: End-of-day async status update guide for engineers
---

# Daily status update guide

## Reference

- [Communication channels guide](communication-channels-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [Agent skill map](agent-skill-map.md)

## Purpose

Every engineer posts a short written status update at the end of their workday. No standup meeting. No shared clock. The update is posted in `#daily-status` where the whole team can read it, search it, and reply asynchronously.

This replaces the synchronous daily standup. The format is inspired by Basecamp's Heartbeat pattern: work is visible by default, communicated in writing, and never dependent on everyone being online at the same time.

## Two rules

**Post once per workday, at your end of day.** Timezone and work schedule are yours to own. Post when your day ends, whatever time that is. If you took the day off or did no work related to the team, post nothing; do not pad.

**Every Progress item must be backed by a verifiable artifact.** A commit, a merged PR, a deployed change. "Worked on X" without a link is not a Progress item.

## The 3P format

Copy this template and fill it in:

```
**Progress**
- <one line per shipped item — include a PR or commit link>

**Plans**
- <one line per next-up item — link to a scope Issue or task>

**Problems**
- <one line per blocker or open question, or "None">
```

**Section rules:**

- One bullet per line. No sub-bullets.
- Link to GitHub artifacts (PRs, Issues, commits) wherever possible.
- The Problems section always appears. Write "None" if there are no blockers.
- Keep each bullet to one line. No narrative prose.
- No file paths, no internal acronyms, no jargon that a new team member would not recognize.

## Where to post

Post in `#daily-status`. One message per engineer per workday. No threads required, but use a reply thread if the message prompts a question or discussion.

Do not DM the team your update. Do not post in `#announcements`. The `#daily-status` channel is the canonical home for daily async status.

## Cadence

Post at **your** end of day, not at a fixed team clock. Async-first means no shared schedule. A 6am engineer in Paris and a 2pm engineer in Montréal both post when their day ends. Neither waits for the other.

If you worked on an issue that spans multiple days, post every day you did active work on it. If a day was meetings-only with no shipped artifacts, write that in Plans or Problems rather than padding Progress.

## Relationship to issue comments

The 3P daily update in `#daily-status` is for team-wide visibility: teammates and stakeholders can follow along without reading GitHub.

Blocker escalation and hill-chart-driven scope status still live as **comments on the active issue**; that is the durable issue record. See [In-flow workflow guide](in-flow-workflow-guide.md) for the blocker escalation ladder (2 hours -> post on Issue; 24 hours -> tag CTO).

The two surfaces are complementary, not redundant:

| Surface | Audience | Purpose |
|---------|----------|---------|
| `#daily-status` 3P update | Team + stakeholders | Daily visibility; searchable in chat |
| Issue comment | Builders + CTO | Durable issue record; blocker escalation |

## Worked example

A builder working on a two-week pitch posts this at 5:45pm on a Tuesday:

```
**Progress**
- Merged scope "Export CSV" behind feature flag (PR #214)
- Fixed edge case where empty rows crashed the exporter (commit abc1234)

**Plans**
- Finish scope "Column picker UI" (Issue #198) — approach is clear, halfway done
- Open PR for column picker tomorrow morning

**Problems**
- None
```

The next day, after hitting a blocker:

```
**Progress**
- Opened PR #217 for column picker UI (draft — waiting on design review)

**Plans**
- Resolve design question on column ordering before merging #217

**Problems**
- Design review blocked on designer availability - posted on issue #201, tagged the designer; will tag CTO within 24 hours per escalation policy.
```

## Anti-patterns

| Anti-pattern | What to do instead |
|--------------|-------------------|
| Padding Progress with planning notes or meeting summaries | Only list items backed by a commit, PR, or deployed change |
| Omitting the Problems section | Always include it; "None" is a valid and good answer |
| Posting in a DM | Post in `#daily-status`; DMs are invisible to the team |
| Mixing client-facing 3P with the internal update | Client-facing standup is a separate artifact; use `/daily-standup` for that |
| Holding a synchronous standup to discuss the update | Refuse; post async; use threads for replies |
| Writing multi-line bullets | One line per item. If it needs more, open a thread |
| Skipping a day without explanation | Post "No active work today" or simply post nothing; never post fabricated progress |

## Reference

- [Communication channels guide](communication-channels-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [Agent skill map](agent-skill-map.md)
