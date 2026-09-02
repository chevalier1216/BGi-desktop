param(
    [switch]$BackgroundTarget,
    [string]$ReportDirectory,
    [int]$TargetX,
    [int]$TargetY,
    [int]$ScreenIndex = 1,
    [switch]$ValidateOnly,
    [switch]$DiagnosticOnly
)

$ErrorActionPreference = 'Stop'

Add-Type @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class BgiNativeInput {
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr SetProcessDpiAwarenessContext(IntPtr value);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern IntPtr GetThreadDpiAwarenessContext();
  [DllImport("user32.dll")] public static extern int GetAwarenessFromDpiAwarenessContext(IntPtr value);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll", SetLastError=true)] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo);
  [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr WindowFromPoint(POINT point);
  [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll", SetLastError=true)] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);
  [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder name, int maxCount);
  [DllImport("user32.dll", EntryPoint="GetWindowLongPtrW")] public static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int index);
  [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr hWnd, uint flags);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
  public const uint LEFTDOWN = 0x0002, LEFTUP = 0x0004, GA_ROOT = 2;
  public const int GWL_EXSTYLE = -20;
  public const long WS_EX_TRANSPARENT = 0x20, WS_EX_LAYERED = 0x80000;
  public static void Click(int x, int y) { SetCursorPos(x, y); mouse_event(LEFTDOWN, 0, 0, 0, UIntPtr.Zero); mouse_event(LEFTUP, 0, 0, 0, UIntPtr.Zero); }
  public static IntPtr RootWindowAt(int x, int y) { return GetAncestor(WindowFromPoint(new POINT { X=x, Y=y }), GA_ROOT); }
  public static uint WindowProcess(IntPtr hWnd) { uint pid; GetWindowThreadProcessId(hWnd, out pid); return pid; }
  public static string ClassName(IntPtr hWnd) { var value = new StringBuilder(256); GetClassName(hWnd, value, value.Capacity); return value.ToString(); }
  public static Dictionary<string, object> Receipt(IntPtr hWnd) {
    RECT rect; GetWindowRect(hWnd, out rect); RECT client; GetClientRect(hWnd, out client); var origin = new POINT { X=0, Y=0 }; ClientToScreen(hWnd, ref origin);
    var style = GetWindowLongPtr(hWnd, GWL_EXSTYLE).ToInt64();
    return new Dictionary<string, object> {
      {"hwnd", hWnd.ToInt64().ToString()}, {"pid", WindowProcess(hWnd)}, {"class_name", ClassName(hWnd)}, {"visible", IsWindowVisible(hWnd)}, {"dpi", GetDpiForWindow(hWnd)},
      {"window_rect", new Dictionary<string, int>{{"x",rect.Left},{"y",rect.Top},{"width",rect.Right-rect.Left},{"height",rect.Bottom-rect.Top}}},
      {"client_origin", new Dictionary<string, int>{{"x",origin.X},{"y",origin.Y}}}, {"client_size", new Dictionary<string, int>{{"width",client.Right-client.Left},{"height",client.Bottom-client.Top}}},
      {"extended_style", style}, {"ws_ex_transparent", (style & WS_EX_TRANSPARENT) != 0}, {"ws_ex_layered", (style & WS_EX_LAYERED) != 0}
    };
  }
  public static List<Dictionary<string, object>> TopLevelReceiptsForProcess(uint expectedPid) { var receipts = new List<Dictionary<string, object>>(); EnumWindows((hWnd, _) => { if (WindowProcess(hWnd) == expectedPid && IsWindowVisible(hWnd)) { receipts.Add(Receipt(hWnd)); } return true; }, IntPtr.Zero); return receipts; }
  public static IntPtr FindTopLevelWindowForProcess(uint expectedPid, int expectedX, int expectedY, int expectedWidth, int expectedHeight) {
    IntPtr exact = IntPtr.Zero; IntPtr fallback = IntPtr.Zero;
    EnumWindows((hWnd, _) => {
      if (WindowProcess(hWnd) != expectedPid || !IsWindowVisible(hWnd)) return true;
      if (fallback == IntPtr.Zero && ClassName(hWnd) != "ConsoleWindowClass") fallback = hWnd;
      RECT rect; GetWindowRect(hWnd, out rect);
      if (rect.Left == expectedX && rect.Top == expectedY && rect.Right-rect.Left == expectedWidth && rect.Bottom-rect.Top == expectedHeight) { exact = hWnd; return false; }
      return true;
    }, IntPtr.Zero);
    return exact != IntPtr.Zero ? exact : fallback;
  }
}
'@

# This process performs both WindowFromPoint and SendInput-equivalent mouse_event calls.
# It must become per-monitor DPI-aware before WinForms or any display API is initialized.
$dpiContextApplied = [BgiNativeInput]::SetProcessDpiAwarenessContext([IntPtr](-4))
if ($dpiContextApplied -eq [IntPtr]::Zero) { [void][BgiNativeInput]::SetProcessDPIAware() }
$mainDpiAwareness = [BgiNativeInput]::GetAwarenessFromDpiAwarenessContext([BgiNativeInput]::GetThreadDpiAwarenessContext())

if ($ValidateOnly) {
    $required = @('button_rect', 'SetProcessDpiAwarenessContext', 'TopLevelReceiptsForProcess', 'FindTopLevelWindowForProcess', 'ws_ex_transparent', 'RootWindowAt', 'BGI_NATIVE_ACCEPTANCE_DIAGNOSTIC_ONLY', 'godot_hwnd_client_origin_plus_button_rect', 'Godot_v4.7.1-stable_win64.exe')
    $godotSource = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'native_clickthrough_acceptance.gd')
    $scriptSource = Get-Content -Raw -LiteralPath $PSCommandPath
    $missing = @($required | Where-Object { -not ($godotSource.Contains($_) -or $scriptSource.Contains($_)) })
    if ($missing.Count -gt 0) { throw "diagnostic_contract_missing:$($missing -join ',')" }
    if ($scriptSource -match "(?m)^\\$godot\\s*=\\s*'[^']*_console\\.exe'") { throw 'diagnostic_contract_must_not_use_console_executable' }
    [pscustomobject]@{ result='PASS'; check='native_harness_static_contract'; dpi_awareness=$mainDpiAwareness } | ConvertTo-Json -Compress
    exit 0
}

