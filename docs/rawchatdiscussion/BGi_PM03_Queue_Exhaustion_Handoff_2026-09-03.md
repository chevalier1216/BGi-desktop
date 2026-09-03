# BGi PM03 Queue Exhaustion Handoff — 2026-09-03

## Repository checkpoint

- Repository / branch: `G:\Projects\BGi-Desktop` / `main`.
- Published HEAD: `1571f7a6c81d351f5ffc11f0662109a81406d8a4` (`feat: grant second explore poster reward`).
- Remote verification: `origin/main` equals this HEAD.

## Verified product state

- Authority revision `5624fa811f00aa5a81bed2e5219e8cb057a74c7d` mappings are delivered: `mission.r01.explore_001` fixes `collectible_grant { collectible_id: collectible.r01.poster_001, quantity: 1 }`, and `mission.r01.explore_002` fixes `collectible_grant { collectible_id: collectible.r01.poster_002, quantity: 1 }`, before `completed_pending_claim`.
- Targeted mapping and lifecycle regressions passed for completion, fixed-result replay, and claim receipt propagation.

## Authoritative sources

- `docs/superpowers/specs/2026-08-10-bgi-desktop-full-loop-contract-supplement.md` §3.4
- `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md`「已核准的單一正式探索任務效果對照」
- `docs/rawchatdiscussion/BGi_PM03_Durable_Handoff_2026-09-02.md`

## Approved queue and deferred validation

- Queue exhaustion verified: the authority lists only `mission.r01.explore_001` and `mission.r01.explore_002`; both are delivered at `1571f7a`.
- No deferred validation blocks this checkpoint.
- Territory-first-touch direction remains not approved. Other formal mission mappings, collectible mappings, probabilities, quantities, classification, uses, series rewards, display/placement, economy, territory tuning, damage, and black-market content remain deferred and must not be inferred.

## Dirty-work ownership

- Preserve the pre-existing modified `godot/BGiDesktop/project.godot`.
- Preserve all pre-existing untracked documents, assets, `.uid` files, tests, and `tools/` paths. None belong to this handoff commit.

## Next minimal Design Decision Boundary

- **Decision required:** approve exactly one next `mission_template_id → ClaimEffectDescriptor` mapping, including the fixed effect type and all identity/quantity fields required by the existing snapshot contract.
- **Why this is minimal:** without that mapping, any next reward, progression, collectible, territory, or character behavior would be an unapproved inference.
- **Next-role instruction:** gameplay/design discussion may propose options only within this minimal Decision Boundary; it must not approve or publish a mapping. After the user explicitly selects an option, produce a Design02-ready Change Batch for PM.
