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
New-Item -ItemType Directory -Path $plugin | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'plotScripts') -Destination (Join-Path $plugin 'plotScripts') -Recurse
Copy-Item -LiteralPath (Join-Path $root 'tests') -Destination (Join-Path $plugin 'tests') -Recurse
New-Item -ItemType Directory -Path (Join-Path $plugin 'data\vars') -Force | Out-Null

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class LineSpectrumNativeTest {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "SendMessageW")]
    private static extern IntPtr GetText(IntPtr window, uint message, IntPtr length, StringBuilder text);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "SendMessageW")]
    private static extern IntPtr SetText(IntPtr window, uint message, IntPtr unused, string text);
    private delegate bool EnumChildProc(IntPtr window, IntPtr parameter);
    [DllImport("user32.dll")]
    private static extern bool EnumChildWindows(IntPtr parent, EnumChildProc callback, IntPtr parameter);
    public static bool ChangeText(IntPtr parent, string oldText, string newText) {
        bool changed = false;
        EnumChildWindows(parent, (window, parameter) => {
            var text = new StringBuilder(32768);
            GetText(window, 0x000D, (IntPtr)text.Capacity, text);
            if (text.ToString() == oldText) {
                SetText(window, 0x000C, IntPtr.Zero, newText);
                changed = true;
                return false;
            }
            return true;
        }, IntPtr.Zero);
        return changed;
    }
}
'@

$process = $null
try {
    foreach ($case in @('Grid', 'Whole', 'Time')) {
        if ($case -eq 'Whole') {
            $customFolder = Join-Path $testRoot 'custom-images'
            [IO.File]::WriteAllText((Join-Path $plugin 'data\sharedSaveFolder.txt'),
                $customFolder, (New-Object Text.UTF8Encoding($false)))
        }
        if ($case -eq 'Time') { $secondFolder = Join-Path $testRoot 'changed-images' }
        $result = Join-Path $testRoot ($case + '.txt')
        $env:AEROPLOT_TEST_RESULT = $result
        $stdout = Join-Path $testRoot ($case + '.stdout.txt')
        $stderr = Join-Path $testRoot ($case + '.stderr.txt')
        $script = Join-Path $plugin 'tests\line_spectrum_ui.praat'
        $process = Start-Process -FilePath $Praat -WorkingDirectory (Join-Path $plugin 'tests') `
            -ArgumentList @('--new-send', '--no-plugins', '--no-pref-files', "`"--pref-dir=$preferences`"", "`"$script`"", $case) `
            -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $steps = @(
            @{ Window='Line spectrum settings'; Button='Draw & Exit'; Text='' },
            @{ Window='Save line spectrum'; Button='Save'; Text='Image 1 of' }
        )
        if ($case -eq 'Grid') {
            $steps += @(
                @{ Window='Save line spectrum'; Button='Skip'; Text='Image 2 of' },
                @{ Window='Line spectrum settings'; Button='Draw & Exit'; Text='' },
                @{ Window='Save line spectrum'; Button='Save'; Text='Image 1 of' },
                @{ Window='Save line spectrum'; Button='Skip'; Text='Image 2 of' }
            )
        }
        foreach ($step in $steps) {
            $button = $null
            $names = @()
            for ($i = 0; $i -lt 300 -and $null -eq $button -and -not $process.HasExited; $i++) {
                Start-Sleep -Milliseconds 100
                $windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
                    [System.Windows.Automation.TreeScope]::Children,
                    [System.Windows.Automation.Condition]::TrueCondition) |
                    Where-Object { $_.Current.ProcessId -eq $process.Id }
                foreach ($window in $windows) {
                    $elements = @($window.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                        [System.Windows.Automation.Condition]::TrueCondition))
                    $names += @($window.Current.Name)
                    $names += @($elements | ForEach-Object { $_.Current.Name })
                    if ($step.Text -eq '' -or ($names | Where-Object { $_ -like "*$($step.Text)*" })) {
                        $button = $elements | Where-Object { $_.Current.Name -eq $step.Button } | Select-Object -First 1
                    }
                    if ($null -ne $button) {
                        if ($case -eq 'Time' -and $step.Window -eq 'Line spectrum settings') {
                            $changed = [LineSpectrumNativeTest]::ChangeText(
                                [IntPtr]$window.Current.NativeWindowHandle, $customFolder, $secondFolder)
                            if (-not $changed) { throw 'Could not change the native Save folder field.' }
                        }
                        break
                    }
                }
            }
            if ($null -eq $button) {
                $details = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
                throw "${case}: missing $($step.Window) / $($step.Button), controls: $($names -join ', '). $details"
            }
            [LineSpectrumNativeTest]::SendMessage([IntPtr]$button.Current.NativeWindowHandle,
                0xF5, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        }
        for ($i = 0; $i -lt 300 -and -not (Test-Path -LiteralPath $result) -and -not $process.HasExited; $i++) {
            Start-Sleep -Milliseconds 100
        }
        if (-not (Test-Path -LiteralPath $result)) {
            $details = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
            throw "$case did not complete. $details"
        }
        if ((Get-Content -LiteralPath $result -Raw).Trim() -ne 'PASS') { throw "$case failed." }
        Write-Output "Passed: $case."
        if (-not $process.HasExited) { Stop-Process -Id $process.Id }
        $process = $null
    }
    $images = Join-Path $plugin 'data\AERoPlot_Images'
    foreach ($name in @('native_test_vowel.png', 'native_test_vowel_1.png')) {
        if (-not (Test-Path -LiteralPath (Join-Path $images $name))) { throw "Missing image: $name" }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $customFolder 'native_test_whole.png'))) { throw 'Missing whole-sound image.' }
    if (-not (Test-Path -LiteralPath (Join-Path $secondFolder 'native_test_0.250000s.png'))) { throw 'Missing time-slice image.' }
    $sharedFolder = (Get-Content -LiteralPath (Join-Path $plugin 'data\sharedSaveFolder.txt') -Raw).Trim()
    if ($sharedFolder -ne $secondFolder) { throw 'The changed folder was not shared.' }
    if (@(Get-ChildItem -LiteralPath $images -Filter '*.png').Count -ne 2 -or
        @(Get-ChildItem -LiteralPath $customFolder -Filter '*.png').Count -ne 1 -or
        @(Get-ChildItem -LiteralPath $secondFolder -Filter '*.png').Count -ne 1) {
        throw 'Unexpected images: unlabelled or skipped points may have been saved.'
    }
}
finally {
    if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
    Remove-Item Env:\AEROPLOT_TEST_RESULT -ErrorAction SilentlyContinue
}
