---
canonical: true
canonical-id: template-communication-channels-guide
canonical-version: 2026-06-22
description: Communication channels and escalation guide
---

# Communication channels guide

## Reference

- [Feedback intake guide](feedback-intake-guide.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [Agent command map](agent-skill-map.md)
- [Weekly team check-in thread](weekly-team-check-in-thread.md)

## Purpose

Every work-relevant message lands in a known, searchable surface. Nothing decays in a DM. Nothing gets decided in a thread no one else can find. This guide defines which channels to create in the team's chat platform, what goes in each, and how to route each message type without deliberation.

## Two rules

**Public by default.** All work-relevant messages live in public channels so future-you, teammates, and clients can search them. If you are about to send a DM, ask whether the content is sensitive. If it is not, use the right public channel instead.

**DMs are for sensitive content only.** Acceptable exceptions: compensation and contracts, individual performance feedback, security incidents prior to public disclosure, legal matters. Everything else moves to a public channel.

## Required channels

Create these channels in the team's chat platform (Slack, Discord, Teams, or equivalent) before the first issue starts.

| Channel | Audience | Purpose |
|---------|----------|---------|
| `#stakeholder-feedback` | Stakeholders + engineers | Customer and stakeholder feedback intake. Primary source for `/create-issue`. |
| `#engineering` | Engineers only | Day-to-day engineering coordination, design discussion. |
| `#pr-review` | Engineers only | PR review requests, review status, and merge pings. Meta-questions about review norms. |
| `#daily-status` | Engineers (post) + stakeholders (read) | Daily async 3P updates from engineers (one message per workday). See [daily-status-update-guide.md](daily-status-update-guide.md). |
| `#ops-incidents` | All hands | SEV1-3 incidents, status updates, postmortem links. |
| `#announcements` | All hands (read-only for stakeholders) | Releases, demo recordings, weekly status. Stakeholders cannot post here. |
| `#demos` | Stakeholders + engineers | Pitch demos at ~80% burn (per [in-flow workflow guide](in-flow-workflow-guide.md)). |

All channels are public within the workspace. No private channels by default.

## Channel-by-message-type matrix

| Message type | Default channel | Skill |
|--------------|-----------------|-------|
| Async weekly status update | `#announcements` + email | `/status-update`, `/weekly-plan` (Default: Monday at 9:00 AM EST) |
| Pitch demo | `#demos` + meeting tool | `/walkthrough-video`, `/e2e-video` |
| Stakeholder feedback | `#stakeholder-feedback` | `/create-issue` |
| SEV1-3 incident | `#ops-incidents` | `/draft-message` (incident template) |
| PR review request | GitHub PR thread + `#pr-review` | `/pr`, `/review-pr` |
| Daily async standup | `#daily-status` | `/daily-standup` (client-facing) · [daily-status-update-guide.md](daily-status-update-guide.md) (internal 3P) |
| Weekly team check-in | `#engineering` | `/draft-message` · [weekly-team-check-in-thread.md](weekly-team-check-in-thread.md) |
| Sensitive (compensation, performance, legal) | DM | `/draft-message` |

When in doubt: post publicly. A message that ends up in the wrong public channel is recoverable. A message that stays in a DM is lost.

## PR review: channel vs. thread

Two surfaces, two jobs.

**GitHub PR thread.** All substantive review feedback goes here: inline comments, change requests, approval rationale, and blocking concerns. The PR thread is the permanent record; any future reader must be able to reconstruct every decision from the PR alone without consulting a chat channel.

**`#pr-review` channel.** Use it for everything that does not belong in a single PR thread: review requests ("can someone pick this up by EOD?"), status pings ("PR #123 is ready for re-review"), merge notifications, and meta-questions that span multiple PRs ("how do we handle this pattern going forward?").

The test: if a comment would only matter to the reviewer and the author of this specific PR, it goes in the PR thread. If it would be useful to a future engineer reading across PRs, post in the channel and link to the PR.

## Per-client overrides

Each client's `client.json` stores the primary and secondary chat platforms:

```json
{
  "communicationChannels": {
    "primary": "slack",
    "secondary": "email"
  }
}
```

Skills that send messages (`/draft-message`, `/meeting-summary`, `/weekly-plan`)
read `communicationChannels.primary` to determine where to route the output.
Accepted values: `"slack"`, `"discord"`, `"teams"`, `"email"`,
`"whatsapp"`. When the field is unset, default to `"email"`. `/create-issue`
does not route a drafted reply through this setting; it closes Slack message
permalinks and Discord message URLs with the scanner reaction path. Slack and
Discord DM scanner URLs have no automated reaction path and close through the
command audit output, like other non-reaction surfaces.

The channel names in the Required channels table apply to Slack and Discord. For Microsoft Teams, use the equivalent Team and channel hierarchy. For email-only clients, substitute `#stakeholder-feedback` with a shared inbox or tagged folder.

## Anti-patterns

| Anti-pattern | What to do instead |
|--------------|-------------------|
| DMing the team a question that future-you will need | Post in `#engineering` or the relevant channel |
| Splitting the same conversation across email, Slack, and GitHub | Pick one surface; link or copy the others |
| Filing feedback as a Slack DM that decays into nothing | Ask the stakeholder to post in `#stakeholder-feedback`, or run `/create-issue` on the DM yourself |
| Creating private channels "just to keep it tidy" | Use the required public channels; add a topic or pinned message if clarity is needed |
| Posting incident updates in `#engineering` instead of `#ops-incidents` | Always use `#ops-incidents` so stakeholders have a single place to follow |
| Posting daily 3P updates in `#engineering` instead of `#daily-status` | Always use `#daily-status` so stakeholders can follow without joining engineer-only channels |
| Posting substantive review feedback in `#pr-review` instead of the PR thread | Leave review critique as PR comments so the decision is reconstructable from the PR alone; use `#pr-review` only for requests, status, and meta-questions |

## Reference

- [Feedback intake guide](feedback-intake-guide.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [Agent command map](agent-skill-map.md)
- [Weekly team check-in thread](weekly-team-check-in-thread.md)
