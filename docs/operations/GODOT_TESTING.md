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
