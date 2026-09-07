# Cross-device development baseline

## Roles and source of truth

- GitHub `origin/main` is the shared source of truth for verified project history.
- GitHub Issues/PRs are the shared coordination state for cross-context work when available; they are not product authority by themselves.
- Approved specs remain the product-behavior authority. A GitHub work item points to the relevant authoritative source instead of replacing it.
- The canonical desktop checkout is the local execution environment; its path is recorded in `PROJECT_CONTEXT.md`.
- Codex owns production-code edits, local commands/tests, branch delivery, and PR creation for approved implementation missions.
- Chat/Work/PM/Design may directly read and update GitHub coordination state and bounded documentation when the connected GitHub action set permits it. Do not assume every product surface has the same write permissions.
- The user is not a cross-agent message bus. Do not require the user to copy a prompt from Chat/Work into Codex when the same task can be persisted in GitHub.
- A local unpushed change is not cross-device availability.

## GitHub-backed work queue

Use `docs/operations/GITHUB_WORK_QUEUE.md` as the durable queue contract.

Normal path:

```text
User requirement / approved decision
→ GitHub work item
→ [READY FOR CODEX]
→ Codex branch + implementation + validation
→ PR / [READY FOR REVIEW]
→ review / repair if needed
→ merge or approved delivery
→ [DONE]
```

When the next step is a product/design decision, the work item becomes `[NEEDS DECISION]`; do not manufacture implementation work or ask the user to relay a long prompt to another context.

Creating an Issue does not by itself prove that Codex was automatically started. Until a verified trigger exists, Codex picks up `[READY FOR CODEX]` work items at session start/resume. This keeps the queue compatible with later automation without changing the task contract.

## Start-of-work synchronization

1. On the desktop, confirm the current branch, upstream, and `origin` with `git status --short --branch` and `git remote -v`.
2. If the worktree is dirty, record its changed paths. An approved active mission may continue within its own boundary, but do not pull, rebase, switch branches, or overwrite those changes.
3. When synchronization is needed and the worktree is clean, run `git fetch origin` and inspect whether the local branch diverges from its upstream.
4. Integrate upstream changes only when safe without rewriting history or losing unrelated work. Treat unclear divergence as a blocker.
5. Read the active GitHub work item and its linked authoritative sources; do not depend on conversation history as the only task description.
6. Record the current baseline and active mission scope in the work item or Durable Handoff when cross-device continuity is needed.

## Desktop implementation and delivery

1. Keep each change scoped to one coherent mission and verify it locally.
2. Review `git status` and `git diff --check` before committing.
3. Production-code and approved product-behavior changes use a short-lived branch + PR by default; link the PR to the GitHub work item.
4. Create atomic commits with clear conventional messages after verification succeeds.
5. Push the committed branch to `origin` and verify the remote revision.
6. Update the work item/PR with verification evidence, changed scope, remaining risks, and review state.

Documentation-only operational changes may go directly to `main` when the active mission explicitly authorizes that bounded low-risk write. Playtest/prototype branches follow `AGENTS.md` and must not self-promote to product authority.

Commit and push at a coherent mission or delivery checkpoint, not for micro-steps. Never force-push, rewrite published history, or report locally-only work as delivered across devices.

## Review and PR routing

- Review the actual PR/diff plus referenced authoritative specs; do not ask the user to paste an implementation summary that already exists in GitHub.
- If implementation matches an already-approved requirement and verification/review passes, PM may continue the approved integration path without asking for another "go" message unless a genuine approval/destructive boundary exists.
- If review finds a bounded implementation defect, return it through PR comments/work-item state and let Codex repair it; the user should not relay repair prompts.
- If review finds a product/design ambiguity, mark `[NEEDS DECISION]` and return only the minimal decision boundary to the user.
- When a supported Work PR-activity trigger is configured, it may automate review/monitoring. Absence of such automation does not change the GitHub queue contract.

## Branch policy

- Codex threads describe execution context; they do not permanently map to Git branches.
- Keep `main` as the verified launch baseline.
- Create a short-lived branch only when a coherent mission needs isolation. Avoid branch churn for routine work.
- A PR is the preferred integration/review boundary for production-code changes because it provides durable diff, comments, checks, and review history.

## Dirty worktree rule

- Do not pull, rebase, switch branches, or start unrelated work while the worktree is dirty.
- Do not use destructive recovery commands to make a tree look clean.
- Preserve existing changes and ask the task owner to choose the intended boundary when ownership is unclear.

## Conflict handling

1. Stop the implementation when a merge or rebase conflict occurs.
2. List every conflicted file and identify whether it belongs to the active task or another task.
3. Resolve only conflicts within the approved scope; request direction for overlapping or ambiguous changes.
4. Run the relevant verification again after resolution.
5. Review the final diff before committing and report the conflict resolution in the work item/PR.

## Fallback when GitHub queue access is unavailable

- Use a repository-relative Mission Brief or Durable Handoff only when the current execution context genuinely cannot read/write the GitHub work item it needs.
- Persist that artifact in the canonical repository when possible and reference it by path.
- Do not make the user manually copy a long prompt between contexts merely because one tool surface lacks direct invocation of another agent.
