# BGi PM03 Durable Handoff — r01 First-playthrough Progression / Pacing Skeleton

Checkpoint: `41e62bdd86af3d83c6aad351e1f83d80d2381706` on `origin/main`.

## Delivered approved mapping queue

- `starter_18`–`starter_23` fixed descriptors.
- `mission.r01.explore_001 → collectible.r01.poster_001 ×1`.
- `mission.r01.explore_002 → collectible.r01.poster_002 ×1`.
- `mission.r01.territory_001 → territory_03 → character.worker02` first-touch.
- `mission.r01.explore_003 → collectible.r01.poster_003 ×1`.

All listed mappings are implemented through completion-time fixed descriptors, reload-safe result snapshots, and successful-claim application. No unlisted task receives an inferred effect.

## Queue status

No further implementation-ready P0/P1 work is uniquely determined by the current authoritative specs. The next decision must not be another isolated reward mapping.

## Next Design Decision Boundary

**Topic:** r01 first-playthrough progression / pacing growth-line skeleton.

### Exact decision required

Define the player-visible order, availability gates, and pacing checkpoints for the already-approved r01 tutorial, formal exploration, territory, and claim loops. The skeleton must state which existing milestones are available together or sequentially, and what successful-claim event makes each next already-approved milestone available.

### Why it blocks coherent implementation

The code can persist and claim approved effects, but it must not invent when formal exploration begins, how the already-approved missions are sequenced, or which existing claim unlocks the next gameplay checkpoint. Any implementation of mission availability or a progress UI would otherwise encode unapproved pacing.

### In scope for the decision

- ordering / grouping / availability of existing approved milestone identities;
- claim-driven gating between those existing milestones;
- the minimal player-facing progression checkpoints needed to present that sequence.

### Explicitly out of scope

- new mission-to-effect mappings or reward identities;
- collectible quantity, probability, class, usage, series reward, display, or placement;
- new territory, Character Type, Unit, economy, refresh, or save-migration behavior;
- `character.handyman01`, `character.assassin01`, and `character.gangster01` unlock, appearance, or dispatch order;
- implementation code or tests.

