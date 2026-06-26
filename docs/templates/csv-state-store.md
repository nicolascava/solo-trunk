---
canonical: true
canonical-id: template-csv-state-store
canonical-version: 2026-06-26
description: CSV as lightweight state store for tasks, issue mirrors, and SR&ED
---

# CSV state store

## Reference

- [GitHub coordination conventions](github-coordination-conventions.md)
- [Adoption checklist](adoption-checklist.md)

## Purpose

Pipeline state (issues, scopes, appetite) lives in GitHub Issues and the GitHub Project board, not in hand-edited CSV files. CSV files remain in use for three specific purposes: the lightweight operational task inbox (`tasks.csv`), generated GitHub Project issue mirrors (`issues.csv`) for teams whose configuration declares `"issuesSourceOfTruth": "github-issues"`, and client-approved SR&ED claim artifacts.

This document defines those CSVs: column schemas, the scripts that read and write them, and the rules for hand-editing.

## Why CSV (for tasks, mirrors, and SR&ED)

- Diffs are readable in pull requests
- Any agent or script can parse a CSV without a database
- No external service required
- Schema changes are explicit: add a column, run a migration script

## File map

| File | Purpose |
|------|---------|
| `tasks.csv` | Ad hoc task inbox outside the Shaped Kanban pipeline. |
| `deferred-findings.csv` | Code-review findings deferred from `/pre-merge` for follow-up tracking. |
| `cycles.csv` | Shape Up cycle calendar, retired. Kept for historical reference only. |
| `support-rotation.csv` | Weekly support rotation roster: primary and backup on-duty engineer per week. Source of truth for generating `support-rotation.ics`. |
| `issues.csv` | Generated GitHub Project issue mirror for clients whose configuration declares `"issuesSourceOfTruth": "github-issues"`. |

## Schemas

### `tasks.csv`

General-purpose task inbox for ad hoc work outside the Shaped Kanban pipeline.

Header: `id,list,description,completed,completedAt,appetite,reminder,appleReminderId`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Unique identifier |
| `list` | string | Named list (e.g. `inbox`, `weekly`) |
| `description` | string | Task description |
| `completed` | boolean | `true` when done |
| `completedAt` | ISO 8601 datetime | When the task was completed |
| `appetite` | string | Optional time box for the task |
| `reminder` | ISO 8601 date | Optional reminder date |
| `appleReminderId` | string | Linked Apple Reminders identifier (optional) |

### `deferred-findings.csv`

Code-review findings deferred from `/pre-merge` that are not fixed in the source PR. Persisted across branch deletion for follow-up tracking. Written by `add-deferred-finding.ts`.

Header: `id,date,branch,phase,severity,file,description,status,resolvedAt,resolvedBranch`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Unique identifier |
| `date` | ISO 8601 datetime | When the finding was deferred |
| `branch` | string | Source branch where the finding was identified |
| `phase` | integer | Review phase that surfaced it (1, 2, or 3) |
| `severity` | string | `critical`, `major`, `minor`, or `nitpick` |
| `file` | string | `path/to/file.ts:line` citation |
| `description` | string | One-line finding summary |
| `status` | string | `open` or `resolved` |
| `resolvedAt` | ISO 8601 datetime | When the finding was resolved (optional) |
| `resolvedBranch` | string | Branch that resolved the finding (optional) |

## RFC-4180 rules

All CSV reading and writing must use a real RFC-4180 parser and serializer.
Never hand-roll CSV parsing or serialization.

Hand-edit rules:
- Quote fields that contain commas or newlines
- Use `""` to escape a literal quote inside a quoted field
- Append-only state CSVs (`tasks.csv`, `deferred-findings.csv`) **must** end with exactly one trailing newline: the `merge=union` driver depends on it (see Merge strategy below). The append scripts enforce this; do not strip the trailing newline when hand-editing.

## Merge strategy

