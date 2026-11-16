param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) { throw 'The test directory must not already exist.' }
if (-not (Test-Path -LiteralPath $Praat)) { throw 'The Praat executable was not found.' }
$testRoot = [IO.Path]::GetFullPath($TestDirectory)
$root = Split-Path -Parent $PSScriptRoot
$preferences = Join-Path $testRoot 'preferences'
$plugin = Join-Path $preferences 'plugin_AERoPlot'
New-Item -ItemType Directory -Path $plugin -Force | Out-Null
foreach ($folder in 'plotScripts', 'tests', 'windows-ui', 'example') {
    Copy-Item -LiteralPath (Join-Path $root $folder) -Destination $plugin -Recurse
}
Copy-Item -LiteralPath (Join-Path $plugin 'tests\fot_reference_prepare.praat') -Destination (Join-Path $plugin 'plotScripts')
Copy-Item -LiteralPath (Join-Path $plugin 'tests\fot_ellipses.praat') -Destination (Join-Path $plugin 'plotScripts')
$vars = Join-Path $plugin 'data\vars'
New-Item -ItemType Directory -Path $vars -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $vars 'ui_mode.txt'), 'windows', (New-Object Text.UTF8Encoding($false)))

$helper = Join-Path $plugin 'windows-ui\bin\AERoPlotWindowsUI.exe'
if (-not (Test-Path -LiteralPath $helper)) { throw 'The bundled Windows UI helper was not found.' }

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class FoTNative {
    public delegate bool EnumCallback(IntPtr window, IntPtr context);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumCallback callback, IntPtr context);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr window, StringBuilder name, int length);
    [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr SendMessageTimeout(IntPtr window, uint message, IntPtr wparam, IntPtr lparam, uint flags, uint timeout, out IntPtr result);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr window, int command);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool PrintWindow(IntPtr window, IntPtr deviceContext, uint flags);
    [StructLayout(LayoutKind.Sequential)] public struct RECT {
        public int Left, Top, Right, Bottom;
    }
    [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr window, out RECT rect);
}
'@
function Wait-Until([scriptblock]$Condition, [string]$What, [int]$Seconds = 30) {
    for ($i = 0; $i -lt $Seconds * 10; $i++) {
        if (& $Condition) { return }
        Start-Sleep -Milliseconds 100
    }
    throw "Timed out waiting for $What."
}
function Get-Window([int]$ProcessId, [string]$Name) {
    $windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
        [System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition) |
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
function Click-Button($Dialog, [string]$Name) {
    $button = $Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.Name -eq $Name -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Button' -and $_.Current.IsEnabled } |
        Select-Object -First 1
    if ($null -eq $button) { throw "Button '$Name' not found or disabled." }
    $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
}
function Wait-Idle($Dialog) {
    Start-Sleep -Milliseconds 700
    Wait-Until {
        $button = $Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.Name -eq 'Draw' -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Button' -and $_.Current.IsEnabled } |
            Select-Object -First 1
        $null -ne $button
    } 'the plot request to finish'
}
function Select-ComboIndex($Dialog, [string]$Name, [int]$Index) {
    $combo = $Dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.AutomationId -eq $Name -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.ComboBox' } | Select-Object -First 1
    if ($null -eq $combo) { throw "Combo '$Name' was not found." }
    $combo.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern).Expand()
    $items = @($combo.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.ControlType.ProgrammaticName -eq 'ControlType.ListItem' })
    if ($items.Count -le $Index) { throw "Combo '$Name' has no item at index $Index." }
    $items[$Index].GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
}
function Send-Script([int]$ProcessId, [string]$Script) {
    $script:found = [IntPtr]::Zero
    $callback = [FoTNative+EnumCallback]{
        param($window, $context)
        $pid2 = [uint32]0
        [FoTNative]::GetWindowThreadProcessId($window, [ref]$pid2) | Out-Null
        $name = New-Object Text.StringBuilder 256
        [FoTNative]::GetClassName($window, $name, $name.Capacity) | Out-Null
        if ($pid2 -eq $ProcessId -and $name.ToString() -like 'PraatShell1 *') { $script:found = $window; return $false }
        return $true
    }
    [FoTNative]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null
    if ($script:found -eq [IntPtr]::Zero) { throw 'Praat shell window not found.' }
    [IO.File]::WriteAllText((Join-Path $preferences 'Message.txt'), $Script, (New-Object Text.UTF8Encoding($false)))
    $result = [IntPtr]::Zero
    if ([FoTNative]::SendMessageTimeout($script:found, 0x8000, [IntPtr]::Zero, [IntPtr]::Zero, 2, 20000, [ref]$result) -eq [IntPtr]::Zero) {
        throw 'Praat did not acknowledge the message.'
    }
}
function Get-Report([int]$ProcessId, [string]$Tag) {
    $report = Join-Path $testRoot "$Tag-report.txt"
    $picture = Join-Path $testRoot "$Tag-picture.png"
    $script = (Join-Path $plugin 'tests\async_plot_report.praat').Replace('\', '/')
    Send-Script $ProcessId ('runScript: "' + $script + '", "' + $report.Replace('\', '/') + '", "' + $picture.Replace('\', '/') + '"' + "`n")
    Wait-Until { (Test-Path -LiteralPath $report) -and (Test-Path -LiteralPath $picture) } "$Tag report"
    return @{ Report = (Get-Content -LiteralPath $report -Raw).Trim(); Picture = (Get-Item -LiteralPath $picture).Length }
}
function Capture-PictureWindow([int]$ProcessId, [string]$Path) {
    $window = Get-Window $ProcessId '*Picture*'
    if ($null -eq $window) { throw 'Praat Picture window not found.' }
    $handle = [IntPtr]$window.Current.NativeWindowHandle
    [FoTNative]::ShowWindow($handle, 3) | Out-Null
    Start-Sleep -Milliseconds 500
    $rect = New-Object FoTNative+RECT
    if (-not [FoTNative]::GetWindowRect($handle, [ref]$rect)) { throw 'Could not get Picture window bounds.' }
    $bitmap = New-Object Drawing.Bitmap ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    try {
        $hdc = $graphics.GetHdc()
        try {
            if (-not [FoTNative]::PrintWindow($handle, $hdc, 0)) { throw 'Could not capture Picture window.' }
        } finally { $graphics.ReleaseHdc($hdc) }
        $bitmap.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
}

$owned = New-Object 'System.Collections.Generic.List[System.Diagnostics.Process]'
try {
    $ready = Join-Path $testRoot 'ready.txt'
    $start = Join-Path $plugin 'tests\fot_start.praat'
    $praatProcess = Start-Process -FilePath $Praat -WorkingDirectory (Join-Path $plugin 'tests') -PassThru `
        -ArgumentList @('--new-send', '--no-plugins', '--no-pref-files', "`"--pref-dir=$preferences`"", "`"$start`"", "`"$ready`"") `
        -RedirectStandardOutput (Join-Path $testRoot 'praat.stdout.txt') -RedirectStandardError (Join-Path $testRoot 'praat.stderr.txt')
    $owned.Add($praatProcess)
    Wait-Until { Test-Path -LiteralPath $ready } 'the start script'
    Wait-Until {
        $script:child = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($praatProcess.Id)" |
            Where-Object { $_.ExecutablePath -eq $helper } | Select-Object -First 1
        $null -ne $script:child
    } 'the dialog process'
    $dialogProcess = Get-Process -Id $script:child.ProcessId
    $owned.Add($dialogProcess)
    Wait-Until { $script:dialog = Get-Window $dialogProcess.Id 'AERoPlot: Formants-over-time plot*'; $null -ne $script:dialog } 'the formants-over-time dialog'
    $dialog = $script:dialog
    $dialogBounds = $dialog.Current.BoundingRectangle
    if ($dialogBounds.Width -lt 880 -or $dialogBounds.Height -lt 700) {
        throw "The formants-over-time dialog is clipped or too small: $($dialogBounds.Width)x$($dialogBounds.Height)."
    }

    $saveButton = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.Name -eq 'Save image' -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Button' } |
        Select-Object -First 1
    if ($null -eq $saveButton -or $saveButton.Current.IsEnabled) {
        throw 'Save image should be unavailable until this dialog draws a plot.'
    }
    foreach ($label in 'Time column', 'Repetition column (optional)', 'Time relative to', 'Core level', 'Ellipses') {
        $found = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
            [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.Name -eq $label -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Text' } |
            Select-Object -First 1
        if ($null -eq $found) { throw "Expected control label '$label' was missing." }
    }
    $before = Get-Report $praatProcess.Id 'before'
    if ($before.Report -notmatch '^1\s+other$') { throw "Unexpected selection before drawing: $($before.Report)" }

    # Without a repetition column, this table has duplicate reference times.
    Select-ComboIndex $dialog 'RepetitionColumn' 0
    $drawButton = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.AutomationId -eq 'Draw' } | Select-Object -First 1
    if ($null -eq $drawButton -or -not [FoTNative]::PostMessage([IntPtr]$drawButton.Current.NativeWindowHandle, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)) {
        throw 'Could not request invalid-reference validation.'
    }
    Wait-Until {
        $script:validation = $null
        $windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
            [System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.ProcessId -eq $dialogProcess.Id }
        foreach ($window in $windows) {
            $text = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                [System.Windows.Automation.Condition]::TrueCondition) |
                Where-Object { $_.Current.Name -like '*exactly one reference time*' } | Select-Object -First 1
            if ($null -ne $text) { $script:validation = $window; break }
        }
        $null -ne $script:validation
    } 'the duplicate-reference warning'
    Click-Button $script:validation 'OK'
    Select-ComboIndex $dialog 'RepetitionColumn' 3

    # A cancelled Praat colour window must return control to the dialog.
    Click-Button $dialog ('Colour settings' + [char]0x2026)
    Wait-Until { $script:colourWindow = Get-Window $dialogProcess.Id 'Colour settings'; $null -ne $script:colourWindow } 'colour settings'
    $manual = $script:colourWindow.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.Name -eq 'Re-sort manually (a Praat window opens)' } | Select-Object -First 1
    if ($null -eq $manual) { throw 'The manual colour option was missing.' }
    $manual.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
    Click-Button $script:colourWindow 'OK'
    Wait-Until { $script:praatWindow = Get-Window $praatProcess.Id '*Reorder Default Colour Sequence*'; $null -ne $script:praatWindow } 'the Praat colour reorder window'
    Click-Button $script:praatWindow 'Exit'
    Wait-Idle $dialog

    Click-Button $dialog 'Draw'
    Wait-Idle $dialog
    $drawn = Get-Report $praatProcess.Id 'drawn'
    if ($drawn.Picture -le 5000) { throw 'The formants-over-time plot is empty.' }
    if ($drawn.Report -notmatch '^1\s+other$') { throw "Selection was not restored: $($drawn.Report)" }
    Capture-PictureWindow $praatProcess.Id (Join-Path $testRoot 'praat-picture-window.png')
    $objects = (Get-Content -LiteralPath $ready -Raw).Trim() -split '\s+'
    $original = Join-Path $testRoot 'original-times.txt'
    $check = 'selectObject: ' + $objects[0] + "`n" +
        'first = Get value: 1, "Element_t"' + "`n" +
        'third = Get value: 3, "Element_t"' + "`n" +
        'selectObject: ' + $objects[1] + "`n" +
        'writeFileLine: "' + $original.Replace('\', '/') + '", first, tab$, third' + "`n"
    Send-Script $praatProcess.Id $check
    Wait-Until { Test-Path -LiteralPath $original } 'the original time values'
    $times = (Get-Content -LiteralPath $original -Raw).Trim() -split '\s+'
    if ($times.Count -ne 2 -or [Math]::Abs([double]$times[0] - 0.1) -gt 1e-9 -or
        [Math]::Abs([double]$times[1] - 0.3) -gt 1e-9) {
        throw 'Drawing changed the original Table time values.'
    }
    $referenceCheck = Join-Path $testRoot 'reference-check.txt'
    $referenceScript = (Join-Path $plugin 'plotScripts\fot_reference_prepare.praat').Replace('\', '/')
    Send-Script $praatProcess.Id ('runScript: "' + $referenceScript + '", ' + $objects[0] +
        ', "' + $referenceCheck.Replace('\', '/') + '"' + "`n")
    Wait-Until { Test-Path -LiteralPath $referenceCheck } 'the reference-time calculation check'
    if ((Get-Content -LiteralPath $referenceCheck -Raw).Trim() -ne 'PASS') {
        throw 'The reference-time calculation check failed.'
    }
    $settings = Get-Content -LiteralPath (Join-Path $vars 'fotPlot.var') -Raw
    foreach ($expected in @("timeCol$`tElement_t", "repFactor$`tRep", "timeRelativeTo`t1")) {
        if (-not $settings.Contains($expected)) { throw "Setting '$expected' was not remembered." }
    }
    Click-Button $dialog 'Save image'
    Wait-Idle $dialog
    Wait-Until { @(Get-ChildItem -LiteralPath (Join-Path $plugin 'data\AERoPlot_Images') -Filter '*.png' -ErrorAction SilentlyContinue).Count -ge 1 } 'the saved image'
    $saved = @(Get-ChildItem -LiteralPath (Join-Path $plugin 'data\AERoPlot_Images') -Filter '*.png')[0]
    if ($saved.Length -lt 5000) { throw 'The saved image is empty.' }

    $ellipseActual = Join-Path $testRoot 'ellipses-actual.png'
    $ellipseJittered = Join-Path $testRoot 'ellipses-jittered.png'
    $ellipseExpected = Join-Path $testRoot 'ellipses-expected.png'
    $ellipseScript = (Join-Path $plugin 'plotScripts\fot_ellipses.praat').Replace('\', '/')
    Send-Script $praatProcess.Id ('runScript: "' + $ellipseScript + '", "' +
        $ellipseActual.Replace('\', '/') + '", "' + $ellipseJittered.Replace('\', '/') + '", "' +
        $ellipseExpected.Replace('\', '/') + '"' + "`n")
    Wait-Until { Test-Path -LiteralPath $ellipseExpected } 'the grouped ellipse images'
    $expectedHash = (Get-FileHash -LiteralPath $ellipseExpected).Hash
    foreach ($image in $ellipseActual, $ellipseJittered) {
        if ((Get-FileHash -LiteralPath $image).Hash -ne $expectedHash) {
            throw 'Ellipses do not match unjittered comparison-by-sequence groups.'
        }
    }

    Select-ComboIndex $dialog 'ReferenceElement' 0
    Click-Button $dialog 'Draw'
    Wait-Idle $dialog
    $absolute = Get-Report $praatProcess.Id 'absolute'
    if ($absolute.Picture -le 5000) { throw 'The absolute-time plot is empty.' }
    $settings = Get-Content -LiteralPath (Join-Path $vars 'fotPlot.var') -Raw
    if (-not $settings.Contains("timeRelativeTo`t0")) { throw 'The no-reference setting was not remembered.' }

    $levels = $dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.AutomationId -eq 'SequenceLevels' -and $_.Current.ControlType.ProgrammaticName -eq 'ControlType.List' } |
        Select-Object -First 1
    if ($null -eq $levels) { throw 'The sequencing levels list was not found.' }
    $firstLevel = $levels.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition) |
        Where-Object { $_.Current.Name -eq '1' } | Select-Object -First 1
    if ($null -eq $firstLevel) { throw 'The first sequencing level was not found.' }
    $firstLevel.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern).Toggle()
    Start-Sleep -Milliseconds 300
    Select-ComboIndex $dialog 'ReferenceElement' 1
    Select-ComboIndex $dialog 'CoreLevel' 1
    Click-Button $dialog 'Draw'
    Wait-Idle $dialog
    $settings = Get-Content -LiteralPath (Join-Path $vars 'fotPlot.var') -Raw
    if (-not $settings.Contains("timeRelativeTo`t1") -or -not $settings.Contains("coreLevel`t3")) {
        throw 'Filtered reference and core levels were not remembered against the original Table.'
    }
    Select-ComboIndex $dialog 'ReferenceElement' 2
    Click-Button $dialog 'Draw'
    Wait-Idle $dialog
    $settings = Get-Content -LiteralPath (Join-Path $vars 'fotPlot.var') -Raw
    if (-not $settings.Contains("timeRelativeTo`t2")) { throw 'The second reference level was not remembered.' }
    Click-Button $dialog 'Draw & Exit'
    Wait-Until { $dialogProcess.HasExited } 'the dialog to close'
    $final = Get-Report $praatProcess.Id 'final'
    if ($final.Picture -le 5000 -or $final.Report -notmatch '^1\s+other$') { throw 'Draw & Exit failed or changed the selection.' }
    $left = @(Get-ChildItem -LiteralPath (Join-Path $plugin 'data\temp\fot-ui') -Filter 'fot-response-*.txt' -ErrorAction SilentlyContinue)
    if ($left.Count -ne 0) { throw 'Response files were left behind.' }
    $views = @(Get-ChildItem -LiteralPath (Join-Path $plugin 'data\temp\fot-ui') -Filter 'fot-view-*.txt' -ErrorAction SilentlyContinue)
    if ($views.Count -ne 0) { throw 'The dialog view file was left behind.' }
    Write-Output 'PASS: Windows formants-over-time dialog'
}
finally {
    foreach ($process in $owned) {
        try { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force } } catch { }
    }
}
