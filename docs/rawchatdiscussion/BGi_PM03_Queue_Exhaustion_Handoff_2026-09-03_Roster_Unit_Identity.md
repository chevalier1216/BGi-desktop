# BGi PM03 — Queue Exhaustion Durable Handoff — Roster Unit Identity

Status: `DESIGN_DECISION_REQUIRED`

## Delivered checkpoint

- Authority revision: `d0f22f7f14f6c0701387ac60bd1af5c204a6e6ba`.
- Delivered revision: `81ef1c83fd8d709c97b802cfdc1160b42390805a` (`feat: persist roster unit identities`), pushed to `origin/main`.
- The initial roster is five independent, persistent, dispatchable Units. Each references Character Type `character.worker01`.
- The approved `starter_18 → territory_02` first valid claim creates one sixth independent Unit with the same Type. `character_06` is no longer treated as a Character Type.
- Direct contract regressions passed: `roster_unit_identity_test`, `claim_effect_descriptor_contract_test`, `tutorial_claim_effect_mapping_test`, and `tutorial_claim_effect_mapping_lifecycle_test`.

## Approved queue verification

The authoritative specs currently define and the implementation has delivered only these fixed production mappings:

- `starter_18` → `territory_first_touch` for `territory_02`, adding one Unit of Type `character.worker01`.
- `starter_19`–`starter_23` → their approved fixed collectible grants.
- `mission.r01.explore_001` → `collectible.r01.poster_001` ×1.
- `mission.r01.explore_002` → `collectible.r01.poster_002` ×1.

No further coherent `IMPLEMENTATION_READY` mapping is present. The prior `starter_01:100 → territory_02` is a fixture only and is not product content.

## Minimal Design Decision Boundary

### Topic

One next explicit production `mission_template_id → ClaimEffectDescriptor` mapping.

### Exact unresolved decision

Select exactly one canonical mission template and its fixed effect type plus every identity field required by the existing snapshot contract. If the effect is `collectible_grant`, this includes `collectible_id` and `quantity`; if it is `territory_first_touch`, this includes `territory_id` and `character_type_id`.

### Why it blocks implementation

Completion results must persist fixed descriptors before `completed_pending_claim`. PM/Coding cannot derive a new mission identity, territory, Character Type, collectible, or quantity from configuration without changing product behavior.

### Dependencies

None beyond the authoritative product decision and publication of its spec revision. Existing fixed-result, claim, persistence, and grant contracts are available.

### Relevant authoritative sources

- `docs/rawchatdiscussion/BGi Desktop — Current Game Design.md`
- `docs/superpowers/specs/2026-08-10-bgi-desktop-full-loop-contract-supplement.md`
- `docs/superpowers/specs/2026-08-10-bgi-desktop-territory-exploration-design.md`

### Existing implementation facts to preserve

- Effects are fixed at completion and persisted; claim/reload must not re-derive them from current configuration.
- `territory_first_touch` is exactly once and uses snapshot identity data.
- Every roster Unit is independently persistent and dispatchable; Type is separate from Unit identity.
- Collectible grants are idempotent and ownership-only where applicable.

### Can this be split?

Yes. This decision is intentionally one bounded mapping and does not depend on resolving any other deferred topic.

## Next-role instruction

Gameplay/design discussion may propose options only within this one Decision Boundary. It must not self-approve or publish a mapping. After the user explicitly selects one option, Design02 may publish a ready Change Batch; PM then implements only that approved mapping.

## Explicitly out of scope

- Any additional mission mapping, territory mapping, Character Type, collectible mapping, quantity, probability, drop table, economy, Series reward, display/placement behavior, black-market rule, or Unit technical-identity decision.
