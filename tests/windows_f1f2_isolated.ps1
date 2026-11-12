param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory
)
# Verifies the Windows F1-F2 dialog: Praat stays usable while it is open, Draw reaches
# Praat, Save image writes a PNG, and Draw & Exit closes it. Uses its own preferences folder.
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) { throw 'The test directory must not already exist.' }
if (-not (Test-Path -LiteralPath $Praat)) { throw 'The Praat executable was not found.' }
$praatExe = $Praat
$testRoot = [IO.Path]::GetFullPath($TestDirectory)
New-Item -ItemType Directory -Path $testRoot | Out-Null
$root = Split-Path -Parent $PSScriptRoot
$preferences = Join-Path $testRoot 'preferences'
$plugin = Join-Path $preferences 'plugin_AERoPlot'
New-Item -ItemType Directory -Path $plugin | Out-Null
foreach ($folder in 'plotScripts', 'tests', 'windows-ui') {
    Copy-Item -LiteralPath (Join-Path $root $folder) -Destination $plugin -Recurse
}
$vars = Join-Path $plugin 'data\vars'
New-Item -ItemType Directory -Path $vars -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $vars 'ui_mode.txt'), 'windows', (New-Object Text.UTF8Encoding($false)))

$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
$bin = Join-Path $plugin 'windows-ui\bin'
New-Item -ItemType Directory -Path $bin -Force | Out-Null
$helper = Join-Path $bin 'AERoPlotWindowsUI.exe'
& $compiler /nologo /target:winexe /optimize+ /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "/out:$helper" (Join-Path $root 'windows-ui\TableUI.cs') (Join-Path $root 'windows-ui\PlotUI.cs') (Join-Path $root 'windows-ui\TablePlotUI.cs')
if ($LASTEXITCODE -ne 0) { throw 'Unable to compile the Windows UI helper.' }

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class F1F2Native {
    public delegate bool EnumCallback(IntPtr window, IntPtr context);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumCallback callback, IntPtr context);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr window, StringBuilder name, int length);
    [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr SendMessageTimeout(IntPtr window, uint message, IntPtr wparam, IntPtr lparam, uint flags, uint timeout, out IntPtr result);
}
'@

