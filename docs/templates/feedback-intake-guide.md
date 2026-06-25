---
canonical: true
canonical-id: template-feedback-intake-guide
canonical-version: 2026-06-22
description: Structured feedback intake guide
---

# Feedback intake guide

## Reference

- [Communication channels guide](communication-channels-guide.md)
- [Shaping and prioritization guide](shaping-prioritization-guide.md)
- [Agent command map](agent-skill-map.md)
- [Multi-surface intake guide](multi-surface-intake-guide.md)

## Purpose

Every piece of feedback lands as exactly one of: an ops issue, a backlog row,
a builder handoff, or a noted triage item. Nothing falls through. Nothing
lives unresolved in a DM or scanner inbox for more than 24 hours.

## Sources

| Source | Scanner/inbox | Channel |
|--------|-----------------|---------|
| Slack mentions and DMs | `slack-scan.ts` | `#stakeholder-feedback` (preferred) |
| Discord mentions and DMs | `discord-scan.ts` | `#stakeholder-feedback` |
| Threads comments | `threads-unanswered-comments.ts` | social |
| LinkedIn comments | `linkedin-unanswered-comments.ts` | social |
| GitHub issue comments | `gh issue list`, `extract-comments.ts` | repo |
| Email | `export-apple-mail.ts`, `mailbox-discovery.js` | inbox |
| Demo or live conversation | manual capture | meeting |

Roadmap rows and shaped issue documents can also originate from external intake surfaces (Google Sheets, Notion DB, Excel, Google Docs, Notion pages, Word). These are imported using the per-platform adapters configured for the repository and do not require manual scanner triage. See [Multi-surface intake guide](multi-surface-intake-guide.md).

Run the relevant scanner to surface unreplied items. Copy the source URL before triaging; it is written into the `Notes` column of any row or issue created so the item can be backtracked.

## Triage decision tree

Apply this tree once per feedback item, top to bottom. Stop at the first matching branch.

```
Is something broken in production?
  yes → assess severity (SEV1 / SEV2 / SEV3)
        → ops track: gh issue + set Severity project field to SEV<n>
        → skip the rest of this tree

  no  → Is it a structural change or new capability?
          yes → backlog row
                → create linked pre-shaped issue via /create-issue
                → suggest /shape when ready to replace the body with the full shaped template

          no  → Is it a tweak to an issue already in progress?
                  yes → owner of current issue addresses it before shipping
                        (per in-flow workflow guide "What to do when things go sideways")

                no  → Is it a small backlog item (under ~30 minutes)?
                        yes → standard backlog row
                              → create linked pre-shaped issue via /create-issue
                        no  → note only
                              → close the loop with source triage marking
```

When a node is ambiguous, use `/create-issue` which prompts for clarification via `AskUserQuestion` before persisting.

## Persistence

Run the canonical command for the disposition determined by the triage tree.

| Disposition | Command |
|-------------|---------|
| Ops issue | Resolve `ISSUE_REPO` from `coordinationRepo`, falling back to `githubRepos[0]`; then run `gh issue create --repo "$ISSUE_REPO" --title "<title>" --body-file <body-file>` and set Severity on the project board with `gh project item-edit --id <board-item-id> --field-id <severity-field-id> --project-id <project-node-id> --single-select-option-id <SEVn-option-id>` (field IDs from `https://github.com/nicolascava/solo-trunk/blob/main/docs/templates/github-coordination-conventions.md`) |
| Backlog row | Create the linked issue first with `gh issue create --repo "$ISSUE_REPO" --title "<title>" --body-file <body-file>`, then append a row to the external roadmap with the title, type, category, slice, source URL, and linked issue URL. Add the issue to the project board when configured, and record the issue URL in the row's `Issue` column |
| Builder handoff | Do not create a row or issue; share the feedback with the current issue owner |
| Note only | No row or issue; close with source triage marking |

The `--source <url>` flag writes `source:<url>` into the `Notes` field of the new external roadmap row. This lets `/create-issue` backtrack the item to its origin when following up later.

`Priority rank` is left empty by `add-issues-row.ts`. Run `/roadmap` to re-rank. When the item is ready to shape, run `/shape` to replace the pre-shaped issue body with the full shaped template.

## Source close-out

Every disposition closes the triage loop. Slack message permalinks and Discord
message URLs close through the scanner reaction path; surfaces with no automated
reaction path close through the command audit note.

| Disposition | Source close-out |
|-------------|------------------|
| Ops issue | `✅` scanner reaction for Slack message permalinks or Discord message URLs; otherwise noted as triaged |
| Backlog row | `✅` scanner reaction for Slack message permalinks or Discord message URLs; otherwise noted as triaged |
| Builder handoff | `✅` scanner reaction for Slack message permalinks or Discord message URLs; otherwise noted as triaged |
| Note only | `✅` scanner reaction for Slack message permalinks or Discord message URLs; otherwise noted as triaged |

Slack message permalinks and Discord message URLs are closed by adding a `✅`
scanner reaction to the original message using the scanner ack command. Slack DM
scanner URLs (`https://slack.com/app_redirect?channel=<id>`) do not include a
message timestamp, so they cannot be acked automatically; record them as triaged
in the command audit output. Discord DMs use scanner URLs
(`/channels/@me/<dm-id>`) that do not include a message ID, so they cannot be
acked automatically; record them as triaged in the command audit output. Teams,
GitHub, Threads, LinkedIn, email, and manual captures have no automated reaction
path; note them as triaged in the command audit output.

## Rules

**Triage within 24 hours.** An unreplied scanner mention older than 24 hours is a failure of this process.

**One item, one disposition.** Do not file the same feedback as both a backlog row and an ops issue. Pick the correct track based on the triage tree.

**No mid-issue scope from feedback.** A stakeholder asking for something during an active `In progress` issue is not a mid-issue scope addition. If it is structural, add a backlog row to the external roadmap. If it is a tweak to the current issue, the builder addresses it before shipping. Never expand the issue in flight.

**No ops issues for structural improvements.** The ops track is reactive. A feature request or improvement belongs in the external roadmap as `Backlog`, not in the ops GitHub issue backlog.

**Urgency is not a disposition.** A feedback item arriving urgently still goes through the triage tree. If a customer is blocked right now, expedite the issue by pulling it immediately into the appropriate Project status; do not skip the triage step.

## Anti-patterns

| Anti-pattern | What to do instead |
|--------------|-------------------|
| Letting feedback sit as an unreplied scanner mention for >24h | Triage daily; run `/create-issue` as part of the daily workflow |
| Adding mid-issue scope from feedback | Add a backlog row to the external roadmap; record the triage outcome through source triage marking |
| Filing every casual ask as a backlog row | Some casual asks only need source triage marking; apply the triage tree |
| Filing structural feedback as an ops issue | Ops is reactive; structural improvements go to the external roadmap as `Backlog` |
| Acting on every "urgent" stakeholder label without triage | Apply the triage tree; prioritize the issue only when a customer is genuinely blocked right now |

## Reference

- [Communication channels guide](communication-channels-guide.md)
- [Shaping and prioritization guide](shaping-prioritization-guide.md)
- [Customer-service to GitHub Issues guide](customer-service-to-github-issues-guide.md)
- [Agent command map](agent-skill-map.md)
- [Multi-surface intake guide](multi-surface-intake-guide.md)
