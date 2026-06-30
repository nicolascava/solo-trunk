---
canonical: true
canonical-id: template-multi-surface-intake-guide
canonical-version: 2026-06-30
description: Multi-surface intake guide for non-technical shapers
---

# Multi-surface intake guide

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [Canonical doc sync](canonical-doc-sync.md)
- [Adoption checklist](adoption-checklist.md)
- [Agent skill map](agent-skill-map.md)

## Purpose

Non-technical shapers (PMs, product owners, founders without a CLI workflow) should be able to submit roadmap items and shaped issues from the tools they already use. This guide defines how six external intake surfaces (two per tool stack) feed rows into the client's external roadmap (Google Sheets, Notion DB, or Excel) and draft GitHub Issues for shaped content.

The shaper drafts in their tool of choice. A sync job imports the draft into the external roadmap and optionally creates or updates a GitHub Issue. The issue gate sign-off, and all subsequent state transitions, remain in GitHub Issues and the GitHub Project.

## Two principles

**External roadmap + GitHub Issues is the source of truth.** External intake surfaces are write-only funnels. They are never updated from the external roadmap or GitHub Issues. If a shaper wants to see current pipeline state, they view the GitHub Project board or the synced view that `sync-customer-docs.ts` pushes to their tool (see [Canonical doc sync](canonical-doc-sync.md)). Editing that synced view has no effect on the source.

**External surfaces are write-only funnels.** A row or document becomes canonical only after the relevant adapter script imports it into the external roadmap (and optionally creates a GitHub Issue). Until then it is a draft. Each adapter is idempotent: rows or documents already marked `Synced` are skipped on every subsequent run.

## Per-client routing

> **Editing client.json:** edit `docs/customers/<slug>/client.json` directly and commit the change.

Set `intakeSync` in the client's `client.json` to activate intake sync:

```jsonc
{
  "intakeSync": {
    "enabled": true,
    "spreadsheet": {
      "platform": "google-sheets",        // or "notion" or "excel"
      "intakeRange": "Intake!A2:Z"         // Google Sheets only; Notion uses DB filter; Excel uses sheet name
    },
    "documents": {
      "platform": "google-docs",          // or "notion" or "word"
      "draftFolderId": "<folder-id>"      // Drive folder ID, Notion parent page ID, or OneDrive folder path
    }
  }
}
```

When `enabled` is `false` (the default), the adapter scripts are a no-op for that client. Clients with `roadmapSensitiveSource` set are skipped by public CI; their intake runs in sensitive-repo CI.

| Client tool stack | `spreadsheet.platform` | `documents.platform` |
|---|---|---|
| Google Workspace | `google-sheets` | `google-docs` |
| Notion | `notion` | `notion` |
| Microsoft 365 | `excel` | `word` |

## Adapter contract

Each adapter is an independent script (e.g., `intake-from-gsheets.ts`). The script must:

1. Print `[imported] <description>` to stdout for each successfully imported item.
2. Print `Done: X imported, Y skipped, Z errors` as the final stdout line.
3. Print errors to stderr.
4. Exit non-zero on any unrecoverable error.

This contract lets the orchestrator collect per-item lines for the PR body (by grepping for `[imported]`) without knowing platform-specific details.

## Idempotency rules

| Surface | Mark-synced strategy |
|---------|----------------------|
| Google Sheet | Append a `Synced` boolean column; set `TRUE` after import |
| Notion DB | Toggle a `Synced` checkbox property on the row |
| Excel | Same as Google Sheet; `Synced` column |
| Google Doc | Move file into `<draftFolderId>/synced/` subfolder |
| Notion page | Add `synced` tag to the page |
| Word doc | Move file into `<draftFolderId>/synced/` subfolder |

Adapters skip rows already marked `Synced=TRUE` and documents already in the `synced/` subfolder (or tagged `synced`).

Backfill: items that existed in a client's tool before `intakeSync.enabled` flipped on must be manually marked `Synced` to avoid re-import on the first run.

## Error handling and shaper feedback loop

When a row or document fails validation:

1. The adapter records the error but does not mark the item `Synced`.
2. For spreadsheet rows: the error message is written to stderr; the row stays unsynced.
3. For documents: the adapter posts a comment on the source document (Google Docs inline comment, Notion page comment, or a companion `<original-name>.errors.md` file for Word).
4. The item remains in its draft location until the shaper fixes it and the next sync run picks it up.
5. Review stderr output, draft a message to the shaper via the client's `communicationChannels.primary` channel, and follow up as needed.

Fix the source document, not the external roadmap or GitHub Issues directly. The source document is the authoritative draft until it passes validation and is imported by the sync job.

## Anti-patterns

