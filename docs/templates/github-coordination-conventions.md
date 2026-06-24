---
canonical: true
canonical-id: template-github-coordination-conventions
canonical-version: 2026-06-24
description: GitHub branch, PR, and issue coordination conventions
---

# GitHub coordination conventions

## Reference

- [Issue gate guide](bet-gate-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [Adoption checklist](adoption-checklist.md)

## Purpose

This document defines how GitHub resources map to Shaped Kanban concepts. Issues, Projects, PRs, branches, and labels are the coordination layer. GitHub Issues are the source of truth for all planned work. Pipeline state lives in the GitHub Project board.

## Issue templates

Install the issue template from `.github/ISSUE_TEMPLATE/` before the first shaped issue:

- `shaped-issue.yml`: the shaped issue form; body structure defined by the canonical template at `docs/templates/shaped-issue-template.md` (regenerate with `bun run packages/scripts/src/pull-shaped-issue-template.ts`)

## Issues

### Native issue type (Bug/Feature/Task)

Every GitHub Issue in the Shaped Kanban process carries one of the three native
org-level issue types:

| Type        | When to use                                                                                   |
| ----------- | --------------------------------------------------------------------------------------------- |
| **Bug**     | Existing behavior is broken or not working as intended                                        |
| **Feature** | New user- or business-facing capability or enhancement                                        |
| **Task**    | Maintenance, refactor, docs, or infrastructure work that is neither a capability nor a defect |

The AI classifies the type from the issue content and sets it automatically
during `/create-issue`, `/shape`, and `/triage` via:

```bash
bun run packages/scripts/src/set-issue-type.ts --ref <issue-url> --type <Bug|Feature|Task>
```

**Org requirement.** Native issue types are org-level resources. The repository
must be owned by a GitHub organization that has the three default types (Bug,
Feature, Task) enabled under
`https://github.com/organizations/<org>/settings/issue-types`. User-owned
repositories cannot use native issue types. When types are unavailable the
script exits with a clear message and the rest of the workflow continues.

### Issues (shaped issues)

Each shaped issue gets one GitHub Issue (created via `/shape` using the `shaped-issue.yml` template):

- **Title:** the issue title (e.g. "Onboarding rework")
- **Body:** structured content: problem, appetite, solution sketch, rabbit holes, no-gos
- **Project fields:** `Status` (pipeline column), `Appetite` (Number 1–5), `Start date` (date), `End date` (date), `Severity`

### Issue types by project state

| Status column | Shaped Kanban stage                                |
| ------------- | -------------------------------------------------- |
| `Triage`      | Captured but not yet classified                    |
| `Ready to be shaped` | Unprioritized backlog                       |
| `Being shaped`       | Shaping in progress                         |
| `Shaped`             | Shape done; awaiting issue-gate proposal    |
| `Ready to work`      | Approved; queued for work                   |
| `In progress`        | Active issue in development                 |
| `In review`          | In PR review                                |
| `Merged`      | Merged to main; pending release                    |
| `Shipped`     | Released                                           |
| `Canceled`           | Stopped before release; covers issue-gate rejection and circuit-breaker cancellation |

Ops-track issues use the same Status column. Use `Severity` (`SEV1`–`SEV4`) to flag incident priority.

### Labels

Issue labels have exactly one purpose: **promoting an issue to the top of the queue**. Every other state dimension (Priority, Severity, Appetite, Effort, Impact, Focused, Status) lives in Project board fields; labels that duplicate those dimensions are noise.

Two canonical issue-promotion labels are defined:

| Label          | Color     | When to use                                                                                               |
| -------------- | --------- | --------------------------------------------------------------------------------------------------------- |
| `revenue-path` | `#0075CA` | Issue has high revenue potential. **Always provisioned** on every repo.                                   |
| `pilot-gate`   | `#E4E669` | Issue blocks pilot-readiness. **Optional**. Provision only when the project has active pilot commitments. |

An issue carrying either label floats to the **top of the queue** ahead of all Priority tiers. This is enforced in two places:

1. **`rank-roadmap.ts`** bakes promotion into the `Priority rank` column on the next re-rank run.
2. **`/whats-next`** reads the `Labels` CSV column at display time (belt-and-suspenders, covering the window between a label being applied and the next re-rank).

**Keep-set (never pruned):** `revenue-path`, `pilot-gate`, `risk:high`, `risk:low`. The `risk:high` / `risk:low` labels are owned by the per-repo PR risk-tagging workflow (`pr-risk-label.yml`, rendered into client repos by `render-pr-risk-protection.ts`) and must not be removed from the repo's label list.

**Provision and prune** with:

```bash
# Always provisions revenue-path; prunes every other label not in the keep-set
bun run packages/scripts/src/create-github-labels.ts --repo <owner/repo>

# Also provisions pilot-gate (for active pilot projects)
bun run packages/scripts/src/create-github-labels.ts --repo <owner/repo> --with-pilot-gate

# Dry-run: print the gh commands without executing them
bun run packages/scripts/src/create-github-labels.ts --repo <owner/repo> [--with-pilot-gate] --dry-run
```

## Projects

One permanent GitHub Project for the team. Recommended title: `Shaped Kanban`.

Columns map to pipeline stages: `Triage`, `Ready to be shaped`, `Being shaped`, `Shaped`, `Ready to work`, `In progress`, `In review`, `Merged`, `Shipped`, `Canceled`.

Use four canonical Project views:

| View | Layout | Status visibility |
| ---- | ------ | ----------------- |
| `Contributors` | Board | Hide `Triage`, `Ready to be shaped`, `Being shaped`, `Shaped`, and `Canceled` |
| `Leadership` | Board | Show all Status columns |
| `Roadmap` | Timeline | Show all Status columns |
| `All issues` | Table/list | Show all Status columns |

The provisioning script prints the manual steps for this view setup because GitHub's current public Project APIs do not expose reliable mutations for view ordering or hidden board columns.

Project fields provisioned by `bun run packages/scripts/src/provision-github-project.ts`:

| Field        | Type          | Options                        | Purpose                                                                                                                        |
| ------------ | ------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
| `Appetite`   | Number        | 1–5                            | Issue appetite in business days; used for end-date burn calculation                                                            |
| `Start date` | Date          | N/A                            | Set by `/start-issue` when the issue is pulled into `In progress`                                                              |
| `End date`   | Date          | N/A                            | `addBusinessDays(Start date, appetite)`; set by `/start-issue` alongside `Start date`; roadmap endpoint and appetite hard stop |
| `Severity`   | Single select | `SEV1`, `SEV2`, `SEV3`, `SEV4` | Incident priority for ops-track issues                                                                                         |
| `Priority`   | Single select | `P0`, `P1`, `P2`, `P3`, `P4`   | Scheduling priority set by `/triage`; P0 = act now, P4 = lowest weight                                                         |
| `Focused`    | Single select | `Yes`, `No`                    | Per-assignee focus flag; the one item each assignee is actively working. Operator-set, default No; at most one per assignee    |
| `Effort`     | Single select | `Low`, `Medium`, `High`        | Effort estimate set by `/triage`; maps to CSV `Effort (1-4)` values 1–3                                                        |
| `Impact`     | Single select | `Low`, `Medium`, `High`        | Impact estimate set by `/triage`; maps to CSV `Impact (1-4)` values 1–3                                                        |

Add all issues to the Project. The board is self-describing: every state dimension is visible in the project view. Prune or archive completed items as the project grows.

### WIP limits

Three columns are WIP-limited; counts are read from the live board by `bun packages/scripts/src/wip-check.ts`:

| Column   | Limit | Rationale                                         |
| -------- | ----- | ------------------------------------------------- |
| `Being shaped` | 3     | Agent workstreams shape in parallel.              |
| `In progress`  | 3     | Agent workstreams build in parallel.              |
| `In review`    | 2     | Human review/verification is the scarce resource. |

`In review` is the primary flow control point. When it is full, the correct action is to complete or skip a review, not to raise the limit. See [WIP limits policy](wip-limits-policy.md) for override rules and team-size scaling.

## Branches

| Convention                                  | Use                                                               |
| ------------------------------------------- | ----------------------------------------------------------------- |
| `<handle>/<issue-slug>-<short-description>` | Per-scope work branch. Maximum lifetime: 2 days. Primary pattern. |
| `<handle>/ops-<short-description>`          | Ops-track item (tech debt, reactive fix, or ops work).            |

Branch rules:

- Scope branches must merge to `main` within 2 days. If a branch lives longer, the change is too large; split it.
- All code implementing a scope is gated behind the issue's feature flag (or a scope-level child flag). Default: off in every environment except local dev.
- Feature flag naming convention: `issue_<issue-slug>` for the issue root, `issue_<issue-slug>__<scope-slug>` for a scope-level child flag.
- Long-lived issue branches are not allowed. Every scope goes directly to `main` behind a flag.

## Pull requests

- Link every scope PR to its parent issue: include `Part of #<issue-number>` in the PR body.
- One PR addresses one scope (as tracked in the issue body task list). If a single PR covers more than one scope, the scopes were sliced too fine.
- **Title formatting:** PR titles follow the same backtick rules as descriptions, wrapping file names, route paths, package names, and `camelCase`/`PascalCase` code identifiers (API type names, component names, function names) in backticks (e.g., ``Fix `schema.sql` migration``, `` Refactor `OnboardingForm` ``, ``Add `PaymentIntent` retry logic``). See `/pr` and `/update-pr` for the full convention.
- **Public copy:** PR titles, descriptions, comments, and issue text must not include internal repo provenance wording. Describe the customer-visible change directly.

## Reference

- [Issue gate guide](bet-gate-guide.md)
- [In-flow workflow guide](in-flow-workflow-guide.md)
- [Adoption checklist](adoption-checklist.md)
