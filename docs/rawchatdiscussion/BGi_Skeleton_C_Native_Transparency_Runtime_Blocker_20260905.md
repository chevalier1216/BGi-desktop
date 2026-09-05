# Skeleton C Native Transparency Runtime Blocker — 2026-09-05

## Mission identity

- Branch: `playtest/r01-progression-c`
- Verified base: `09aa7b2aa7a1a2d30a2e1aded2a5ea06f0590f02`
- Status: non-authoritative playtest; transparency diagnostic complete, click-through acceptance remains separate and pending. Not merged and not committed/pushed as validated.
- Persistence: only `user://playtest_r01_progression_c/state.json`; normal main persistence was not used.

## Completed evidence

- Skeleton C headless progression regression passed before this foreground phase.
- Dedicated playtest scene parses and the new `skeleton_c_playtest_transparency_config_test.gd` passes.
- Formal Godot 4.7.1 Windows x86_64 release template was installed at `G:/Projects/Godot/export_templates/4.7.1.stable/windows_release_x86_64.exe` and used to rebuild the playtest executable.
- The project enables `display/window/per_pixel_transparency/allowed`, `display/window/size/transparent`, and `rendering/viewport/transparent_background`.
- Windows DWM composition was enabled on the RTX 3080 host.

## Foreground transparency diagnostic result

The full usable-screen geometry build failed: the host started opaque black and showed the desktop only after a click-through event or foreground loss.

The one-pixel geometry diagnostic (`usable_rect.size - Vector2i(1, 1)`) passed: the background was immediately transparent.

This is evidence of a Windows/Godot full usable-screen transparency compatibility issue. The one-pixel inset is diagnostic only; it is not approved as a production layout fix.

## Native evidence before the geometry diagnostic

A read-only probe of an active formal-build window reported:

- borderless window style present;
- DWM composition enabled;
- no `WS_EX_LAYERED` extended style.

The final full-geometry failed run was closed before its equivalent read-only probe could be collected. Do not infer that the deferred-flag timing repair changed this result.

## Next bounded technical mission

Do not treat the geometry diagnostic as a production fix or claim full foreground validation pass from it.

Treat Windows click-through as a separate acceptance concern. Verify that the current transparent diagnostic build preserves visible BGi UI while UI-local input is handled by BGi and transparent-region input reaches the desktop. Do not change the diagnostic geometry result into a production rule during this acceptance.

## Final branch validation evidence

- The one-pixel geometry diagnostic build passed immediate transparent-background validation.
- Its UI-local input and transparent-region click-through checks both passed.
- The full Skeleton C foreground checklist passed: Tutorial exposes the two parallel roots; Explore001 exposes Explore002; Territory001 persists Territory03 first-touch and exactly one worker02 Unit; Explore003 waits for both prerequisites; and reset returns to the isolated profile's Tutorial checkpoint.

This validates the non-authoritative playtest branch only. Any production integration must decide and replace the full-usable-screen transparency compatibility workaround through its own technical review; this branch must not merge itself into `main`.

This is a Windows/Godot runtime integration blocker, not a product or Design Decision Boundary.
