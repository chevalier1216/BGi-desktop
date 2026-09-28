## Mandatory cross-project PR gate (2026-09-29)

本 repo **必須遵守** [跨專案 Git 交付政策](https://github.com/chevalier1216/KarpathyWiki_personal/blob/main/CROSS_PROJECT_GIT_POLICY.md)。此規範優先於本檔及其他舊文件中任何直接提交預設分支的做法；保留原有產品規格、必要測試、授權與成本限制。Work / Codex / 其他 Agent 不需使用者每次重複提醒：

- 從最新受保護整合分支建立 **每項獨立需求一個短期 branch**；禁止 direct commit/push 至整合分支，包括 Wiki、文件與 hotfix；多 Agent 使用獨立 branch/工作樹。
- 在工作分支驗證、commit、push，建立 PR；審核 diff、範圍、敏感資訊、必要 CI、衝突與 migration/部署影響。未過不得 merge；新費用、破壞性及授權操作仍需明確批准。
- 預設 Squash Merge 並留存 PR、head SHA、merge SHA、CI/部署讀回；需要回檔則從 revert branch 建 PR，不 force push/reset 整合分支。只開 PR 或只 push 不可說已完成整合。
- 並行功能用獨立 PR，合併前確認相依及更新最新整合分支；如不能建立 PR/執行驗證，記錄 blocker，**不可改走直接 push**。
- 此文件為工作方式，不代表 GitHub Ruleset 已啟用；須另行設定與讀回預設分支的 Require PR、必須 CI、禁止 force push/刪除。


# BGi-Desktop Agent Rules

## Source-of-truth hierarchy

1. Approved BGi specs define product behavior and acceptance.
2. This file defines durable BGi-specific constraints.
3. `docs/operations/` holds mutable environment, delivery, and verification details.
4. A current GitHub work item / mission brief defines the active outcome, scope, and acceptance criteria.

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
- Cross-context handoffs contain only a GitHub work item, Mission Brief, Design Decision Packet, or Durable Handoff. Authoritative specs and actual Git state are the durable source of truth; do not hand off full conversation history.
- Do not treat a Codex thread as a permanent Git branch. Use a short-lived Git branch and PR for **every repository change**, including documentation; `main` remains the verified launch baseline.

## GitHub work queue and cross-context routing

- The user must not act as a clipboard between Chat/Work/PM/Design/Codex. When GitHub write access is available, the current control context creates or updates the durable GitHub work item directly.
- GitHub Issue / PR state is the default cross-context control plane. Long specifications remain in authoritative repo documents; the Issue points to them instead of duplicating them.
- Use these title states unless repository labels later replace them:
  - `[NEEDS DECISION]` — product/design decision required; implementation must not proceed past the boundary.
  - `[READY FOR CODEX]` — approved, bounded implementation mission with sufficient acceptance criteria.
  - `[IN CODEX]` — execution started.
  - `[READY FOR REVIEW]` — implementation delivered to a branch/PR and awaiting review.
  - `[BLOCKED]` — genuine tooling, permission, repository-safety, or unresolved dependency blocker.
  - `[DONE]` — merged/delivered and verified at the intended authority level.
- A `[READY FOR CODEX]` work item must contain or link: Goal, approved authority/source, requirements, acceptance criteria, constraints/deferred boundaries, priority, expected delivery, and any required branch/isolation rule.
- At Codex session start/resume, when GitHub Issue access is available, inspect open `[READY FOR CODEX]` work items before asking the user for another prompt. Execute the highest-priority eligible item; if multiple equal-priority items have an unresolved dependency/order, return that routing ambiguity to PM rather than asking the user to relay task text.
- Issue creation is durable queue state; do not assume it automatically wakes an existing Codex thread unless a verified trigger is actually configured. The queue contract must remain usable whether pickup is manual session start, remote Codex resume, or future automation.
- Coding should link its branch/PR to the work item and update durable state/results there when its GitHub tooling permits. If Coding cannot write GitHub metadata, that is a tooling/authentication boundary; do not ask the user to copy a long prompt between contexts.
- Production-code or approved product-behavior changes use a short-lived branch + PR by default. Documentation-only operational updates also require an isolated branch and PR, including authorized, low-risk edits; no direct write to `main`.
- Review should consume the PR/diff and referenced authoritative sources directly. A passing implementation review may proceed without a new user message when the product decision was already approved and no new approval/destructive boundary exists.
- Non-authoritative playtest/prototype branches never become approved product behavior merely because tests or review pass; their promotion follows the Experimental and playtest branch rules below.
- Follow `docs/operations/GITHUB_WORK_QUEUE.md` for the queue contract and fallback behavior.

## Experimental and playtest branches

- `main` remains the canonical, verified launch baseline. Do not create a branch merely because work is discussed in a PM, Design, Coding, or other conversation; for any persisted repository modification create a separate branch + PR; planning-only discussions without changes need no branch.
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
