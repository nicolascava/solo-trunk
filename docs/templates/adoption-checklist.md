---
canonical: true
canonical-id: template-adoption-checklist
canonical-version: 2026-06-24
description: Shaped Kanban adoption checklist for new teams
---

# Adoption checklist

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [CSV state store](csv-state-store.md)

## Purpose

Step-by-step checklist for setting up Shaped Kanban in a new client GitHub repository. Complete these steps before the first issue enters `In progress`.

## Prerequisites

- A GitHub repository with Issues, Projects, and Milestones enabled
- `gh` CLI installed and authenticated for the client repository
- Bun 1.x available (for the scripts in `packages/scripts/`)
- This monorepo cloned locally for the CSV utility scripts
- **Org issue types enabled.** The repository must be owned by a GitHub
  organization with the three default issue types enabled (Bug, Feature, Task).
  Enable them at
  `https://github.com/organizations/<org>/settings/issue-types` before the
  first issue is created. User-owned repositories skip this requirement; native
  issue type setting will be unavailable.

## Step 1: Connect the external roadmap and create the GitHub Project

**External roadmap.** Configure the client's roadmap source in `client.json`. The external system (Google Sheets, Notion, or Excel) is the source of truth for the prioritized backlog.

```json
{
  "roadmapSystem": "gsheets",
  "roadmapSpreadsheetId": "<spreadsheet-id>"
}
```

Accepted values for `roadmapSystem`: `"gsheets"`, `"notion"`, `"excel"`, `"jira"`.

**GitHub Project.** Run the provisioning script to create and configure the project automatically:

```bash
bun run packages/scripts/src/provision-github-project.ts --client <slug> [--dry-run]
```

This creates a GitHub Project titled `Shaped Kanban` with the canonical pipeline columns (`Triage`, `Ready to be shaped`, `Being shaped`, `Shaped`, `Ready to work`, `In progress`, `In review`, `Merged`, `Shipped`, `Canceled`), provisions the `Issue size (days)`, `Severity`, `Priority`, `Effort`, `Impact`, and `Rank` project fields, and imports any existing issues from `docs/customers/<slug>/issues.csv`. Run with `--dry-run` first to preview all actions. The script also prints the manual steps for the canonical Project views: `Contributors`, `Leadership`, `Roadmap`, and `All issues`.

**tasks.csv.** Create the following file in the client repository under `docs/` and commit it:

```
docs/tasks.csv
id,list,description,completed,completedAt,appetite,reminder,appleReminderId
```

**Install issue template.** Run `bun run packages/scripts/src/pull-shaped-issue-template.ts` from this monorepo to regenerate `.github/ISSUE_TEMPLATE/shaped-issue.yml` from `docs/templates/shaped-issue-template.md`, then copy that file into the client repository. Commit it.

## Step 2: Mirror the canonical templates

Create a `docs/customers/<client-name>/docs/` directory in this monorepo (or directly in the client repository). For each template in `docs/templates/`, create a thin instantiation file that opens with:

```markdown
This is the <Client Name>-specific instantiation of [<template name>](../../templates/<file>.md). Read the template for the full rationale. This document records the <Client Name>-specific configuration.
```

Then add the client-specific details: participant names and roles, WIP limit overrides, OKR alignment criteria, and any process overrides.

## Step 3: Seed the external roadmap

Add existing backlog items as rows in the client's external roadmap (Google Sheets, Notion, or Excel). Each row represents a potential issue; fill in Title, Description, Category, Type, Effort, Impact, and Slice at minimum. Leave `Pipeline state` as `Backlog` for all new rows. The sync scripts map that stable CSV value to the `Ready to be shaped` GitHub Project status.

Run `/roadmap <client-slug>` to pull the ranked backlog and confirm the external system is reachable.

## Step 4: Define communication channels

Set up the team's communication structure before any issue enters `In progress`. See [Communication channels guide](communication-channels-guide.md).

