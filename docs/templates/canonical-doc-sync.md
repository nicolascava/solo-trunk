---
canonical: true
canonical-id: template-canonical-doc-sync
canonical-version: 2026-05-13
description: Canonical doc CI sync pipeline guide
---

# Canonical customer doc sync

## Reference

- [`agent-skill-map.md`](agent-skill-map.md): skill matrix, including `/setup-sync-ci`
- [`csv-state-store.md`](csv-state-store.md): CSV schema conventions
- [`multi-surface-intake-guide.md`](multi-surface-intake-guide.md): inbound intake from external surfaces
- [`ci-templates/`](ci-templates/): copy-paste CI snippets per provider

---

## Purpose

When a configured customer's `issues.csv` or plan Markdown files are updated on
`main`, the changes are automatically mirrored to the client's destination
platform:

| Platform | Issues → | Plans → |
|---|---|---|
| Google | Google Sheets | Google Docs |
| Notion | Notion database | Notion pages |
| Microsoft/OneDrive | Excel workbook | PDF on OneDrive |

The CI step routes by reading each client's `client.json`.

The inverse direction (external surface → repo) is handled by the per-platform
adapter configured for the repository. Shapers draft roadmap rows in Google
Sheets, Notion DB, or Excel, and pitch documents in Google Docs, Notion pages,
or Word. Run the appropriate adapter to import those drafts as PRs. See
[Multi-surface intake guide](multi-surface-intake-guide.md) for the full
contract.

---

## Platform routing

The orchestrator resolves the target platform in this order:

1. **Explicit:** `tools.documentation` in `client.json`: `"notion"`, `"google-drive"`.
2. **Heuristic** (when `tools` is absent or null):
   - `microsoft.oneDrive.docsFolderPath` is set → **Microsoft**
   - `notionParentPageId` is set → **Notion**
   - `plansDriveFolderId` or `roadmapSpreadsheetId` is set → **Google**
3. **Error** if none of the above can be inferred.

Microsoft wins over Google when both are configured (e.g., a client with both OneDrive and `plansDriveFolderId`/`roadmapSpreadsheetId` set).

---

## Trigger conditions

| Condition | Description |
|---|---|
| Branch | `main` only |
| Paths | configured customer `issues.csv` or plan Markdown files |
| Sensitive | Slugs with `roadmapSensitiveSource` set are **skipped**; sync must be triggered from the sensitive-repo CI |

---

## Client metadata authoring

`client.json` is the **source of truth** read by all sync scripts. Edit it
directly and commit the change.

---

## Required `client.json` fields

### Google clients (`tools.documentation: "google-drive"`)

| Field | Required | Description |
|---|---|---|
| `roadmapSpreadsheetId` | ✓ | Target spreadsheet ID for roadmap CSV → Google Sheets sync |
| `plansDriveFolderId` | ✓ | Target Drive folder for plan-doc uploads (Docs/PDFs) |
| `googleServiceAccountKeyPath` | ✓ (local) | Path to SA key file (local); in CI use `GOOGLE_SA_KEY` env |
| `roadmapSource` | optional | Override roadmap.csv path |
| `issuesSource[0]` | optional | Override issues directory path |

### Notion clients (`tools.documentation: "notion"`)

| Field | Required | Description |
|---|---|---|
| `notionParentPageId` | ✓ | Parent page under which databases/pages are created |

### Microsoft clients (heuristic: `microsoft.oneDrive.*` set)

| Field | Required | Description |
|---|---|---|
| `microsoft.oneDrive.excelFolderPath` | ✓ | OneDrive path for Excel workbooks |
| `microsoft.oneDrive.docsFolderPath` | ✓ | OneDrive path for PDF documents |
| `microsoft.oneDrive.driveId` | optional | Specific drive ID (omit for personal OneDrive) |
| `opsRepoPath` | ✓ | Local path to the client's ops repo (source of CSV/MD files) |

---

## Secret-management contract

All secrets live in GCP Secret Manager (Cloud Build) or GitHub/GitLab/Bitbucket repo secrets.
**Never** store secrets in `.env` files committed to source control.

| Secret name | Cloud Build resource | GH secret name | Required for |
|---|---|---|---|
| `NOTION_API_KEY` | `secrets/notion-api-key` | `NOTION_API_KEY` | Notion clients |
| `GOOGLE_SA_KEY` | `secrets/google-sa-key` | `GOOGLE_SA_KEY` | Google clients |
| `MICROSOFT_OAUTH_CLIENT_ID` | `secrets/microsoft-oauth-client-id` | `MICROSOFT_OAUTH_CLIENT_ID` | OneDrive clients |
| `MICROSOFT_OAUTH_TENANT_ID` | `secrets/microsoft-oauth-tenant-id` | `MICROSOFT_OAUTH_TENANT_ID` | OneDrive clients |
| `MICROSOFT_OAUTH_REFRESH_TOKEN` | `secrets/microsoft-oauth-refresh-token` | `MICROSOFT_OAUTH_REFRESH_TOKEN` | OneDrive clients |

### One-time Microsoft refresh-token bootstrap

The `MICROSOFT_OAUTH_REFRESH_TOKEN` requires a one-time interactive sign-in to obtain:

Run the repository's Microsoft auth bootstrap locally, sign in when the browser
opens, then copy the printed token and store it in Secret Manager or repo
secrets.

The CI non-interactive path exchanges `MICROSOFT_OAUTH_REFRESH_TOKEN` directly
via the `/oauth2/v2.0/token` endpoint and skips the browser flow entirely.

---

## Tooling

| Action | Command |
|---|---|
| Sync all changed clients (CI mode) | repository doc-sync CI |
| Sync a single client (dry-run) | `/sync-docs <client> --dry-run` |
| Sync roadmap only | `/sync-docs <client> --only roadmap` |
| Bootstrap CI for a new client | `/setup-sync-ci` |
| Local manual sync (developer) | `/sync-docs` |

---

## Rules

- Public CI must never process slugs with `roadmapSensitiveSource` set. Sensitive content syncs from the sensitive-repo CI only.
- The CI step exits non-zero if any individual sync fails, so Cloud Build/GitHub Actions marks the run as failed and notifies the team.
- Each client's failure is isolated: if `lua` sync fails, `fix` and `bgp` still run.
- `GOOGLE_SA_KEY` must be base64-encoded in CI. The build step decodes it before use: `printf '%s' "$GOOGLE_SA_KEY" | base64 -d > /workspace/google-sa.json`.
- Do not add the internal roadmap CSV as a trigger path; it is explicitly excluded from syncing.

---

## Reference

- [`agent-skill-map.md`](agent-skill-map.md): skill matrix, including `/setup-sync-ci`
- [`csv-state-store.md`](csv-state-store.md): CSV schema conventions
- [`multi-surface-intake-guide.md`](multi-surface-intake-guide.md): inbound intake from external surfaces
- [`ci-templates/`](ci-templates/): copy-paste CI snippets per provider
