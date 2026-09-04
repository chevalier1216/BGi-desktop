# Design Decision Packet — Next P1

Authority checkpoint: `5616611a6af9dccfaaa9d559e1872948d91a9822` on `origin/main`.

## Topic

Next single formal mission-to-`ClaimEffectDescriptor` mapping.

## Current authoritative rule

The approved mapping table is exhausted: `starter_18`–`starter_23`, `mission.r01.explore_001`, `mission.r01.explore_002`, and `mission.r01.territory_001` are implemented. Unlisted tutorial and formal missions must not infer an effect. Existing first-touch, collectible, receipt, reload, and roster-Unit contracts remain in force.

## Exact unresolved decision

Select exactly one next `mission_template_id` and its fixed completion-time `ClaimEffectDescriptor`:

- effect type;
- required identity fields; and
- `quantity` only when the selected effect is `collectible_grant`.

No other mission, territory, Character Type, unlock/order, probability, economy, display, or placement decision is included.

## Why it now blocks implementation

`TutorialClaimEffectMapping` intentionally returns an empty descriptor list for every unlisted mission. Adding an entry would define product reward/progression behavior that the authoritative specs do not uniquely determine.

## Dependencies

- A user-selected design decision must be synchronized authoritatively before Coding can implement it.
- The selected mapping must use existing descriptor contracts; any new effect contract is outside this packet.

## Relevant authoritative spec paths

- `docs/superpowers/specs/2026-08-10-bgi-desktop-full-loop-contract-supplement.md` — approved descriptor table and non-inference boundary.
- `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md` — approved territory and formal exploration mappings.
