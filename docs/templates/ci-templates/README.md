# CI Templates

## CI checks (lint · style · type · test)

Use `/setup-ci` to auto-detect the customer's CI backend and scaffold the right template.

| CI Backend | Template | Trigger | Backend selection rule |
|---|---|---|---|
| Google Cloud Build | `cloudbuild-checks-snippet.yaml` | Cloud Build trigger (Terraform) | `client.json` has `gcpProject` |
| GitHub Actions | `github-actions-checks.yml` | `pull_request` + `merge_group` | GitHub remote, no GCP project |

Both templates run four independent parallel jobs: **lint**, **style**, **type**, and **test**. The `/setup-ci` skill auto-detects the customer repo's package manager and emits PM-correct run commands — `pnpm lint`, `npm run lint`, `yarn lint`, or `bun run lint` as appropriate. Lines marked `# SWAP:` in the canonical templates document remaining variation points (e.g., image versions, turbo config) but are no longer the primary adaptation mechanism for package manager choice.

> **Auto-generation:** `/setup-ci` detects the customer's package manager and
> emits the correct checks file automatically. The `# SWAP:` markers in the
> canonical templates are inline documentation of variation points, not the
> adaptation mechanism.

Validate the templates with the repository's CI-template tests after copying to
confirm structural integrity.

---

## CI templates for Customer Doc Sync

Copy the snippet matching your CI provider into the client's repo CI config.
Replace `<SLUG>` with the client's monorepo slug (e.g., `bgp`, `lua`, `fix`).

| CI Provider | Template | Trigger | Secrets |
|---|---|---|---|
| Cloud Build | `cloudbuild-sync-customers.yaml` | Terraform trigger — paths filter | GCP Secret Manager |
| GitLab CI | `gitlab-ci-snippet.yml` | `rules: changes` | GitLab masked CI/CD variables |
| Bitbucket Pipelines | `bitbucket-pipelines-snippet.yml` | `condition.changesets.includePaths` | Secured repo variables |
| Any (shell) | `generic-shell.sh` | Your CI's hook | Export env vars before running |

## Required secrets (all providers)

| Secret name | Description |
|---|---|
| `NOTION_API_KEY` | Notion integration token (required for Notion clients) |
| `GOOGLE_SA_KEY` | Base64-encoded Google service-account JSON (required for Google clients) |
| `MICROSOFT_OAUTH_CLIENT_ID` | Azure app client ID (required for OneDrive clients) |
| `MICROSOFT_OAUTH_TENANT_ID` | Azure tenant ID — defaults to `common` |
| `MICROSOFT_OAUTH_REFRESH_TOKEN` | Non-interactive refresh token — obtain once locally with the repository's Microsoft auth bootstrap |

## Canonical spec

Full routing rules, required `client.json` fields, and secret-management contract:
`canonical-doc-sync.md`