1. Create the seven required public channels in the client's chat platform (Slack, Discord, Teams, or equivalent):
   - `#stakeholder-feedback`: feedback intake from stakeholders and customers
   - `#engineering`: day-to-day engineering coordination
   - `#pr-review`: PR review requests, status, and merge pings (engineer-posted)
   - `#daily-status`: end-of-day 3P async updates from engineers (stakeholder-visible; engineer-posted)
   - `#ops-incidents`: SEV1–3 incidents and status updates
   - `#announcements`: releases and weekly status (read-only for stakeholders)
   - `#demos`: pitch demos at ~80% burn
2. Set `communicationChannels.primary` (and optionally `secondary`) in `client.json`:
   ```json
   { "communicationChannels": { "primary": "slack" } }
   ```
   Accepted values: `"slack"`, `"discord"`, `"teams"`, `"email"`, `"whatsapp"`.
3. Pin `#stakeholder-feedback`, `#ops-incidents`, and `#daily-status` so they are visible to all members.
4. Inform stakeholders that `#stakeholder-feedback` is the canonical intake channel for all requests and feedback.
5. Share [Daily status update guide](daily-status-update-guide.md) with engineers and confirm they post end-of-day 3P updates in `#daily-status`.

## Step 5: Configure intake surfaces (optional)

Skip this step if the shaper is comfortable running CLI commands or editing CSVs directly.

Set up one or more external intake surfaces so non-technical shapers can submit roadmap rows and pitches from their own tools. See [Multi-surface intake guide](multi-surface-intake-guide.md) for the full per-platform setup.

1. Choose the client's tool stack:
   - **Google Workspace**: Google Sheets (rows) + Google Docs (pitches)
   - **Notion**: Notion DB (rows) + Notion pages (pitches)
   - **Microsoft 365**: Excel on OneDrive (rows) + Word on OneDrive (pitches)
2. Create the intake surface using the copy-paste template from [Multi-surface intake guide](multi-surface-intake-guide.md) for the chosen platform.
3. Set `intakeSync` in `client.json`:
   ```json
   {
     "intakeSync": {
       "enabled": true,
       "spreadsheet": { "platform": "google-sheets", "intakeRange": "Intake!A2:Z" },
       "documents": { "platform": "google-docs", "draftFolderId": "<folder-id>" }
     }
   }
   ```
4. Run `bun run packages/scripts/src/intake-from-gsheets.ts --client <slug> --dry-run` (or the appropriate platform adapter) to validate the adapter configuration before enabling live imports.

## Step 6: Shape the first issues

Run `/shape` in the monorepo for the top 2–4 problems from the external roadmap. Each run:
1. Creates or updates the GitHub Issue body with the shaped content
2. Backfills canonical project fields and moves the issue to `Shaped` in the GitHub Project
3. @-mentions the decider for review

See [Issue gate guide](bet-gate-guide.md) for the async sign-off process.

## Step 7: Pass the first issue gate

For each issue the decider accepts:
1. Post a sign-off comment on the GitHub Issue (shaper + decider names and dates)
2. Move the accepted issue from `Shaped` to `Ready to work` in the GitHub Project

## Step 8: Start the first issue

When ready to begin:

```bash
/start-issue <issue-number>
```

The skill moves the issue to `In progress` in the GitHub Project and sets `Started date`. The circuit-breaker clock starts at `Started date`.

Run the kickoff session with the builder. See [In-flow workflow guide](in-flow-workflow-guide.md).

## Step 9: Verify before going live

- [ ] All seven required public channels exist in the client's chat workspace
- [ ] Both CSVs exist in `docs/` with correct header rows (`docs/tasks.csv`, `docs/deferred-findings.csv`)
- [ ] `Issue size (days)`, `Severity`, `Priority`, `Effort`, `Impact`, and `Rank` project fields exist (run `bun run packages/scripts/src/provision-github-project.ts --dry-run` to verify)
- [ ] At least one issue is in Project `Status=Ready to work` or `Status=In progress`
- [ ] A GitHub Project exists for tracking issues
- [ ] Every relative link in the client instantiation docs resolves
- [ ] `bun packages/scripts/src/wip-check.ts --stage build --client <slug>` exits 0 (no WIP violation)

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [CSV state store](csv-state-store.md)
- [Communication channels guide](communication-channels-guide.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [Issue gate guide](bet-gate-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
