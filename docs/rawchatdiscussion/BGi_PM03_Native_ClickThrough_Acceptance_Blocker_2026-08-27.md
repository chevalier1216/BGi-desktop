# BGi PM03 Native Click-Through Acceptance — Durable Blocker

## Repository checkpoint

- Repository: `G:\Projects\BGi-Desktop`
- Branch / HEAD / remote: `main` / `9a299daa05bfd9d2ee8f4e32def958adb9316bdb` / `origin/main` verified at the same revision before this acceptance run.
- Product baseline: the Embedded Game visible milestone remains passed; this checkpoint changes no production behavior.

## Failed bounded acceptance

- Acceptance harness: `godot/BGiDesktop/tests/native_clickthrough_acceptance.gd` and `godot/BGiDesktop/tests/native_clickthrough_acceptance.ps1` (mission-owned, uncommitted).
- One authorized rerun on 2026-08-27 failed with `bgi_ui_region_did_not_receive_input`.
- Transparent-region input reached the background target (`background_received.txt` exists), so OS input automation is available.
- No Godot crash, timeout, or harness process remained after cleanup.

## Verified cause

- Godot reported `screen: 1` with `usable_screen_position: (0,0)`.
- The WinForms background target using screen index `1` was placed at `(-1000,-249)`.
- The harness therefore placed the BGi overlay and background target on different physical displays; the UI-region click could not validate BGi routing.
- Evidence directory: `C:\Users\phil\AppData\Local\Temp\bgi-native-clickthrough-9612845c6c2942a4829914bce45971e2`.

## Scope and protected state

- Do not alter or stage the pre-existing dirty `godot/BGiDesktop/project.godot`.
- Preserve all pre-existing untracked paths.
- Current mission-owned untracked paths are the two harness files above and this handoff.
- No mission files are staged or committed after this failure.

## Next executable instruction

Refactor the acceptance harness so it creates or repositions the background target only after reading Godot's actual native usable-screen rectangle from `native_ready.json`; use that same rectangle for both target placement and input coordinates. Run PowerShell/Godot non-native parsing checks. A future native click-through attempt requires fresh explicit one-shot authorization; do not retry automatically.

## Classification

- Original classification: `NATIVE_ACCEPTANCE_FAIL — harness display-coordinate mapping`.
- Not a Design blocker and not a manual-input platform limitation.

## 2026-09-02 rerun evidence

- A newly authorized one-shot rerun used only Godot's `native_ready.json` geometry to create the background target and calculate both clicks.
- Godot reported `usable_screen_rect: (0,0,1080,1920)`; the background target was created at `(80,80)` from that rectangle, and the BGi UI click was `(570,310)` from the same rectangle.
- The transparent-region click again reached the background target, but the BGi UI event still did not arrive. No crash, timeout, or remaining Godot process occurred.
- Evidence directory: `C:\Users\phil\AppData\Local\Temp\bgi-native-clickthrough-187d9a7bf2f64e878a8da182a20d0522`.
- The screen-coordinate mapping failure is resolved; the remaining failure is native UI hit-test/input routing in the acceptance harness or the production mouse-passthrough chain.

## Revised next executable instruction

Without launching another native run, add bounded instrumentation that distinguishes native window receipt, mouse-passthrough polygon membership, and Button `pressed` delivery. Verify the instrumentation through non-native parsing/targeted automated checks. A future native acceptance still requires fresh explicit one-shot authorization.

## 2026-09-02 bounded repair-loop exhaustion

- Authorization allowed three repair cycles; all three used exactly one native attempt after a material harness change and non-native parsing/load validation.
- Cycle 1 added window receipt, polygon membership, Button GUI receipt, and Button `pressed` instrumentation. The UI click produced `bgi_window_did_not_receive_input`.
- Cycle 2 added `WindowFromPoint` PID evidence. The UI point was not owned by the Godot process.
- Cycle 3 made the background target DPI-aware, derived its placement only from Godot's usable rectangle, and verified its reported bounds as `(60,1720,180,120)`. The target does not cover the UI point `(570,310)`, but `WindowFromPoint(UI)` still returned the background process PID.
- Cycle 3 evidence directory: `C:\Users\phil\AppData\Local\Temp\bgi-native-clickthrough-3eff987b13e4485b8627f4f8d5db90c1`.
- No crash, timeout, or residual Godot process occurred in any of the three cycles.

## Final classification and next role instruction