if ($BackgroundTarget) {
	# The background target has the same DPI contract as the orchestrator before WinForms initializes.
    [void][BgiNativeInput]::SetProcessDpiAwarenessContext([IntPtr](-4))
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'BGi native acceptance background target'
    $form.StartPosition = 'Manual'
    $form.FormBorderStyle = 'FixedToolWindow'
    $form.ShowInTaskbar = $false
    $form.TopMost = $false
    $form.Location = New-Object System.Drawing.Point($TargetX, $TargetY)
    $form.Size = New-Object System.Drawing.Size(180, 120)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'background input target'
    $label.Dock = 'Fill'
    $label.TextAlign = 'MiddleCenter'
    $form.Controls.Add($label)
    $form.Add_MouseDown({ [System.IO.File]::WriteAllText((Join-Path $ReportDirectory 'background_received.txt'), 'background_received') })
    $label.Add_MouseDown({ [System.IO.File]::WriteAllText((Join-Path $ReportDirectory 'background_received.txt'), 'background_received') })
    $form.Add_Shown({ [System.IO.File]::WriteAllText((Join-Path $ReportDirectory 'background_ready.json'), (ConvertTo-Json @{ x=$form.Location.X; y=$form.Location.Y; width=$form.Width; height=$form.Height } -Compress)) })
    [System.Windows.Forms.Application]::Run($form)
    exit 0
}

