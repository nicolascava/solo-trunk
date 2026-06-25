---
canonical: true
canonical-id: template-solo-trunk-workflow-guide
canonical-version: 2026-06-14
description: Direct-to-main integration for solo-developer repositories
---

# Solo-trunk workflow guide

## Applicability

This workflow is for **solo-developer businesses only**. A repository opts in by
placing `git-workflow.json` at the root with the following content:

```json
{ "workflow": "solo-trunk" }
```

The PR-based workflow (the default for all repositories) is described in
`https://github.com/nicolascava/solo-trunk/blob/main/docs/templates/in-flow-workflow-guide.md` and
`https://github.com/nicolascava/solo-trunk/blob/main/docs/templates/github-coordination-conventions.md`. Use this guide only when
your repository declares `"workflow": "solo-trunk"`.

## Principles

1. **Trunk is always deployable.** Every commit to `main` must be safe to
   deploy. Never push a known-broken commit.
2. **No pull requests as the integration mechanism.** Changes land directly on
   `main`. There is no review-and-merge step.
3. **CI on `main` gates production deploys.** The `Checks` workflow runs on
   every push to `main`. The deploy pipeline fires only after `Checks` passes.
   A failing `Checks` run blocks the deploy and triggers a stop-the-line
   response.
4. **Feature-flag discipline.** Ship incomplete features behind a flag rather
   than keeping long-lived branches. The circuit-breaker rule from
   `https://github.com/nicolascava/solo-trunk/blob/main/docs/templates/circuit-breaker-rule.md` still applies: once the appetite is
   exhausted, stop.
5. **Same quality bar as the PR workflow.** The `/land` skill runs equivalent
   quality gates (build, tsc, lint, test), a `/pre-merge` self-review, and a
   test plan verification before pushing.

## The `/land` flow

Use the `/land` skill to integrate completed work. It replaces the full PR-based
skill chain for solo-developer repositories:

| PR-workflow step | Solo-trunk equivalent |
|---|---|
| Create PR, request review | (skipped: no external reviewer) |
| `/review-pr` (external review) | `/pre-merge` self-review (clean-context subagents) |
| `/apply-pr-feedback` | Apply findings inline during `/land` |
| `/execute-test-plan` (linked issue) | Test plan execution during `/land` |
| Wait for CI green in PR | Wait for CI green on `main` (BLOCKING) |
| Pre-merge block (branch protection) | Revert-on-red (stop-the-line) |
| `/merge` | Direct push + `gh run watch --exit-status` |

## Quality-parity table

| Quality concern | PR workflow | Solo-trunk |
|---|---|---|
| Code correctness | External reviewer + `/review-pr` | `/pre-merge` self-review (phases 1-3) |
| Reviewer findings applied | `/apply-pr-feedback` | Inline during `/land` step 3 |
| Test plan verified | `/execute-test-plan` | Linked issue test plan during `/land` step 4 |
| Build + type + lint + test | `Checks / Quality` CI gate (required) | Local gates in `/land` step 2, then CI on `main` |
| No bad commit reaches prod | `Checks / Quality` on PR + branch protection | `Checks` on `main` + `workflow_run` deploy gate |
| Red state resolved fast | Merge blocked by CI | Revert-on-red within 30 minutes |

## Stop-the-line rule

If any CI run on `main` fails after a push:

1. Do not push additional commits on top of a red `main`.
2. Either revert (`git revert HEAD; git push origin main`) or fix forward within
   30 minutes.
3. Confirm the corrective run is green before resuming normal work.

The 30-minute ceiling is borrowed from `https://github.com/nicolascava/solo-trunk/blob/main/docs/templates/in-flow-workflow-guide.md`.
A red `main` is a production incident, not a normal working state.

## CI configuration

For the solo-trunk workflow to gate deploys correctly, the repository's CI must
be configured as follows:

- **`checks.yml`** must trigger on `push: branches: [main]` (in addition to the
  standard `pull_request` trigger). This ensures the `Checks / Quality` job runs
  on every direct commit to `main`.
- **`deploy.yml`** must trigger via `workflow_run` on the `Checks` workflow
  (`types: [completed]`, `branches: [main]`), with the deploy job guarded by
  `github.event.workflow_run.conclusion == 'success'`. A separate gate job
  replicates path-filter behaviour (since `workflow_run` does not support path
  filters natively).

The reference implementation's checks and deploy workflows are configured this way.

## Opting in

1. Add `git-workflow.json` to the repository root: `{ "workflow": "solo-trunk" }`
2. Declare the opt-in in the repository's agent instructions under "Workflow rules" so agents honor it.
3. Ensure the repository CI matches the configuration described above.
4. Use `/land` instead of `/pr` + `/merge` to integrate completed work.