function Wait-Until([scriptblock]$Condition, [string]$What, [int]$Seconds = 30) {
    for ($i = 0; $i -lt $Seconds * 10; $i++) {
        if (& $Condition) { return }
        Start-Sleep -Milliseconds 100
    }
    throw "Timed out waiting for $What."
}
function Get-ShellWindow([int]$ProcessId) {
    $script:found = [IntPtr]::Zero
    $callback = [F1F2Native+EnumCallback]{
        param($window, $context)
        $pid2 = [uint32]0
        [F1F2Native]::GetWindowThreadProcessId($window, [ref]$pid2) | Out-Null
        $name = New-Object Text.StringBuilder 256
        [F1F2Native]::GetClassName($window, $name, $name.Capacity) | Out-Null
        if ($pid2 -eq $ProcessId -and $name.ToString() -like 'PraatShell1 *') { $script:found = $window; return $false }
        return $true
    }
    [F1F2Native]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null
    return $script:found
}
function Send-Script([int]$ProcessId, [string]$Script) {
    $window = Get-ShellWindow $ProcessId
    if ($window -eq [IntPtr]::Zero) { throw 'Praat shell window not found.' }
    [IO.File]::WriteAllText((Join-Path $preferences 'Message.txt'), $Script, (New-Object Text.UTF8Encoding($false)))
    $result = [IntPtr]::Zero
    if ([F1F2Native]::SendMessageTimeout($window, 0x8000, [IntPtr]::Zero, [IntPtr]::Zero, 2, 20000, [ref]$result) -eq [IntPtr]::Zero) {
        throw 'Praat did not acknowledge the message.'
    }
}
function Get-Dialog([int]$ProcessId) {
    [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
        [System.Windows.Automation.TreeScope]::Children,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.ProcessId -eq $ProcessId } | Select-Object -First 1
}
function Click-Button($Dialog, [string]$Name, [switch]$NoClick) {
    $button = $null
    for ($i = 0; $i -lt 50 -and $null -eq $button; $i++) {
        $button = $Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.Name -eq $Name -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Button' -and $_.Current.IsEnabled } |
            Select-Object -First 1
        if ($null -eq $button) { Start-Sleep -Milliseconds 200 }
    }
    if ($null -eq $button) {
        $names = ($Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition) | ForEach-Object { $_.Current.Name }) -join '|'
        throw "Button '$Name' not found among: $names"
    }
    if (-not $NoClick) { $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke() }
}
# The dialog disables its buttons while Praat is plotting, so an enabled button means it is finished.
function Wait-Idle($Dialog) {
    Start-Sleep -Milliseconds 700
    Click-Button $Dialog 'Draw' -NoClick
}
function Get-Report([int]$ProcessId, [string]$Tag) {
    $report = Join-Path $testRoot "$Tag-report.txt"
    $picture = Join-Path $testRoot "$Tag-picture.png"
    $script = (Join-Path $plugin 'tests\async_plot_report.praat').Replace('\', '/')
    Send-Script $ProcessId ('runScript: "' + $script + '", "' + $report.Replace('\', '/') + '", "' + $picture.Replace('\', '/') + '"' + "`n")
    Wait-Until { (Test-Path -LiteralPath $report) -and (Test-Path -LiteralPath $picture) } "$Tag report"
    Start-Sleep -Milliseconds 500
    return @{ Report = (Get-Content -LiteralPath $report -Raw).Trim(); Picture = (Get-Item -LiteralPath $picture).Length }
}

$owned = New-Object 'System.Collections.Generic.List[System.Diagnostics.Process]'
try {
    $ready = Join-Path $testRoot 'ready.txt'
    $start = Join-Path $plugin 'tests\f1f2_start.praat'
    $praatProcess = Start-Process -FilePath $praatExe -WorkingDirectory (Join-Path $plugin 'tests') -PassThru `
        -ArgumentList @('--new-send', '--no-plugins', '--no-pref-files', "`"--pref-dir=$preferences`"", "`"$start`"", "`"$ready`"")
    $owned.Add($praatProcess)
    Wait-Until { Test-Path -LiteralPath $ready } 'the start script'

    $child = $null
    Wait-Until {
        $script:child = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($praatProcess.Id)" |
            Where-Object { $_.ExecutablePath -eq $helper } | Select-Object -First 1
        $null -ne $script:child
    } 'the dialog process'
    $dialogProcess = Get-Process -Id $script:child.ProcessId
    $owned.Add($dialogProcess)
    Wait-Until { $script:dialog = Get-Dialog $dialogProcess.Id; $null -ne $script:dialog } 'the dialog window'
    $dialog = $script:dialog

    # Praat must stay usable while the dialog is open.
    $before = Get-Report $praatProcess.Id 'before'
    if ($before.Report -notmatch '^1\s+other$') { throw "Unexpected selection before drawing: $($before.Report)" }

    # Draw keeps the dialog open and draws in Praat.
    Click-Button $dialog 'Draw'
    Wait-Idle $dialog
    $script:drawn = $null
    Wait-Until {
        $script:drawn = Get-Report $praatProcess.Id 'draw1'
        $script:drawn.Picture -gt 5000
    } 'the first plot' 60
    if ($dialogProcess.HasExited) { throw 'The dialog closed after Draw.' }
    if ($script:drawn.Report -notmatch '^1\s+other$') { throw "Selection not restored after Draw: $($script:drawn.Report)" }

    # Save image writes a PNG into the default folder.
    $images = Join-Path $plugin 'data\AERoPlot_Images'
    Click-Button $dialog 'Save image'
    Wait-Idle $dialog
    Wait-Until { @(Get-ChildItem -LiteralPath $images -Filter '*.png' -ErrorAction SilentlyContinue).Count -ge 1 } 'the saved image'
    $saved = @(Get-ChildItem -LiteralPath $images -Filter '*.png')[0]
    if ($saved.Length -lt 5000) { throw 'The saved image is empty.' }

    # The settings were remembered for next time.
    $remembered = Get-Content -LiteralPath (Join-Path $vars 'f1f1Plot.var') -Raw
    if ($remembered -notmatch 'f1Col\$\s+F1' -or $remembered -notmatch 'f2Col\$\s+F2') { throw 'F1 and F2 columns were not remembered.' }

    # Draw & Exit draws and closes the dialog.
    Click-Button $dialog 'Draw & Exit'
    Wait-Until { $dialogProcess.HasExited } 'the dialog to close' 30
    $final = Get-Report $praatProcess.Id 'final'
    if ($final.Picture -lt 5000) { throw 'The final plot is empty.' }
    if ($final.Report -notmatch '^1\s+other$') { throw "Selection not restored after Draw & Exit: $($final.Report)" }
    if (-not $praatProcess.Responding) { throw 'Praat is not responding after the dialog closed.' }
    $left = @(Get-ChildItem -LiteralPath (Join-Path $plugin 'data\temp\f1f2-ui') -Filter 'f1f2-response-*.txt' -ErrorAction SilentlyContinue)
    if ($left.Count -ne 0) { throw 'Response files were left behind.' }

    Write-Output 'PASS: Windows F1-F2 dialog'
}
finally {
    foreach ($p in $owned) {
        try { if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force } } catch { }
    }
}