$project = Split-Path -Parent $PSScriptRoot
$godot = 'G:\Projects\Godot\Godot_v4.7.1-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw "Godot GUI executable not found: $godot" }
if ([string]::IsNullOrWhiteSpace($ReportDirectory)) { $ReportDirectory = Join-Path $env:TEMP ('bgi-native-clickthrough-' + [guid]::NewGuid().ToString('N')) }
New-Item -ItemType Directory -Force -Path $ReportDirectory | Out-Null
$log = Join-Path $ReportDirectory 'godot-native-console.log'
$env:BGI_NATIVE_ACCEPTANCE_DIR = $ReportDirectory
$env:APPDATA = $ReportDirectory
$env:LOCALAPPDATA = $ReportDirectory
$env:BGI_NATIVE_ACCEPTANCE_DIAGNOSTIC_ONLY = if ($DiagnosticOnly) { '1' } else { '' }
$target = $null
$godotProcess = $null
try {
    $godotProcess = Start-Process -FilePath $godot -ArgumentList @('--path', $project, '--screen', $ScreenIndex, '--log-file', $log, '--script', 'res://tests/native_clickthrough_acceptance.gd') -PassThru
    $ready = Join-Path $ReportDirectory 'native_ready.json'
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while (-not (Test-Path -LiteralPath $ready) -and [DateTime]::UtcNow -lt $deadline) {
        if ($godotProcess.HasExited) { throw "godot_exited_before_ready:$($godotProcess.ExitCode)" }
        Start-Sleep -Milliseconds 100
    }
    if (-not (Test-Path -LiteralPath $ready)) { throw 'godot_ready_timeout' }
    $native = Get-Content -Raw -LiteralPath $ready | ConvertFrom-Json
    if (-not [bool]$native.ui_point_in_polygon) { throw 'ui_click_not_in_mouse_passthrough_polygon' }
    $screenRect = $native.usable_screen_rect
    if ($null -eq $screenRect -or [int]$screenRect.width -lt 400 -or [int]$screenRect.height -lt 300) { throw 'invalid_godot_usable_screen_rect' }
	$allGodotWindows = [BgiNativeInput]::TopLevelReceiptsForProcess([uint32]$godotProcess.Id)
	$godotHwnd = [BgiNativeInput]::FindTopLevelWindowForProcess([uint32]$godotProcess.Id, [int]$screenRect.x, [int]$screenRect.y, [int]$screenRect.width, [int]$screenRect.height)
	$godotReceipt = if ($godotHwnd -eq [IntPtr]::Zero) { $null } else { [BgiNativeInput]::Receipt($godotHwnd) }
	if ($godotReceipt -ne $null -and [uint32]$godotReceipt.pid -ne [uint32]$godotProcess.Id) { throw 'godot_hwnd_owner_pid_mismatch' }
	$buttonRect = $native.button_rect
	if ($buttonRect -eq $null -or [int]$buttonRect.width -le 0 -or [int]$buttonRect.height -le 0) { throw 'invalid_godot_button_rect' }
	$clientOrigin = $godotReceipt.client_origin
	$uiX = [int]$clientOrigin.x + [int]$buttonRect.x + [int]([int]$buttonRect.width / 2)
	$uiY = [int]$clientOrigin.y + [int]$buttonRect.y + [int]([int]$buttonRect.height / 2)
	$uiHwnd = [BgiNativeInput]::RootWindowAt($uiX, $uiY)
	$rect = if ($godotReceipt -eq $null) { $null } else { $godotReceipt.window_rect }
	$diagnostic = [ordered]@{
		dpi_awareness = $mainDpiAwareness
		all_top_level_windows_for_godot_pid = $allGodotWindows
		godot_window = $godotReceipt
		godot_geometry = $native
		ui_point = @{ x=$uiX; y=$uiY; coordinate_basis='godot_hwnd_client_origin_plus_button_rect'; hwnd=$uiHwnd.ToInt64().ToString(); window_pid=[BgiNativeInput]::WindowProcess($uiHwnd) }
		ui_point_inside_actual_hwnd_rect = ($rect -ne $null -and $uiX -ge [int]$rect.x -and $uiX -lt ([int]$rect.x + [int]$rect.width) -and $uiY -ge [int]$rect.y -and $uiY -lt ([int]$rect.y + [int]$rect.height))
	}
	$diagnostic | ConvertTo-Json -Depth 6 -Compress | Set-Content -NoNewline -LiteralPath (Join-Path $ReportDirectory 'native_window_diagnostic.json')
	if ($DiagnosticOnly) {
		$godotProcess.WaitForExit(8000) | Out-Null
		if (-not $godotProcess.HasExited -or $godotProcess.ExitCode -ne 0) { throw 'godot_diagnostic_did_not_exit_cleanly' }
		[System.IO.File]::WriteAllText((Join-Path $ReportDirectory 'result.txt'), 'DIAGNOSTIC_PASS')
		[pscustomobject]@{ result='DIAGNOSTIC_PASS'; report_directory=$ReportDirectory; receipt=$diagnostic } | ConvertTo-Json -Depth 6 -Compress
		return
	}
	if ($godotReceipt -eq $null) { throw 'godot_render_hwnd_not_found' }
	$targetX = [int]$rect.x + 60
	$targetY = [int]$rect.y + [int]$rect.height - 200
    $target = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-BackgroundTarget', '-ReportDirectory', $ReportDirectory, '-TargetX', $targetX, '-TargetY', $targetY) -PassThru
    $targetReady = Join-Path $ReportDirectory 'background_ready.json'
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (-not (Test-Path -LiteralPath $targetReady) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
    if (-not (Test-Path -LiteralPath $targetReady)) { throw 'background_target_timeout' }
    $targetBounds = Get-Content -Raw -LiteralPath $targetReady | ConvertFrom-Json
    if ([int]$targetBounds.x -ne $targetX -or [int]$targetBounds.y -ne $targetY) { throw 'background_target_dpi_coordinates_mismatch' }
    $transparentX = $targetX + 90
    $transparentY = $targetY + 60
    $transparentHwnd = [BgiNativeInput]::RootWindowAt($transparentX, $transparentY)
    $uiHwnd = [BgiNativeInput]::RootWindowAt($uiX, $uiY)
    $hitTest = [ordered]@{
        dpi_awareness = $mainDpiAwareness
        godot_window = $godotReceipt
        transparent_point = @{ x=$transparentX; y=$transparentY; hwnd=$transparentHwnd.ToInt64().ToString(); window_pid=[BgiNativeInput]::WindowProcess($transparentHwnd) }
        ui_point = @{ x=$uiX; y=$uiY; hwnd=$uiHwnd.ToInt64().ToString(); window_pid=[BgiNativeInput]::WindowProcess($uiHwnd) }
        godot_pid = $godotProcess.Id
        background_pid = $target.Id
    }
    $hitTest | ConvertTo-Json -Compress | Set-Content -NoNewline -LiteralPath (Join-Path $ReportDirectory 'window_hit_test.json')
	if ($uiX -lt [int]$rect.x -or $uiX -ge ([int]$rect.x + [int]$rect.width) -or $uiY -lt [int]$rect.y -or $uiY -ge ([int]$rect.y + [int]$rect.height)) { throw 'godot_ui_point_outside_actual_hwnd_rect' }
    if ([int]$hitTest.ui_point.window_pid -ne $godotProcess.Id) { throw 'bgi_ui_point_not_owned_by_godot_window' }
    [BgiNativeInput]::Click($transparentX, $transparentY)
    $backgroundEvent = Join-Path $ReportDirectory 'background_received.txt'
    $deadline = [DateTime]::UtcNow.AddSeconds(5)
    while (-not (Test-Path -LiteralPath $backgroundEvent) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
    if (-not (Test-Path -LiteralPath $backgroundEvent)) { throw 'transparent_region_did_not_reach_background_target' }
    $windowEvent = Join-Path $ReportDirectory 'bgi_window_input_received.json'
    if (Test-Path -LiteralPath $windowEvent) { throw 'transparent_region_was_received_by_bgi_window' }
    [BgiNativeInput]::Click($uiX, $uiY)
    $bgiEvent = Join-Path $ReportDirectory 'bgi_ui_received.txt'
    $deadline = [DateTime]::UtcNow.AddSeconds(5)
    while (-not (Test-Path -LiteralPath $bgiEvent) -and [DateTime]::UtcNow -lt $deadline) {
        if ($godotProcess.HasExited) { break }
        Start-Sleep -Milliseconds 100
    }
    $buttonGuiEvent = Join-Path $ReportDirectory 'bgi_button_gui_input_received.json'
    if (-not (Test-Path -LiteralPath $bgiEvent)) {
        if (-not (Test-Path -LiteralPath $windowEvent)) { throw 'bgi_window_did_not_receive_input' }
        if (-not (Test-Path -LiteralPath $buttonGuiEvent)) { throw 'bgi_window_received_input_but_button_gui_input_missing' }
        throw 'bgi_button_gui_input_without_pressed'
    }
    $godotProcess.WaitForExit(5000) | Out-Null
    if (-not $godotProcess.HasExited -or $godotProcess.ExitCode -ne 0) { throw 'godot_did_not_exit_cleanly_after_bgi_input' }
    [System.IO.File]::WriteAllText((Join-Path $ReportDirectory 'result.txt'), 'PASS')
    [pscustomobject]@{ result='PASS'; report_directory=$ReportDirectory; console_log=$log; background_event=(Get-Content -Raw $backgroundEvent); bgi_event=(Get-Content -Raw $bgiEvent) } | ConvertTo-Json -Compress
}
catch {
    [System.IO.File]::WriteAllText((Join-Path $ReportDirectory 'result.txt'), "FAIL:$($_.Exception.Message)")
    Write-Error $_
    exit 1
}
finally {
    foreach ($process in @($godotProcess, $target)) {
        if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
    }
}
