# Durable Handoff — PM03 — 2026-08-25

## Repository checkpoint

- Repository: `G:\Projects\BGi-Desktop`
- Branch: `main`
- HEAD: `f69de5a301a2f88b5dfc0fb98dabbc691de5f65d` (`feat: map tutorial claim effects`)
- Remote baseline: `origin/main` received `f69de5a` from `5e77389`.

## Verified product state

- Mission results persist fixed `ClaimEffectDescriptor` values before `completed_pending_claim`; claim and reload only read the snapshot.
- Approved mappings are implemented only for `starter_18`–`starter_23`: first touch for `territory_02` / `character_06`, then the five specified collectible grants.
- Receipt replay and first-touch application remain idempotent. Scene Prop and Scene Set grants remain ownership-only.
- Targeted Godot 4.7.1 headless tests passed. Foreground interactive UX validation is deferred.

## Authoritative sources

- `docs/superpowers/specs/2026-08-10-bgi-desktop-full-loop-contract-supplement.md` §3.4
- `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md`「第一批固定的新手任務效果對照」
- `docs/superpowers/specs/2026-08-10-bgi-desktop-mission-lifecycle-state-ownership.md`

## Approved queue and decision boundary

- No further IMPLEMENTATION_READY mission is known.
- Human design decision required: approve additional `mission_template_id → ClaimEffectDescriptor` entries before implementing any further territory, character, or collectible effects.
- Deferred: all other mappings, drop tables/probabilities, collectible use, Series rewards, Scene Prop/Scene Set display or placement, economy, territory thresholds/damage, and black market.

## Dirty-work ownership

- The worktree contains pre-existing untracked documentation, assets, `.uid` files, and `tools/`; none are part of the commits above and must be preserved.
- No mission-owned uncommitted code changes remain at this checkpoint.

## Resume instruction

Verify `main`, HEAD, `origin/main`, and dirty ownership; read this handoff and the authoritative sources above. Do not infer deferred values. Resume only after design publishes additional approved fixed descriptor mappings, then implement the highest-priority mapped mission.
