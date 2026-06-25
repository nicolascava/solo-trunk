---
canonical: true
canonical-id: template-customer-service-to-github-issues-guide
canonical-version: 2026-05-27
description: Process and automation guide for routing support conversations to GitHub Issues without duplicating content
---

# Customer-service platform → GitHub Issues guide

## Reference

- [Multi-surface intake guide](multi-surface-intake-guide.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [GitHub coordination conventions](github-coordination-conventions.md)
- [Shaping and prioritization guide](shaping-prioritization-guide.md)
- [CSV state store](csv-state-store.md)
- [Agent skill map](agent-skill-map.md)

---

## Principles

**Single source of truth.** The customer-service platform (Intercom, Zendesk, Front, …) owns the conversation. The GitHub Issue is a lightweight triage record; a pointer, not a copy. Engineers read the full context in the support platform.

**No transcript duplication.** Issue bodies must never contain a copy of the conversation thread. They must contain a link to it. Duplicating content creates maintenance debt: any update in the support platform is invisible to engineers reading the issue, and vice-versa.

**Idempotency.** The sync job is safe to run repeatedly. It sets a `github_issue_url` custom attribute on the conversation after creating the issue. On subsequent runs (or duplicate button clicks), any conversation that already carries this attribute is silently skipped.

**No GitHub access required for support.** The entire trigger surface lives inside Intercom. Agents click one button; they never open or interact with GitHub.

---

## How agents file issues

A Canvas Kit app is installed in the Intercom Inbox sidebar. It renders a **"File to GitHub"** button on live customer conversations.

### Conversations (customer-reported)

1. Open the conversation in the Intercom Inbox.
2. Click **"File to GitHub"** in the sidebar app.
3. The button shows a loading state while the issue is created (< 5 s).
4. The sidebar updates to confirm: "Filed as GitHub issue #\<number>" with a link.

### Standalone tickets (agent-initiated, no customer)

> **Not yet supported.** The submit handler returns an error canvas for ticket-only payloads. This section will be updated when standalone ticket sync is implemented.

Support agents never touch the GitHub UI.

---

## What syncs

### Into the GitHub Issue (thin record)

| Field | Value |
|-------|-------|
| Title | `[Support] <conversation subject or first line>` |
| Body | Conversation URL, reporter name, date, instructions to read the full thread in Intercom. No transcript. |
| Label | `from-support` (default; configurable via `issueLabels`) |
| Repo | `client.json#intercomSync.targetRepo` |
| Project | Added to `client.json#intercomSync.project` (GH Projects v2 board) via `gh project item-add` |

### Back into the conversation (link record)

| Field | Value |
|-------|-------|
| Custom attribute `github_issue_url` | URL of the newly created issue; idempotency marker and quick link |
| Internal note | "GitHub issue created: `<url>`", visible to the support team, not to the customer |

---

## Idempotency

The submit handler checks `conversation.custom_attributes.github_issue_url` before creating an issue.

- **Attribute absent** → create the issue, add to the GH Project, set the attribute, add the note.
- **Attribute present** → return an "Already filed" canvas with the existing URL. Nothing is created.

A failed run (e.g. the `gh` command errored) leaves the attribute unset, so the conversation is automatically retried on the next button click or on the daily backstop run.

---

## Triage and shaping handoff

Once the issue is created it enters the normal Shaped Kanban pipeline:

1. An engineer or PM triages the issue: adds priority, applies the right label, links it to the current or next shaped issue if relevant.
2. Structural or repeated issues are shaped via the `/shape` skill.
3. Task-sized issues are picked up from the `Ops` service class.
4. Issues that do not meet the issue-gate threshold are closed with a note.

The roadmap CSV row is optionally appended (the `Issue` column stores the issue number; the `Notes` column stores the conversation URL), enabling the issue to appear in shape-queue scoring.

---

## Configuration

> **Editing client.json:** edit the client's `client.json` directly and commit the change.

Add an `intercomSync` block to the client's `client.json`:

```json
{
  "intercomSync": {
    "enabled": true,
    "region": "us",
    "workspaceId": "ws_abc123",
    "triageTag": "to-github",
    "targetRepo": "Owner/repo",
    "issueLabels": ["from-support"],
    "project": { "owner": "Owner", "number": 3 }
  }
}
```

| Key | Required | Default | Description |
|-----|----------|---------|-------------|
| `enabled` | yes | N/A | Set `false` to disable the sync without removing the config |
| `region` | no | `"us"` | Intercom API region: `"us"`, `"eu"`, or `"au"`. Overrides the `INTERCOM_REGION` env var when present. |
| `workspaceId` | yes (Canvas Kit) | N/A | Intercom workspace ID. Used by the Canvas Kit service to resolve which client a submit belongs to. Find it in the Intercom app URL (`app.intercom.com/a/apps/<workspaceId>`). |
| `triageTag` | yes (backstop) | N/A | Intercom tag **ID** (not display name) for the daily backstop poller. Still useful as a secondary signal. Find the ID in the tag URL or via `GET /tags`. |
| `targetRepo` | yes | N/A | GitHub repo in `"Owner/repo"` format |
| `issueLabels` | no | `["from-support"]` | Labels auto-created and applied to every new issue |
| `project` | no | N/A | GH Projects v2 board to add issues to: `{ "owner": "Owner", "number": 3 }`. Resolve the project number from the board URL. |

The `INTERCOM_ADMIN_ID` environment variable is optional. When set, it is included in the internal note payload, which is required by some Intercom account configurations. Store it in Secret Manager alongside the access token if needed.

The Intercom access token is stored in GCP Secret Manager as `intercom-access-token` and is never committed to the repository.

---

## Canvas Kit app setup (out-of-band, one-time per workspace)

1. Create an **Intercom App** in the [Intercom Developer Hub](https://app.intercom.com/a/developer-signup).
2. Enable the **Inbox** canvas type (sidebar).
3. Set **Initialize URL** to `https://<your-cloud-run-url>/initialize` and **Submit URL** to `https://<your-cloud-run-url>/submit`.
4. Copy the app's **client secret** and provide it to the Canvas Kit service as the `INTERCOM_APP_CLIENT_SECRET` environment variable.
5. Install the app to the Intercom workspace.
6. Add `workspaceId` and (optionally) `project` to the client's `client.json#intercomSync` block.

The Canvas Kit server is a self-contained Bun HTTP service. Deploy it to any runtime that can serve HTTP and set the environment variables:
- `INTERCOM_APP_CLIENT_SECRET:` from the Intercom Developer Hub (required).
- `INTERCOM_ACCESS_TOKEN:` the workspace-level OAuth token (required).
- `INTERCOM_ADMIN_ID:` the Intercom admin user ID to assign issues to (optional).
- `GH_TOKEN:` a GitHub PAT for opening issues (required if `gh` CLI is not pre-authenticated).
- `PORT:` optional, defaults to `8080`.

For GCP: build the service Dockerfile, push to Artifact Registry, and deploy via Cloud Run with `min_instance_count = 0` and an LB URL (or direct service URL).

---

## Operating the automation

### Running manually (dry-run, backstop poller)

```bash
INTERCOM_ACCESS_TOKEN=<token> \
bun run intercom-sync --client <slug> --dry-run
```

Prints the conversations that would be promoted to GitHub issues. Mutates nothing.

### Canvas Kit in production

The Canvas Kit server is a standalone Bun HTTP service that responds to Intercom button clicks in real time. It is not deployed as part of this framework's infra; each customer self-hosts it on their own GCP project (or any other runtime). See the setup steps above for environment variables and the Dockerfile.

### Self-hosted backstop poller (optional)

The monorepo does not run a central backstop cron. Customers who want a server-side safety net can self-deploy one using the same script:

```bash
# Dry-run to preview what would be synced:
INTERCOM_ACCESS_TOKEN=<token> \
GH_TOKEN=<pat> \
bun run intercom-sync --client <slug> --dry-run

# Live run:
INTERCOM_ACCESS_TOKEN=<token> \
GH_TOKEN=<pat> \
bun run intercom-sync --client <slug>
```

To automate it, create a Cloud Build trigger in your own GCP project that runs the script above, schedule it with Cloud Scheduler (daily is a safe default), and store `intercom-access-token` in your Secret Manager. See the setup steps in the Canvas Kit section for environment variable requirements.

The idempotency check on `github_issue_url` means it is safe to run repeatedly; conversations already filed (either via Canvas Kit or a previous cron run) are silently skipped.

---

## Adapting to other platforms

The adapter contract is minimal:

1. **List triaged conversations** (those with the triage tag and without the synced attribute set).
2. **Create a GitHub issue** with a link to the conversation.
3. **Mark the conversation synced** (set an attribute or move it to a "synced" folder/status).
4. **Add a back-link** (internal note or comment) in the conversation.

To support a new platform, implement the same customer-service client interface
and wire it into the sync command. The orchestrator should stay
platform-agnostic. The Canvas Kit service can be adapted by replacing the
Intercom-specific parsing with the new platform's webhook format.

---

## Open questions and follow-ups

- **Bidirectional status sync:** when an issue is closed in GitHub, add a note in the support conversation and/or change its state.
- **Webhook-driven backstop:** replace the daily poll with an Intercom Workflow "Send webhook" triggered by the triage tag; fires within seconds rather than waiting for the next daily run. Lower priority now that Canvas Kit covers the primary real-time path.
- **Multi-platform expansion:** Zendesk and Front follow the same adapter contract; they only need a new `*-api.ts` client and (optionally) a platform-specific Canvas Kit equivalent.
- **Auto-summarization:** summarize the conversation's first message as the issue title when no subject is set; could use an LLM call.
- **Assignee resolution:** resolve the GitHub assignee from `client.json#contributors` when a matching contributor exists.
