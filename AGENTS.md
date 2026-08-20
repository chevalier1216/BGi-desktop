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
- Use roles on demand: `coding` implements and tests; `design` resolves genuine design or operational-data questions; `art_direction` handles approved asset work and visual decisions; `oplog` is used only for release checkpoints, substantial consolidation, or historical audit.
- Do not treat a Codex thread as a permanent Git branch. Use short-lived Git branches only when code isolation has real value; `main` remains the verified launch baseline.

## Global Skills

- Use `$lean-mission-execution` for a defined implementation mission.
- Add `$visible-ux-validation` whenever a mission changes or validates a user-facing flow.
- These Skills provide reusable execution methods. Do not copy their workflows into BGi documents.

## Background-safe validation

- A user working on the Windows workstation is not a blocker for the mission as a whole. Do not seize the foreground window, physical mouse, or keyboard for routine validation.
- A validation runtime may be fixed to the dedicated second physical monitor for real application launch, rendering, screenshot evidence, visible-state inspection, and application or scene-level programmatic interaction. Both monitors remain one Windows interactive session: the second monitor does not authorize global OS-level input or establish foreground isolation.
- Prefer reproducible headless, targeted automated, scene/state, simulated-event, and application-driven background-safe validation. Defer only the part that genuinely requires native foreground interaction.
- Record a deferred foreground-required check as incomplete, with its concrete evidence gap. Do not infer or claim visible UX success from automated evidence alone.
- A low-risk, project-local background-safe UX validation harness that does not alter product behavior may be added as a later infrastructure improvement. It must not delay the current playable-loop mission.

## Git, delivery, and verification

- Follow `docs/operations/CROSS_DEVICE_DEVELOPMENT.md` for synchronization and Git safety.
- Each pushed version must also have a read-back-verified, human-readable Google Doc in the designated BGi Drive folder. It must distinguish released commits from uncommitted or unverified work.
- Follow `docs/operations/GODOT_TESTING.md` for automated and visible validation. Automated evidence alone never passes visible UX validation.
- Follow `docs/operations/USAGE_HANDOFF.md` when the usage stop threshold is reached.

## 美術與素材

- 素材取得、授權核對、導入與資產台帳必須遵循 `docs/operations/ASSET_POLICY.md`。
