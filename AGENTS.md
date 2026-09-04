# BGi-Desktop Agent Rules

## Source-of-truth hierarchy

1. Approved BGi specs define product behavior and acceptance.
2. This file defines durable BGi-specific constraints.
3. `docs/operations/` holds mutable environment, delivery, and verification details.
4. A current mission brief defines the active outcome, scope, and acceptance criteria.

Do not duplicate a workflow across these layers. Resolve a conflict by escalating it; do not invent product behavior.

## Canonical scope and safety

- Work only in the canonical project root named by `docs/operations/PROJECT_CONTEXT.md`. Treat any backup as read-only unless the user explicitly authorizes otherwise.
- Preserve unrelated worktree changes. Deleting, moving, or renaming files, changing Windows or ACL settings, external-account authorization, and irreversible external actions require explicit user approval.
- Unspecified economics, rewards, and content values remain `[PLACEHOLDER]`.
- Do not claim a test, import, commit, push, release, or visible UX result without evidence.

## Mission autonomy and roles

- A coherent mission is the unit of implementation, verification, Git delivery, and reporting. The mission owner continues through routine work until the acceptance checkpoint unless there is a genuine blocker, human decision, approval boundary, or usage stop threshold.
- After an approved mission completes, PM may proceed directly to the next mission when the execution order and acceptance are already clear and no human decision is required. Do not require repeated "go" or "continue" messages.
- Do not end a run with a user-facing progress report while an active mission has a spec-defined next necessary step and no genuine blocker, human decision, approval boundary, or usage stop threshold. Continue implementation and targeted verification directly; locating a gap, passing a targeted test, or completing a micro-step is not a reporting checkpoint.
- A run may end only after the coherent mission is verified and delivered, or because a genuine blocker, human decision, approval boundary, usage threshold, or platform interruption prevents continuation. For a platform interruption before mission completion, report `RUN INTERRUPTED — mission incomplete` with the active mission, completed checkpoint, exact next executable step, and whether a blocker exists.
- PM / orchestrator manages the approved queue, priority, dependencies, and routing. When authoritative specs do not uniquely determine product, gameplay, or UX behavior, do not invent it: create a Design Decision Packet for the design context.
- Design owns product, gameplay, UX, and authoritative specifications; it does not modify production code. Completed decisions must be written to an authoritative spec, not retained only in conversation.
- Coding implements and verifies approved specifications without changing product, gameplay, or UX behavior. A genuine implementation ambiguity is returned as `DESIGN_DECISION_REQUIRED`.
- Art direction is used only when visual direction, assets, or art decisions are actually needed. `oplog` is used only for release checkpoints, substantial consolidation, or historical audit.
- Cross-context handoffs contain only a Mission Brief, Design Decision Packet, or Durable Handoff. Authoritative specs and actual Git state are the durable source of truth; do not hand off full conversation history.
- Do not treat a Codex thread as a permanent Git branch. Use short-lived Git branches only when code isolation has real value; `main` remains the verified launch baseline.

## Experimental and playtest branches

- `main` remains the canonical, verified launch baseline. Do not create a branch merely because work is discussed in a PM, Design, Coding, or other conversation; create one only when it provides real implementation, runtime, or persistence isolation value.
- PM / orchestrator owns branch routing. Every branch mission must state its branch name, base revision, bounded scope, status, persistence-isolation approach, required validation, and merge authority.
- Experimental, prototype, debug, and playtest branches are non-authoritative by default. They must not merge themselves into `main`, publish product rules, or be treated as a source of truth.
- FAST, debug, and playtest persistence must be isolated from normal `main` runtime and saves. A branch must not read from or write to normal `main` persistence unless the approved mission explicitly provides a safe, reversible compatibility boundary.
- After branch validation, deliver the branch result through commit, push, remote verification, and a Durable Handoff. The handoff must distinguish validated evidence, remaining limitations, and whether the branch is a candidate, rejected experiment, or ready for integration review.
- When a user formally approves a branch candidate that changes product rules, first complete Design02 authoritative synchronization. PM / orchestrator then schedules and authorizes any `main` integration; approval of the candidate alone does not authorize a self-merge.

## Global Skills

- `$continuous-mission-orchestration`: PM / orchestrator continuity between coherent mission checkpoints.
- `$lean-mission-execution`: continuous work within one defined implementation mission to its acceptance checkpoint.
- `$visible-ux-validation`: only when a user-facing flow is changed or validated.
- `$durable-execution-handoff`: before or after a usage, context, runtime, machine, or agent boundary.
- Load skills by trigger; no role must load all four for every task. These skills provide reusable methods; do not copy their workflows into BGi documents.

## Background-safe validation

- A user working on the Windows workstation is not a blocker for the mission as a whole. Do not seize the foreground window, physical mouse, or keyboard for routine validation.
- A validation runtime may be fixed to the dedicated second physical monitor for real application launch, rendering, screenshot evidence, visible-state inspection, and application or scene-level programmatic interaction. Both monitors remain one Windows interactive session: the second monitor does not authorize global OS-level input or establish foreground isolation.
- Prefer reproducible headless, targeted automated, scene/state, simulated-event, and application-driven background-safe validation. Defer only the part that genuinely requires native foreground interaction.
- Record a deferred foreground-required check as incomplete, with its concrete evidence gap. Do not infer or claim visible UX success from automated evidence alone.
- When the execution environment cannot access the interactive Windows desktop, mark the affected result `background validation complete / foreground validation deferred`. Do not repeatedly attempt OS screenshots or global mouse or keyboard automation.
- A deferred foreground validation is not a pipeline blocker unless its result is an explicit prerequisite of the next approved mission. Continue unrelated, approved implementation, testing, documentation, and Git delivery work without expanding product scope to manufacture work.
- A low-risk, project-local background-safe UX validation harness that does not alter product behavior may be added as a later infrastructure improvement. It must not delay the current playable-loop mission.

## Git, delivery, and verification

- Follow `docs/operations/CROSS_DEVICE_DEVELOPMENT.md` for synchronization and Git safety.
- Each pushed version must also have a read-back-verified, human-readable Google Doc in the designated BGi Drive folder. It must distinguish released commits from uncommitted or unverified work.
- Follow `docs/operations/GODOT_TESTING.md` for automated and visible validation. Automated evidence alone never passes visible UX validation.
- Follow `docs/operations/USAGE_HANDOFF.md` when the usage stop threshold is reached.

## 美術與素材

- 素材取得、授權核對、導入與資產台帳必須遵循 `docs/operations/ASSET_POLICY.md`。
