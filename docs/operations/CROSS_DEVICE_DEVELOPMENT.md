# Cross-device development baseline

## Roles and source of truth

- GitHub `origin/main` is the shared source of truth for verified project history.
- `origin` must identify the intended GitHub repository before a mission starts. Local repositories are working copies, not the only persistence layer for completed work.
- The canonical desktop checkout is the local execution environment; its path is recorded in `PROJECT_CONTEXT.md`.
- Desktop Codex writes project files, runs local verification, commits, and pushes.
- The mobile ChatGPT Project is used for planning, requirements clarification, review, and handoff decisions. It does not directly modify the repository.
- A local unpushed change is not cross-device availability.

## Start-of-work synchronization

1. On the desktop, confirm the current branch, upstream, and `origin` with `git status --short --branch` and `git remote -v`.
2. If the worktree is dirty, record its changed paths. An approved active mission may continue within its own boundary, but do not pull, rebase, switch branches, or overwrite those changes.
3. When synchronization is needed and the worktree is clean, run `git fetch origin` and inspect whether the local branch diverges from its upstream.
4. Integrate upstream changes only when safe without rewriting history or losing unrelated work. Treat unclear divergence as a blocker.
5. Record the current baseline and active mission scope in the mission handoff when cross-device continuity is needed.

## Desktop implementation and handoff

1. Keep each change scoped to one coherent mission and verify it locally.
2. Review `git status` and `git diff --check` before committing.
3. Create an atomic commit with a clear conventional message after verification succeeds.
4. Push the committed branch to `origin`.
5. Send one mission-level handoff containing the commit SHA, verification result, changed files, and remaining risks.

Commit and push at a coherent mission or delivery checkpoint, not for micro-steps. Never force-push, rewrite published history, or report locally-only work as delivered across devices.

## Branch policy

- Codex threads describe execution context; they do not permanently map to Git branches.
- Keep `main` as the verified launch baseline.
- Create a short-lived branch only when a coherent mission needs isolation. Merge or otherwise finish that branch after verification; avoid branch churn for routine work.

## Dirty worktree rule

- Do not pull, rebase, switch branches, or start unrelated work while the worktree is dirty.
- Do not use destructive recovery commands to make a tree look clean.
- Preserve existing changes and ask the task owner to choose the intended boundary when ownership is unclear.

## Conflict handling

1. Stop the implementation when a merge or rebase conflict occurs.
2. List every conflicted file and identify whether it belongs to the active task or another task.
3. Resolve only conflicts within the approved scope; request direction for overlapping or ambiguous changes.
4. Run the relevant verification again after resolution.
5. Review the final diff before committing and report the conflict resolution in the handoff.

## Mobile planning rule

- Mobile decisions should name the target branch, desired outcome, acceptance checks, and any files that must remain untouched.
- Desktop execution reports evidence and does not treat an unpushed local change as cross-device availability.
