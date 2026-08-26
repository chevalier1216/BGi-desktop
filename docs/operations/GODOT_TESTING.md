# Godot Testing Playbook

## Scope

Use this playbook for Godot headless verification and the transition to visible QA.

## Headless test isolation

- Run every test with a unique temporary directory.
- Set `APPDATA` and `LOCALAPPDATA` to that directory for the test process.
- Pass a separate absolute `--log-file` path inside the same temporary directory.
- Keep test-created `user://` data inside that isolated environment.

## Evidence to record

- Godot version and test script path.
- Exact command or equivalent reproducible parameters.
- Exit code.
- Expected assertions or checks.
- Non-test warnings, kept separate from failures.

## Example PowerShell pattern

```powershell
$testRoot = Join-Path $env:TEMP ("bgi-godot-test-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
$env:APPDATA = $testRoot
$env:LOCALAPPDATA = $testRoot
& 'G:\Projects\Godot\Godot_v4.7.1-stable_win64_console.exe' `
  --headless `
  --path 'G:\Projects\BGi-Desktop\godot\BGiDesktop' `
  --log-file (Join-Path $testRoot 'godot-headless.log') `
  --script 'res://tests/<test_script>.gd'
```

## Validation progression

Use the smallest relevant automated/headless verification first. For user-facing work, run the normal visible UX checkpoint in Godot editor 的 embedded game／in-editor execution using `$visible-ux-validation`. Native desktop／exported executable validation is reserved for OS-specific milestone or integration acceptance.

- A build, headless run, or source inspection alone does not pass visible UX validation.
- Visible UX validation may use placeholders when approved requirements allow them; missing final art alone is not a blocker.
- Full QA follows a complete visible gameplay loop. Do not require Full QA before an earlier visible UX checkpoint.

## Background-safe validation order

When the Windows workstation is in use, continue all validation that does not require native foreground control. Do not seize the foreground window, physical mouse, or keyboard. A BGi runtime or validation window may be fixed to the dedicated second physical monitor for background-safe real-application work; both monitors still share one Windows interactive session, so this does not authorize global OS-level input or guarantee foreground isolation.

1. Prefer Godot editor 的 embedded game／in-editor execution for ordinary player-visible UI validation, including panel content and interaction evidence.
2. Run CLI, headless, targeted automated, application or scene-level simulated-event, and state-transition tests normally; these do not by themselves pass player-visible UI validation.
3. Use screenshot, viewport, and state evidence to corroborate the observed behavior.
4. Reserve native desktop／exported executable validation on monitor 2 for OS-specific behavior such as desktop transparency, click-through, or interaction with Windows／other applications, and for milestone or integration acceptance.
5. Label a check `foreground-required` only when the preceding methods cannot verify it and native foreground window, mouse, or keyboard control is genuinely necessary.
6. Defer that foreground-required check without stopping independent implementation, testing, documentation, or Git delivery work.
7. Until it is performed, report the OS-specific visible UX result as incomplete; never substitute automated evidence for the missing interaction.

When the Codex execution environment cannot access the interactive Windows desktop, record the outcome as `background validation complete / foreground validation deferred`. Do not retry OS screenshots or global mouse or keyboard automation. This deferred validation blocks a later mission only when that mission explicitly depends on the missing native-interaction evidence; otherwise continue the approved execution order without expanding product scope.

Background-safe UX harnesses are allowed when they are low-risk, project-local, reproducible, and do not alter product behavior. Treat them as infrastructure work after the current playable-loop acceptance path, unless they are necessary to reproduce a current defect.
