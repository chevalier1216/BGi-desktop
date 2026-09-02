# BGi PM03 Durable Handoff — 2026-09-02

## Repository checkpoint

- Repository / branch: `G:\Projects\BGi-Desktop` / `main`.
- Verified published revision: `fb8731041ccb4db31a714813fab7545fd0680fa0` (`fix: align desktop native input coordinates`).
- Remote status at checkpoint: `origin/main` equals `fb87310`.

## Verified current product state

- The PM03 visible milestone is complete: in-app panels remain within one BGi desktop host; Embedded Game validation previously passed for mission list/detail content, drag, z-order, ESC, and close/reopen input.
- Native click-through acceptance passed at `fb87310`: transparent host regions delivered input to the background target and the BGi UI region delivered input to its Button.
- DesktopWindowController synchronises the native work-area size and content scale, so native pointer input, Control geometry, and the passthrough polygon share one coordinate basis.

## Authoritative sources

- `docs/superpowers/specs/2026-08-10-bgi-desktop-full-loop-contract-supplement.md`
- `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md`
- `docs/superpowers/specs/2026-08-10-bgi-desktop-mission-lifecycle-state-ownership.md`
- `docs/operations/DURABLE_HANDOFF_2026-08-25_PM03.md`

## Approved queue and deferred validation

- Targeted discovery found no further coherent IMPLEMENTATION_READY mission after the completed native milestone.
- No validation remains deferred for this completed milestone.
- Do not infer deferred mission mappings, drop tables/probabilities, collectible uses, placement/display behavior, resource economy, territory tuning, or black-market content.

## Dirty-work ownership

- Preserve the pre-existing modified `godot/BGiDesktop/project.godot`.
- Preserve all pre-existing untracked documents, assets, `.uid` files, tests, and `tools/`; none are part of this handoff commit.
- No mission-owned production or harness changes remain uncommitted at this checkpoint.

## Next minimal Design Decision Boundary

- **Decision required:** approve the next explicit `mission_template_id → ClaimEffectDescriptor` mapping, including only the effect kind and identity fields required by the existing fixed-result/claim contract.
- **Why required:** the authoritative durable handoff confirms the currently approved mappings are exhausted; no additional territory, character, or collectible effect may be derived from current configuration or placeholders.
- **Next-role instruction:** Publish one authoritative, fixed descriptor mapping for the highest-priority next mission template, then return its spec revision to PM for the next bounded implementation mission.
