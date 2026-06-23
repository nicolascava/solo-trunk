---
canonical: true
canonical-id: template-sred-tracking
canonical-version: 2026-05-07
description: SR&ED time and activity tracking template
---

# SR&ED/RS&DE tracking

## Reference

- [CSV state store](csv-state-store.md)
- [SR&ED narrative template](sred-narrative.md)

## Purpose

SR&ED (Scientific Research and Experimental Development) is a Canadian federal tax incentive program administered by the CRA. Quebec runs a parallel program (RS&DE) administered by Revenu Québec. Both programs reduce the after-tax cost of eligible R&D work performed in Canada.

This document defines the canonical process, document layout, CSV schemas, filing calendar, and evidence rules for preparing and submitting an SR&ED/RS&DE claim. It is the reference for the `/sred` skill and for any agent or human touching SR&ED artifacts.

All per-client data (business numbers, salaries, employee names) is sensitive and lives in the per-client sensitive repository. Only the template and skill live in the public monorepo.

## Jurisdictions

| Jurisdiction | Form | Administrator | Due date |
|---|---|---|---|
| Federal (CRA) | T661 | Canada Revenue Agency | 18 months after fiscal year end |
| Quebec (RQ) | RD-1029.7 | Revenu Québec | 12 months after fiscal year end |

The `/sred` skill targets both by default. A client may be federal-only if they have no Quebec establishment. Set `jurisdictions` in `client.json` to `["cra"]` to skip RQ.

## Folder layout (per-client, sensitive repo)

```
<sensitive-repo-root>/customers/<slug>/sred/<fiscal-year>/
  projects.csv              # one row per SR&ED project
  personnel.csv             # one row per (project, employee) allocation
  evidence.csv              # one row per linked artifact
  projects/<project-slug>.md  # narrative per project (copy of sred-narrative.md)
  README.md                 # filing checklist for the fiscal year
```

Bootstrap with: `bun packages/scripts/bootstrap-sred-claim.ts --client <slug> --fiscal-year <YYYY> --sensitive-root <path>`

## CSV schemas

### `projects.csv`

One row per SR&ED project for the fiscal year. Written by `packages/scripts/append-sred-project.ts`.

| Column | Type | Description |
|---|---|---|
| `id` | string | Unique identifier (UUID or slug) |
| `project_slug` | string | Kebab-case project identifier |
| `title` | string | Human-readable project title |
| `project_start_date` | ISO 8601 date | When SR&ED work began |
| `project_end_date` | ISO 8601 date | When SR&ED work ended (or fiscal year end) |
| `jurisdictions` | string | Comma-separated: `cra`, `rq`, or both |
| `uncertainty_summary` | string | One-sentence summary of the technological uncertainty |
| `advancement_summary` | string | One-sentence summary of the technological advancement sought |
| `status` | string | `drafting`, `ready-for-consultant`, `submitted`, `accepted`, or `rejected` |

### `personnel.csv`

One row per (project, employee) allocation. Written by `packages/scripts/append-sred-personnel.ts`.

| Column | Type | Description |
|---|---|---|
| `id` | string | Unique identifier |
| `project_slug` | string | References `projects.csv` |
| `person_name` | string | Full name |
| `role` | string | Job title or function during SR&ED work |
| `province` | string | Province of work (e.g. `QC`, `ON`) |
| `allocation_pct` | number | Percentage of time spent on SR&ED (0–100) |
| `salary_cad` | number | Annual salary in CAD |
| `is_subcontractor` | boolean | `true` if an arm's-length contractor |
| `notes` | string | Free-text notes |

### `evidence.csv`

One row per linked artifact. Written by `packages/scripts/append-sred-evidence.ts`. Seeded from `git` history by `packages/scripts/aggregate-sred-evidence.ts`.