| Anti-pattern | What to do instead |
|---|---|
| Editing the external roadmap or GitHub Issues directly to bypass intake sync | Fix the source row or document; let the next sync re-import it |
| Using intake sync as bidirectional sync | Intake is one-way (external surface → external roadmap/GitHub Issues). The outbound path is `sync-customer-docs.ts` |
| Enabling intake sync without configuring `communicationChannels` | Error messages go to the shaper via the primary channel; configure `communicationChannels.primary` in `client.json` first |
| Marking items `Synced` manually to skip them | Only do this for pre-existing items before first sync, never to skip validation |
| Running the adapter without a dry-run first | Run with `--dry-run` on a single test row before processing all rows |

---

## Spreadsheet platform specs

### Google Sheets

**Required columns** (headers must match exactly):

| Column | Type | Notes |
|---|---|---|
| Title | string | Problem or capability name |
| Type | string | `feature`, `bug`, `chore`, `ops` |
| Category | string | Client-defined category |
| Slice | string | Release slice name |
| Service Class | string | `standard`, `fixed-date`, `expedite` (defaults to `standard`) |
| Appetite | string | `1 business day` … `5 business days` (optional for backlog rows) |
| Notes | string | Free text; source URL prepended by adapter |
| Source | string | URL of originating conversation or document |
| Synced | boolean | Set to `TRUE` by the adapter after import |

**Copy-paste header row** (paste into cell A1 of a sheet named `Intake`):

```
Title	Type	Category	Slice	Service Class	Appetite	Notes	Source	Synced
```

Set `intakeSync.spreadsheet.intakeRange` in `client.json` to `Intake!A2:Z` to skip the header row.

### Notion DB

**Required properties** (Notion property names must match exactly):

| Property | Notion type | Notes |
|---|---|---|
| Title | Title | Problem or capability name |
| Type | Select | Options: `feature`, `bug`, `chore`, `ops` |
| Category | Select | Client-defined category |
| Slice | Select | Release slice name |
| Service Class | Select | Options: `standard`, `fixed-date`, `expedite` |
| Appetite | Select | Options: `1 business day`, `2 business days`, `3 business days`, `4 business days`, `5 business days` |
| Notes | Rich text | Free text |
| Source | URL | URL of originating item |
| Synced | Checkbox | Unchecked by default; checked by adapter after import |

The adapter filters for rows where `Synced` is unchecked.

### Excel (OneDrive)

Same column schema as Google Sheets. The sheet must be named `Intake`. The `intakeRange` field is unused for Excel; the adapter reads the sheet named `Intake` automatically.

---

## Document platform specs

Each shaped issue document follows the canonical heading structure with these nine `Heading 2` sections in order when populated: **Problem**, **Steps to reproduce** (Bug issues only, immediately after Problem), **Issue size**, **Solution**, **Impacted repos**, **Rabbit holes**, **No-gos**, **Priority rationale**, **Sources**. Optional sections may be omitted when empty or non-applicable. Use `/shape` to produce the current body skeleton. The adapter rejects documents that are missing required sections or that specify an issue size outside the 1–5 business-day range.

Use `Heading 1` for the issue title and `Heading 2` for each section heading. The H1 title is kebab-cased to produce the issue slug. The document must have exactly one H1.

### Google Docs

Apply `Heading 1` to the title line and `Heading 2` to each section title in Format → Paragraph styles before saving the document to the draft folder. H3 headings are treated as subsections within the enclosing H2.

On success the adapter moves the document into `<draftFolderId>/synced/` and creates or updates a GitHub Issue via `gh issue create`. On parse error it posts an inline comment on the document with the error message and leaves the document in place.

### Notion page

Use `heading_1` for the issue title and `heading_2` for each section. The page title (not the first heading block) becomes the issue slug. Nested blocks under a `bulleted_list_item` are flattened into the item text. On success the adapter adds a `synced` tag to the page and creates or updates a GitHub Issue. On parse error it posts a Notion comment and adds a `parse-error` tag.

### Word (OneDrive)

Use Word's built-in heading styles: **Heading 1** for the issue title, **Heading 2** for each section.

On success the adapter moves the file into the `synced/` subfolder on OneDrive and creates or updates a GitHub Issue. On parse error it writes a companion file named `<original-name>.errors.md` to the same folder with one bullet per error.

---

## Reference

- [Shaped Kanban overview](shaped-kanban-overview.md)
- [Feedback intake guide](feedback-intake-guide.md)
- [Customer-service to GitHub Issues guide](customer-service-to-github-issues-guide.md)
- [Canonical doc sync](canonical-doc-sync.md)
- [Adoption checklist](adoption-checklist.md)
- [Agent skill map](agent-skill-map.md)
