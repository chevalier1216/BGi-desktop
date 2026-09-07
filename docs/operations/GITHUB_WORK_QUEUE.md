# GitHub Work Queue Contract

## Purpose

Use GitHub Issues and Pull Requests as the durable cross-context coordination layer for BGi so the user does not have to relay prompts between Chat/Work/PM/Design/Codex.

This file defines coordination state only. Approved product specifications remain authoritative for product behavior.

## Work-item states

Use title prefixes until repository labels are deliberately introduced:

```text
[NEEDS DECISION]
[READY FOR CODEX]
[IN CODEX]
[READY FOR REVIEW]
[BLOCKED]
[DONE]
```

### `[NEEDS DECISION]`

Use when implementation cannot proceed without a real product/gameplay/UX decision. The Issue must contain the smallest decision boundary and links to relevant authoritative sources. Do not attach an implementation approval that the user has not made.

### `[READY FOR CODEX]`

Use only when the mission is approved and executable without inventing product behavior.

Required fields:

```text
Status: READY FOR CODEX
Priority: P0 | P1 | P2 | P3
Goal:
Authority / sources:
Requirements:
Acceptance criteria:
Constraints / deferred boundaries:
Expected delivery:
Branch / isolation rule: optional unless isolation is required
```

Keep the Issue concise. Long authoritative content belongs in repository specs/documents and is linked by repository-relative path.

### `[IN CODEX]`

Execution has started. Record branch/worktree when applicable and the verified base revision. Do not use this state merely because someone read the Issue.

### `[READY FOR REVIEW]`

Implementation has reached its delivery checkpoint. The Issue or linked PR must contain:

- branch and commit/PR reference;
- verification evidence;
- changed scope;
- deferred/incomplete validation;
- known risks/blockers;
- whether this is authoritative implementation or a non-authoritative candidate.

### `[BLOCKED]`

Use only for a genuine blocker such as repository safety, unavailable authorization/tooling, unresolved external dependency, or a technical condition that prevents all safe progress on the mission. Include the exact next recovery condition.

### `[DONE]`

Use only after the intended delivery/integration state is verified. For production PR work this normally means merged and remote-verified; for a non-authoritative experiment it may mean the experiment mission is complete while the candidate remains unmerged, but the Issue must say so explicitly.

## Role contract

### Chat / Work / PM / Design

When connected GitHub write actions are available:

- create/update the Issue directly;
- record user-approved decisions directly in durable state;
- move implementation-ready work to `[READY FOR CODEX]`;
- review PRs/diffs directly when the surface supports it;
- return only genuine decision/permission/destructive boundaries to the user.

Do not output a long "paste this into Codex" prompt when the same instruction can be written to GitHub.

### Codex

At session start/resume, when Issue access is available:

1. inspect open `[READY FOR CODEX]` work items;
2. choose the highest-priority eligible mission;
3. if equal-priority order/dependency is ambiguous, return that ambiguity to PM rather than asking the user to relay task text;
4. update state to `[IN CODEX]` when execution actually starts, if GitHub metadata write is available;
5. implement/test on the required branch/worktree;
6. open/link a PR for production-code changes by default;
7. deliver evidence through PR/Issue state, not conversation-only summaries.

If Codex cannot access or mutate Issues because of tooling/authentication, report that capability boundary. Do not treat the user as a message transport layer.

## PR contract

Production-code or approved product-behavior changes should normally be delivered through a PR.

The PR should reference the work item and authoritative sources. Review comments are the durable repair channel:

```text
Issue [READY FOR CODEX]
→ Codex branch
→ PR
→ review comments / checks
→ Codex repair if needed
→ approved integration
→ Issue [DONE]
```

Do not require a new user message between routine repair/review cycles when the approved mission has not changed.

## Automation boundary

- Issue creation is a queue write, not proof that Codex has been automatically awakened.
- Until a verified Issue→Codex trigger exists, Codex discovers the queue at session start/resume.
- Supported PR-activity automation in Work may be used for review/monitoring when configured.
- Future automation may replace the pickup mechanism without changing this Issue/PR contract.

## Human interruption policy

Return to the user only for:

1. a real product/gameplay/UX decision;
2. an authentication/permission boundary that cannot be resolved with current authorized tools;
3. a destructive/irreversible action that requires explicit approval;
4. a resource/usage boundary that forces interruption.

Routine routing, prompt formatting, task copying, branch naming, test execution, review fixes, and GitHub status updates are not reasons to make the user act as an agent relay.

## Fallback artifacts

If a context genuinely cannot use the Issue/PR control plane, use a repository-relative Mission Brief, Design Decision Packet, or Durable Handoff. The artifact must be an index to authoritative sources, not a transcript. As soon as GitHub coordination becomes available again, reconcile the durable work-item state there.