| Column | Type | Description |
|---|---|---|
| `id` | string | Unique identifier (often the commit hash or artifact ID) |
| `project_slug` | string | References `projects.csv` |
| `kind` | string | `commit`, `pull_request`, `issue`, `plan`, `doc`, `test_report`, or `meeting_note` |
| `ref` | string | Canonical reference (commit hash, URL, filename) |
| `title` | string | Human-readable description of the artifact |
| `occurred_at` | ISO 8601 date | When the work happened |
| `notes` | string | Optional additional context |

## Filing calendar

| Event | CRA | RQ |
|---|---|---|
| Fiscal year end | N/A | N/A |
| Claim due | +18 months | +12 months |
| Internal draft ready | +9 months | +6 months |
| Consultant review | +12 months | +9 months |

Work backwards from the fiscal year end date to set internal milestones. Most consultants need 4–8 weeks for final review.

## Eligibility checklist

Work is eligible if it meets **all three** of the CRA's criteria:

1. **Technological uncertainty:** You could not determine the outcome by applying standard practice or existing knowledge. The uncertainty was scientific or technological in nature, not commercial or business risk.
2. **Systematic investigation:** You followed a structured process: hypothesis → experiment → analysis → conclusion. Informal tinkering or trial-and-error without documentation does not qualify.
3. **Technological advancement:** You sought to advance general scientific or technological knowledge (not just solve your own problem). The advancement need not succeed; negative results qualify if the investigation was systematic.

Work that does not qualify:

- Routine software maintenance and bug fixes
- UI/UX changes and cosmetic redesigns
- Standard integration of existing libraries or APIs (unless integration itself posed a technological uncertainty)
- Market research, business analysis, or feasibility studies
- Style or brand work

## Evidence rules

Evidence documents that SR&ED work happened during the claim period. More is better; contemporaneous evidence (created at the time of the work) carries the most weight.

| Kind | Good evidence | Notes |
|---|---|---|
| `commit` | Git commits with descriptive messages | Mined automatically by `aggregate-sred-evidence.ts` |
| `pull_request` | PRs that describe a hypothesis, test, or finding | Link to the PR; include description |
| `issue` | GitHub Issues that frame a technical problem or shaped design | Include title and URL |
| `doc` | Architecture decisions, ADRs, design docs | Include filename or URL |
| `test_report` | Test suite output, performance benchmarks | Include date and key metrics |
| `meeting_note` | Meeting notes referencing SR&ED experiments | Include date and attendees |

Rules:
- Evidence must fall within the project's `project_start_date` and `project_end_date`.
- Each `project_slug` in `evidence.csv` must match a row in `projects.csv`.
- At minimum, have evidence from at least two different `kind` values per project.
- Keep raw evidence (commit logs, test reports) accessible in the repo or the sensitive repo for CRA review.

## Anti-patterns

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| Claiming all engineering time | CRA audits allocation percentages against contemporaneous records | Track allocation per project in `personnel.csv`; be conservative |
| Vague uncertainty statements | "We didn't know if it would work" is not a technological uncertainty | Name the specific scientific or engineering unknown |
| No contemporaneous evidence | Evidence created during an audit carries less weight | Commit notes, plans, and test reports as you work |
| Mixing business risk with technical uncertainty | "We weren't sure customers would like it" is not SR&ED | Separate product uncertainty from technical uncertainty |
| Submitting the same project across two fiscal years | Each claim is fiscal-year-specific | Split work by fiscal year; document cross-year projects clearly |
| Missing RQ deadline | RQ deadline (12 months) is earlier than CRA (18 months) | Set a calendar reminder at fiscal year end |

## Reference

- CRA T661 form: https://www.canada.ca/en/revenue-agency/services/forms-publications/forms/t661.html
- RQ RD-1029.7: https://www.revenuquebec.ca/en/businesses/tax-credits/scientific-research-and-experimental-development/
- [CSV state store](csv-state-store.md)
- [SR&ED narrative template](sred-narrative.md)
