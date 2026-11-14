param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) { throw 'The test directory must not already exist.' }
if (-not (Test-Path -LiteralPath $Praat)) { throw 'The Praat executable was not found.' }
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
Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class LadefogedNative {
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
    $callback = [LadefogedNative+EnumCallback]{
        param($window, $context)
        $pid2 = [uint32]0
        [LadefogedNative]::GetWindowThreadProcessId($window, [ref]$pid2) | Out-Null
        $name = New-Object Text.StringBuilder 256
        [LadefogedNative]::GetClassName($window, $name, $name.Capacity) | Out-Null
        if ($pid2 -eq $ProcessId -and $name.ToString() -like 'PraatShell1 *') { $script:found = $window; return $false }
        return $true
    }
    [LadefogedNative]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null
    return $script:found
}
function Send-Script([int]$ProcessId, [string]$Script) {
    $window = Get-ShellWindow $ProcessId
    if ($window -eq [IntPtr]::Zero) { throw 'Praat shell window not found.' }
    [IO.File]::WriteAllText((Join-Path $preferences 'Message.txt'), $Script, (New-Object Text.UTF8Encoding($false)))
    $result = [IntPtr]::Zero
    if ([LadefogedNative]::SendMessageTimeout($window, 0x8000, [IntPtr]::Zero, [IntPtr]::Zero, 2, 20000, [ref]$result) -eq [IntPtr]::Zero) {
        throw 'Praat did not acknowledge the message.'
    }
}
function Get-Window([int]$ProcessId, [string]$Name) {
    $windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
        [System.Windows.Automation.TreeScope]::Children,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.ProcessId -eq $ProcessId }
    foreach ($window in $windows) {
        if ($window.Current.Name -like $Name) { return $window }
        $child = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.Name -like $Name -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Window' } |
            Select-Object -First 1
        if ($null -ne $child) { return $child }
    }
}
function Get-Dialog([int]$ProcessId) {
    Get-Window $ProcessId 'AERoPlot: Ladefoged plot*'
}
function Click-Button($Dialog, [string]$Name) {
    $button = $null
    for ($i = 0; $i -lt 100 -and $null -eq $button; $i++) {
        $button = $Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.Name -eq $Name -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Button' -and $_.Current.IsEnabled } |
            Select-Object -First 1
        if ($null -eq $button) { Start-Sleep -Milliseconds 200 }
    }
    if ($null -eq $button) { throw "Button '$Name' not found." }
    $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
}
function Select-AveragesHidden($Dialog) {
    $combo = $Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.AutomationId -eq 'AveragesBar' } |
        Select-Object -First 1
    if ($null -eq $combo) { throw 'The averages bar control was not found.' }
    $combo.SetFocus()
    [System.Windows.Forms.SendKeys]::SendWait('{HOME}')
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
    Start-Sleep -Milliseconds 200
    $selected = $combo.GetCurrentPattern([System.Windows.Automation.SelectionPattern]::Pattern).Current.GetSelection()
    if ($selected.Count -ne 1 -or $selected[0].Current.Name -ne 'Hide averages bar') {
        throw 'The averages bar could not be set to Hide averages bar.'
    }
}
function Wait-Idle($Dialog) {
    Start-Sleep -Milliseconds 700
    $button = $Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.Name -eq 'Draw' -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Button' -and $_.Current.IsEnabled } |
        Select-Object -First 1
    if ($null -eq $button) { throw 'The Ladefoged request has not finished.' }
}
function Get-Report([int]$ProcessId, [string]$Tag) {
    $report = Join-Path $testRoot "$Tag-report.txt"
    $picture = Join-Path $testRoot "$Tag-picture.png"
    $script = (Join-Path $plugin 'tests\async_plot_report.praat').Replace('\', '/')
    Send-Script $ProcessId ('runScript: "' + $script + '", "' + $report.Replace('\', '/') + '", "' + $picture.Replace('\', '/') + '"' + "`n")
    Wait-Until { (Test-Path -LiteralPath $report) -and (Test-Path -LiteralPath $picture) } "$Tag report"
    Start-Sleep -Milliseconds 400
    return @{ Report = (Get-Content -LiteralPath $report -Raw).Trim(); Picture = (Get-Item -LiteralPath $picture).Length }
}

$owned = New-Object 'System.Collections.Generic.List[System.Diagnostics.Process]'
try {
    $ready = Join-Path $testRoot 'ready.txt'
    $start = Join-Path $plugin 'tests\lade_start.praat'
    $praatProcess = Start-Process -FilePath $Praat -WorkingDirectory (Join-Path $plugin 'tests') -PassThru `
        -ArgumentList @('--new-send', '--no-plugins', '--no-pref-files', "`"--pref-dir=$preferences`"", "`"$start`"", "`"$ready`"") `
        -RedirectStandardOutput (Join-Path $testRoot 'praat.stdout.txt') -RedirectStandardError (Join-Path $testRoot 'praat.stderr.txt')
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
    Wait-Until { $script:dialog = Get-Dialog $dialogProcess.Id; $null -ne $script:dialog } 'the Ladefoged dialog'
    $dialog = $script:dialog

    $sharedButtons = @(
        ('Font' + [char]0x2026), ('Output units' + [char]0x2026),
        ('Save folder' + [char]0x2026), ('Colour settings' + [char]0x2026),
        'Save image', 'Draw', 'Draw & Exit', 'Cancel', 'Instructions'
    )
    foreach ($button in $sharedButtons) {
        $found = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.Name -eq $button -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Button' }
        if ($null -eq $found) { throw "Expected shared control '$button' was missing." }
    }
    foreach ($labelName in 'Comparison factor (colour)', 'Max frequency (Hz)') {
        $label = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.Name -eq $labelName -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Text' } |
            Select-Object -First 1
        if ($null -eq $label -or $label.Current.BoundingRectangle.Width -lt 150) {
            throw "The '$labelName' label is missing or clipped."
        }
    }

    $before = Get-Report $praatProcess.Id 'before'
    if ($before.Report -notmatch '^1\s+other$') { throw "Unexpected selection before drawing: $($before.Report)" }

    # Cancelling a Praat colour window must complete the request and keep the dialog usable.
    Click-Button $dialog ('Colour settings' + [char]0x2026)
    Wait-Until { $script:colourWindow = Get-Window $dialogProcess.Id 'Colour settings'; $null -ne $script:colourWindow } 'colour settings'
    $manual = $script:colourWindow.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.Name -eq 'Re-sort manually (a Praat window opens)' -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.RadioButton' } |
        Select-Object -First 1
    if ($null -eq $manual) { throw 'The manual colour option was missing.' }
    $manual.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Click-Button $script:colourWindow 'OK'
    Wait-Until { $script:praatWindow = Get-Window $praatProcess.Id '*Reorder Default Colour Sequence*'; $null -ne $script:praatWindow } 'the Praat colour reorder window'
    Click-Button $script:praatWindow 'Exit'
    Wait-Idle $dialog

    # The shared restore option must restore the default palette immediately.
    Click-Button $dialog ('Colour settings' + [char]0x2026)
    Wait-Until { $script:colourWindow = Get-Window $dialogProcess.Id 'Colour settings'; $null -ne $script:colourWindow } 'colour settings'
    $restore = $script:colourWindow.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.Name -eq 'Restore the original default palette' -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.RadioButton' } |
        Select-Object -First 1
    if ($null -eq $restore) { throw 'The default palette option was missing.' }
    $restore.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Click-Button $script:colourWindow 'OK'
    Wait-Idle $dialog
    $paletteDir = Join-Path $plugin 'data\palettes'
    if ((Get-Content -LiteralPath (Join-Path $paletteDir 'current.palette') -Raw) -ne
        (Get-Content -LiteralPath (Join-Path $paletteDir 'Adjusted_CB_Qualitative_Set1.palette') -Raw)) {
        throw 'The default colour palette was not restored.'
    }

    Select-AveragesHidden $dialog
    $averageValues = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.AutomationId -eq 'ShowAverageValues' } |
        Select-Object -First 1
    if ($null -eq $averageValues -or $averageValues.Current.IsEnabled) {
        throw 'Average-value labels should be disabled when the averages bar is hidden.'
    }
    if ($averageValues.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern).Current.ToggleState -ne
        [System.Windows.Automation.ToggleState]::Off) {
        throw 'Average-value labels should be cleared when the averages bar is hidden.'
    }

    Click-Button $dialog 'Draw'
    Wait-Idle $dialog
    $drawn = Get-Report $praatProcess.Id 'drawn-without-averages'
    if ($drawn.Picture -le 5000) { throw 'The Ladefoged plot is empty.' }
    if ($drawn.Report -notmatch '^1\s+other$') { throw "Selection was not restored after drawing: $($drawn.Report)" }

    Click-Button $dialog 'Save image'
    Wait-Idle $dialog
    $images = Join-Path $plugin 'data\AERoPlot_Images'
    Wait-Until { @(Get-ChildItem -LiteralPath $images -Filter '*.png' -ErrorAction SilentlyContinue).Count -ge 1 } 'the saved image'
    $saved = @(Get-ChildItem -LiteralPath $images -Filter '*.png')[0]
    if ($saved.Length -lt 5000) { throw 'The saved image is empty.' }

    Click-Button $dialog 'Draw & Exit'
    Wait-Until { $dialogProcess.HasExited } 'the dialog to close'
    $final = Get-Report $praatProcess.Id 'final'
    if ($final.Picture -le 5000) { throw 'Draw & Exit did not leave a plot in Praat.' }
    if ($final.Report -notmatch '^1\s+other$') { throw "Selection was not restored after Draw & Exit: $($final.Report)" }
    $left = @(Get-ChildItem -LiteralPath (Join-Path $plugin 'data\temp\lad-ui') -Filter 'lad-response-*.txt' -ErrorAction SilentlyContinue)
    if ($left.Count -ne 0) { throw 'Response files were left behind.' }
    Write-Output 'PASS: Windows Ladefoged dialog'
}
finally {
    foreach ($process in $owned) {
        try { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force } } catch { }
    }
}