- `NATIVE_ACCEPTANCE_BLOCKED — Windows hit-test/window ownership diagnostic chain`.
- This is not a Design blocker and not a request for manual user clicking.
- Preserve the uncommitted mission-owned harness files and this handoff. Do not retry native acceptance without a new approved repair mission.
- Next debugging mission: enumerate top-level HWND rectangles and ownership for the Godot and background processes, then instrument or inspect the Godot `WM_NCHITTEST` / `DisplayServer.window_set_mouse_passthrough` boundary. Run non-native checks first; any later native attempt must have a fresh bounded authorization.

## 2026-09-02 window-ownership diagnostic mission

- This bounded diagnostic did not send mouse input or run native acceptance.
- The main harness process is now per-monitor DPI-aware before it loads display APIs (`GetAwarenessFromDpiAwarenessContext` = `2`).
- `Godot_v4.7.1-stable_win64_console.exe --script` produced only a same-PID `ConsoleWindowClass` (`993x519`), not the Godot render HWND. The earlier acceptance harness therefore used the console window for ownership and hit-test evidence.
- The harness now uses `Godot_v4.7.1-stable_win64.exe`, enumerates all visible top-level windows for the Godot PID, excludes the console class, and records HWND, owner PID, client/window rect, DPI, and extended styles.
- Diagnostic evidence: `C:\Users\phil\AppData\Local\Temp\bgi-native-window-diagnostic-ee45115cabdb453ba4d82d3bd4c37e09`.
  - Godot render HWND: class `Engine`, PID `25192`, rect `(-1080,-329,1080,1920)`, client origin `(-1080,-329)`, DPI `96`.
  - Godot's usable screen report remained `(0,0,1080,1920)`. It is not the Win32 global desktop coordinate space on this monitor arrangement.
  - A UI point calculated from `Engine` client origin plus Godot's local Button rect was `(-510,-19)`, fell inside the actual HWND rect, and `WindowFromPoint` returned the same Engine HWND/PID.
- Root cause of the invalid prior acceptance is confirmed: it combined the console executable / console HWND with a Godot-local usable-screen coordinate as if it were a Win32 physical coordinate. This was a harness fault, not evidence of a product click-through failure.
- The corrected harness derives both background target and BGi UI physical coordinates from the selected Engine HWND receipt. The next native attempt is a new bounded acceptance, not a retry of the invalid console-based runs.

## 2026-09-02 viewport/stretch transform isolation

- No native runtime was started and no input was sent for this isolation step.
- New acceptance evidence reached the selected Engine HWND at physical `(-510,-19)`. That is `client_origin (-1080,-329) + Button local center (570,310)`, so the Windows HWND and physical point mapping are now correct.
- Godot's root input probe nevertheless received `InputEvent.position = (675,-547)` and the Button received no GUI event.
- `project.godot` fixes the logical viewport at `1280x450` and uses `window/stretch/mode="canvas_items"`. `desktop_window_controller.gd` then changes only `window.size` to the native work area (`1080x1920` in this run); it does not synchronise `Window.content_scale_size` with that work area.
- The observed x transform is exact proof of that mismatch: physical client x `570 * 1280 / 1080 = 675`. The y result additionally crosses the negative-offset monitor/window-position transform, so it cannot be made reliable by changing only the harness physical click coordinate.
- Minimal production repair required before another acceptance: in `DesktopWindowController._apply_window_mode`, after assigning the usable work-area `window.size`, synchronise the window content scale size to that same usable size (or otherwise explicitly establish an equivalent 1:1 desktop-host viewport transform). Keep the existing embedded/headless early return. This makes Control geometry, the passthrough polygon, and native input coordinates share the same local work-area basis.
- A harness-only `content_scale_size` override would mask the production defect, so it was deliberately not applied. The harness remains limited to its corrected Engine-HWND physical coordinate receipt.
- Required targeted non-native regression after the production repair: assert that the desktop host's configured logical content scale matches the usable work-area size while the embedded-game guard preserves its existing behaviour. Do not rerun native acceptance until that regression passes.

## 2026-09-02 resolved acceptance

- Production repair: `DesktopWindowController` now synchronises `Window.content_scale_size` with the native usable work-area whenever it enables desktop-window mode. The existing headless and Embedded Game guards remain unchanged.
- Targeted regressions passed: `desktop_window_embedded_lifecycle_test.gd` and the native acceptance harness static load check.
- One new bounded native acceptance passed after that material repair. Its evidence directory is `C:\Users\phil\AppData\Local\Temp\bgi-native-clickthrough-13d5217fe48844bfb8035487bac2cce4`.
  - A transparent-region click reached the background target (`background_received`).
  - A click inside the BGi UI region reached the Button (`bgi_ui_received`).
  - The harness cleaned up its Godot and background-target processes.
- Classification: `NATIVE_CLICK_THROUGH_ACCEPTANCE_PASS`. This document is retained as the diagnostic history rather than an active blocker.