`tasks.csv` and `deferred-findings.csv` are marked `merge=union` in `.gitattributes`. Git's built-in union driver keeps rows from both sides of a merge instead of conflicting on the tail-appended hunk, eliminating the recurring PR conflicts that result from every branch appending rows at end-of-file.

Two invariants must hold for clean union merges:

1. **Trailing newline**: each file must end with exactly one `\n`. The append scripts (`add-task.ts`, `add-deferred-finding.ts`) enforce this automatically.
2. **Unique row ids**: `id` (column 0) must be unique across all rows. The union driver silently keeps both copies when two branches edit the same row, so a collision becomes a duplicate rather than a conflict. The repository test suite must assert uniqueness on every test run.

**Residual risk:** if two branches concurrently edit the same existing row (e.g. both flip `completed` on the same task), union keeps both versions silently. The guard test catches this after the fact (pre-push). Schema migrations via `add-csv-column.ts` rewrite the whole file and should be standalone PRs merged before or after other CSV-touching branches. The union driver also has no awareness of RFC-4180 quoting: a field value containing an embedded newline (a valid quoted multi-line field) would be split across physical lines during a merge and produce a corrupt row. The append scripts never write embedded newlines to these files; do not hand-edit union-merged CSVs with multi-line field values.

## Schema migrations

To add a column to an existing CSV, use a migration script or a focused manual
change that updates every row consistently. Never add columns by editing only
the header row.

## GitHub Project issue mirrors

For GitHub-backed clients, `issues.csv` is a generated local mirror of the
configured GitHub Project, not the primary planning surface. A client opts into
this mirror only when its configuration includes all of:

- `"issuesSourceOfTruth": "github-issues"`
- `coordinationRepo`
- `githubProjectNumber`

The daily local sync rewrites those mirrors from GitHub. The mirror preserves
local-only columns such as `Plan`, `Plan link`, `Dependencies`, and `Notes` for
matched GitHub issue rows, but GitHub-owned metadata columns are
source-of-truth from the Project. Rows no longer present in the Project are
removed on the next backup.

Do not hand-edit GitHub-owned columns in these mirrors. Make issue, state,
assignee, label, appetite, and due-date changes in GitHub. Local notes and plan
links may be edited in the CSV when needed, but only on rows that already have a
GitHub issue URL.

## SR&ED CSVs

SR&ED artifacts can contain employee names, salaries, business numbers, and claim evidence.
Store them in the client-approved claim repository. Public monorepos are disallowed unless the
repository root is explicitly marked self-sensitive with `sensitive-root.json` containing
`{ "mode": "self" }`. In this monorepo, that marker approves
`docs/customers/<slug>/sred/<fiscal-year>/` unless `client.json` declares a separate
`sensitiveRepo.root`.

Location: `<claim-root>/customers/<slug>/sred/<fiscal-year>/`

| File | Purpose |
|------|---------|
| `projects.csv` | One row per SR&ED project. Columns: `id`, `project_slug`, `title`, `project_start_date`, `project_end_date`, `jurisdictions`, `uncertainty_summary`, `advancement_summary`, `status` |
| `personnel.csv` | One row per (project, employee) allocation. Columns: `id`, `project_slug`, `person_name`, `role`, `province`, `allocation_pct`, `salary_cad`, `is_subcontractor`, `notes` |
| `evidence.csv` | One row per linked artifact (commit, PR, issue, etc.). Columns: `id`, `project_slug`, `kind`, `ref`, `title`, `occurred_at`, `notes` |

Always write SR&ED CSVs in the approved claim location for the relevant client and fiscal year.

See [SR&ED tracking](sred-tracking.md) for filing calendar, eligibility checklist, and evidence rules.

## Reference

- [GitHub coordination conventions](github-coordination-conventions.md)
- [Agent skill map](agent-skill-map.md)
- [Adoption checklist](adoption-checklist.md)
- [SR&ED tracking](sred-tracking.md)
