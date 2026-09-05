# Durable Handoff — Skeleton C Non-Authoritative Playtest

## Status

- Branch candidate validated for the defined playtest flow; it is **not authoritative** and has no self-merge authority.
- Branch: `playtest/r01-progression-c`
- Verified base: `09aa7b2aa7a1a2d30a2e1aded2a5ea06f0590f02` from `origin/main`.
- Implementation delivery: `43ce0285d7851f20826273a3be7cc696cc41b394`.

## Bounded scope delivered

- Skeleton C tutorial-to-progression flow, including the approved branch-only topology.
- Separate persistence namespace: `user://playtest_r01_progression_c/`; normal main save is not read or written.
- FAST reset/restart.
- Territory 03 first-touch projection and exactly one persistent `character.worker02` roster Unit for the playtest flow.

## Validation evidence

- Headless Skeleton C progression regression: PASS.
- Transparency configuration regression and playtest scene parse: PASS.
- Manual foreground checklist: PASS for Tutorial claim, Explore001/Explore002 availability, Territory001 first touch, Worker02 Unit x1, Explore003 gating, FAST reset, and persistence isolation.
- Manual native acceptance: PASS for UI operation and external click-through while using the 1px geometry diagnostic.

## Known compatibility limitation

- A native window sized to the full usable-screen rectangle rendered a black background in this Windows/Godot environment.
- Reducing the native window by one pixel restored visual transparency. This is an experimental branch diagnostic, **not** an approved production layout or integration rule.

## PM03 next routing

- Keep the branch as a candidate only. Do not merge it into `main`.
- Any product-rule adoption requires explicit user approval, then Design02 authoritative synchronization, followed by PM-authorized main integration.
- If production desktop transparency is scheduled separately, treat the full-usable-screen behavior as an engineering compatibility mission; do not silently carry the 1px diagnostic into main.
