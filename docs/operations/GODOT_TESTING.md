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

Use the smallest relevant automated/headless verification first. For user-facing work, then run a visible UX checkpoint through the real application using `$visible-ux-validation`.

- A build, headless run, or source inspection alone does not pass visible UX validation.
- Visible UX validation may use placeholders when approved requirements allow them; missing final art alone is not a blocker.
- Full QA follows a complete visible gameplay loop. Do not require Full QA before an earlier visible UX checkpoint.

## Background-safe validation order

When the Windows workstation is in use, continue all validation that does not require native foreground control. Do not seize the foreground window, physical mouse, or keyboard.

1. Run CLI, headless, targeted automated, and scene/state tests normally.
2. Prefer background-safe user-facing evidence: application or scene execution, simulated UI events, state transitions, and viewport screenshots that do not take OS focus.
3. Label a check `foreground-required` only when native foreground window, mouse, or keyboard control is genuinely necessary.
4. Defer that foreground-required check without stopping independent implementation, testing, documentation, or Git delivery work.
5. Until it is performed, report the visible UX result as incomplete; never substitute automated evidence for the missing interaction.

Background-safe UX harnesses are allowed when they are low-risk, project-local, reproducible, and do not alter product behavior. Treat them as infrastructure work after the current playable-loop acceptance path, unless they are necessary to reproduce a current defect.
