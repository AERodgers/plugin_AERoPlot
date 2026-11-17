param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory,
    [switch]$TableOnly
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) {
    throw 'The test directory must not already exist.'
}
if (-not (Test-Path -LiteralPath $Praat)) {
    throw 'The Praat executable was not found.'
}
$testRoot = [IO.Path]::GetFullPath($TestDirectory)
New-Item -ItemType Directory -Path $testRoot | Out-Null
$root = Split-Path -Parent $PSScriptRoot
$preferences = Join-Path $testRoot 'preferences'
$plugin = Join-Path $preferences 'plugin_AERoPlot'
New-Item -ItemType Directory -Path $plugin | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'plotScripts') -Destination $plugin -Recurse
Copy-Item -LiteralPath (Join-Path $root 'tests') -Destination $plugin -Recurse
Copy-Item -LiteralPath (Join-Path $root 'windows-ui') -Destination $plugin -Recurse
$vars = Join-Path $plugin 'data\vars'
New-Item -ItemType Directory -Path $vars -Force | Out-Null
$expectedTitle = 'Caf' + [char]0x00e9 + ' regression ~ title'
[IO.File]::WriteAllText((Join-Path $vars 'pitch_plus.var'),
    "variable`tvalue`r`nimage_title`$`t$expectedTitle`r`n",
    (New-Object Text.UTF8Encoding($false)))

$bin = Join-Path $plugin 'windows-ui\bin'
$helper = Join-Path $bin 'AERoPlotWindowsUI.exe'
if (-not (Test-Path -LiteralPath $helper)) {
    throw 'The bundled Windows UI helper was not found.'
}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
public static class PlotPrototypeNative {
    public delegate bool EnumChildCallback(IntPtr window, IntPtr parameter);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")]
    private static extern bool EnumChildWindows(IntPtr parent, EnumChildCallback callback, IntPtr parameter);
    [DllImport("user32.dll")]
    public static extern IntPtr GetParent(IntPtr window);
    [DllImport("user32.dll", EntryPoint="GetClassNameW", CharSet=CharSet.Unicode)]
    private static extern int GetClassName(IntPtr window, StringBuilder name, int maximum);
    [DllImport("user32.dll", EntryPoint="GetWindowTextW", CharSet=CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr window, StringBuilder text, int maximum);
    [DllImport("user32.dll")]
    public static extern int GetDlgCtrlID(IntPtr window);
    [DllImport("user32.dll")]
    public static extern bool IsWindowEnabled(IntPtr window);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr window, out RECT rect);
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
    [DllImport("user32.dll", EntryPoint="SendMessageW", CharSet=CharSet.Unicode)]
    private static extern IntPtr SendMessageText(IntPtr window, uint message, IntPtr wparam,
        [MarshalAs(UnmanagedType.LPWStr)] string text);
    [DllImport("user32.dll", EntryPoint="SendMessageW", CharSet=CharSet.Unicode)]
    private static extern IntPtr SendMessageTextBuffer(IntPtr window, uint message, IntPtr wparam,
        StringBuilder text);
    public static IntPtr[] Children(IntPtr parent) {
        var result = new List<IntPtr>();
        EnumChildWindows(parent, delegate(IntPtr window, IntPtr parameter) {
            result.Add(window);
            return true;
        }, IntPtr.Zero);
        return result.ToArray();
    }
    public static string ClassName(IntPtr window) {
        var name = new StringBuilder(256);
        GetClassName(window, name, name.Capacity);
        return name.ToString();
    }
    public static string WindowText(IntPtr window) {
        var text = new StringBuilder(512);
        GetWindowText(window, text, text.Capacity);
        return text.ToString();
    }
    public static IntPtr FindExactComboItem(IntPtr combo, string value) {
        return SendMessageText(combo, 0x158, new IntPtr(-1), value);
    }
    public static string ComboSelection(IntPtr combo) {
        int index = SendMessage(combo, 0x147, IntPtr.Zero, IntPtr.Zero).ToInt32();
        if (index < 0)
            return "";
        int length = SendMessage(combo, 0x149, IntPtr.Zero, IntPtr.Zero).ToInt32();
        var text = new StringBuilder(length + 1);
        SendMessageTextBuffer(combo, 0x148, new IntPtr(index), text);
        return text.ToString();
    }
    public static int Top(IntPtr window) {
        RECT rect;
        return GetWindowRect(window, out rect) ? rect.Top : Int32.MaxValue;
    }
    public static bool IsAfterOnSameRow(IntPtr label, IntPtr control) {
        RECT labelRect, controlRect;
        if (!GetWindowRect(label, out labelRect) || !GetWindowRect(control, out controlRect))
            return false;
        return controlRect.Left >= labelRect.Right - 8 &&
            controlRect.Top < labelRect.Bottom && controlRect.Bottom > labelRect.Top;
    }
    public static int HorizontalGap(IntPtr label, IntPtr control) {
        RECT labelRect, controlRect;
        return GetWindowRect(label, out labelRect) && GetWindowRect(control, out controlRect)
            ? controlRect.Left - labelRect.Right : Int32.MaxValue;
    }
}
'@

function Get-DialogElements($dialog) {
    return @($dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
        [System.Windows.Automation.Condition]::TrueCondition))
}

function Find-ComboByLabel($dialog, [string]$label, [int]$occurrence = 1) {
    $dialogHandle = [IntPtr]$dialog.Current.NativeWindowHandle
    $labelHandles = @([PlotPrototypeNative]::Children($dialogHandle) |
        Where-Object { [PlotPrototypeNative]::WindowText($_) -eq $label } |
        Sort-Object { [PlotPrototypeNative]::Top($_) })
    if ($labelHandles.Count -lt $occurrence) {
        throw "Label '$label' occurrence $occurrence was not found by Win32."
    }
    $labelHandle = $labelHandles[$occurrence - 1]
    for ($parent = [PlotPrototypeNative]::GetParent($labelHandle);
        $parent -ne [IntPtr]::Zero -and $parent -ne $dialogHandle;
        $parent = [PlotPrototypeNative]::GetParent($parent)) {
        $descendants = @([PlotPrototypeNative]::Children($parent))
        $combos = @($descendants | Where-Object {
                [PlotPrototypeNative]::ClassName($_) -match 'COMBOBOX' -and
                [PlotPrototypeNative]::IsAfterOnSameRow($labelHandle, $_)
            } |
            Sort-Object { [PlotPrototypeNative]::HorizontalGap($labelHandle, $_) })
        if ($combos.Count -gt 0) {
            return [IntPtr]$combos[0]
        }
    }
    throw "No adjacent Win32 combo box was found for label '$label' occurrence $occurrence."
}

function Select-ComboOption($dialog, [string]$label, [string]$optionName, [int]$occurrence = 1) {
    $combo = Find-ComboByLabel $dialog $label $occurrence
    $itemIndex = [PlotPrototypeNative]::FindExactComboItem($combo, $optionName).ToInt32()
    if ($itemIndex -lt 0) {
        throw "Option '$optionName' was not found in combo beside '$label'."
    }
    [PlotPrototypeNative]::SendMessage($combo, 0x14E, [IntPtr]$itemIndex, [IntPtr]::Zero) | Out-Null
    $controlId = [PlotPrototypeNative]::GetDlgCtrlID($combo)
    $command = [IntPtr]((1 -shl 16) -bor ($controlId -band 0xffff))
    [PlotPrototypeNative]::SendMessage([PlotPrototypeNative]::GetParent($combo), 0x0111, $command, $combo) | Out-Null
    Start-Sleep -Milliseconds 150
}

function Get-ComboSelection($dialog, [string]$label, [int]$occurrence = 1) {
    $combo = Find-ComboByLabel $dialog $label $occurrence
    return [PlotPrototypeNative]::ComboSelection($combo)
}

function Test-VisibleNamedControl($dialog, [string]$name) {
    $matches = @(Get-DialogElements $dialog |
        Where-Object {
            $_.Current.Name -eq $name -and
            $_.Current.BoundingRectangle.Height -gt 0
        })
    return $matches.Count -gt 0
}

$ownedProcesses = New-Object 'System.Collections.Generic.List[System.Diagnostics.Process]'
try {
    $cases = @(
        @{ Mode='Table'; Script='windows_table_prototype.praat'; Button='Create Table' },
        @{ Mode='Table optional tiers'; Script='windows_table_optional_ui.praat'; Button='Create Table'; RequiredControls=@('Duration tier 1', 'Intensity tier 1', 'Intensity pitch floor (Hz)') },
        @{ Mode='Table sparse saved tiers'; Script='windows_table_sparse_settings.praat'; Button='Create Table' },
        @{ Mode='PitchPlus'; Script='windows_pitch_plus_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Plot type', 'Minimum F0 (Hz)', 'Secondary parameter') },
        @{ Mode='PitchPlus redraw'; Script='windows_pitch_plus_ui.praat'; Buttons=@('Draw', 'Draw  Exit') },
        @{ Mode='PitchPlus without TextGrid'; Script='windows_pitch_plus_sound_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Plot type', 'Minimum F0 (Hz)') },
        @{ Mode='Spectrogram'; Script='windows_spectrogram_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Draw sound waveform', 'Window width (inches)', 'Crop to interval tier', 'Display tier') },
        @{ Mode='Spectrogram without TextGrid'; Script='windows_spectrogram_sound_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Draw sound waveform', 'Window width (inches)') },
        @{ Mode='PitchPlus cancellation'; Script='windows_pitch_plus_ui.praat'; Button='Cancel' }
    )
    if ($TableOnly) {
        $cases = @($cases | Where-Object {
            $_.Mode -in @('Table', 'Table optional tiers', 'Table sparse saved tiers')
        })
    }
    foreach ($case in $cases) {
        if ($case.Mode -eq 'Table sparse saved tiers') {
            $settingsPath = Join-Path $vars 'tier2Table.var'
            $updates = @{
                'ui.lowestTier$' = 'word'
                'ui.formants2tabulate' = '2'
                'ui.vowelDur$' = ''
                'ui.duration2$' = 'vowel'
                'ui.duration3$' = 'syllable'
                'ui.intensityTier1$' = ''
                'ui.intensityTier2$' = 'pitch'
                'ui.intensityTier3$' = 'utterance'
                'ui.intensityMethod1' = '2'
                'ui.intensityMethod2' = '3'
                'ui.intensityMethod3' = '4'
            }
            $settingsLines = @(Get-Content -LiteralPath $settingsPath)
            for ($lineIndex = 0; $lineIndex -lt $settingsLines.Count; $lineIndex++) {
                $separator = $settingsLines[$lineIndex].IndexOf("`t")
                if ($separator -lt 0) { continue }
                $variableName = $settingsLines[$lineIndex].Substring(0, $separator)
                if ($updates.ContainsKey($variableName)) {
                    $settingsLines[$lineIndex] = $variableName + "`t" + $updates[$variableName]
                    $updates.Remove($variableName)
                }
            }
            foreach ($variableName in $updates.Keys) {
                $settingsLines += $variableName + "`t" + $updates[$variableName]
            }
            [IO.File]::WriteAllText($settingsPath,
                ($settingsLines -join "`r`n") + "`r`n",
                (New-Object Text.UTF8Encoding($false)))
        }
        $result = Join-Path $testRoot ($case.Mode.Replace(' ', '-') + '.txt')
        $env:AEROPLOT_TEST_RESULT = $result
        $stdout = Join-Path $testRoot ($case.Mode.Replace(' ', '-') + '.stdout.txt')
        $stderr = Join-Path $testRoot ($case.Mode.Replace(' ', '-') + '.stderr.txt')
        $script = Join-Path $plugin ('tests\' + $case.Script)
        $helperProcessIds = @(Get-CimInstance Win32_Process |
            Where-Object { $_.ExecutablePath -eq $helper } |
            ForEach-Object { $_.ProcessId })
        $process = Start-Process -FilePath $Praat -WorkingDirectory (Join-Path $plugin 'tests') `
            -ArgumentList @('--FULL-TRUST', '--no-plugins', '--no-pref-files', "`"--pref-dir=$preferences`"", '--run', "`"$script`"") `
            -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $ownedProcesses.Add($process)

        $buttonSequence = @()
        if ($case.ContainsKey('Buttons')) {
            $buttonSequence = $case.Buttons
        } else {
            $buttonSequence = @($case.Button)
        }
        foreach ($buttonName in $buttonSequence) {
            $helperProcess = $null
            for ($i = 0; $i -lt 200 -and $null -eq $helperProcess; $i++) {
                Start-Sleep -Milliseconds 100
                $child = Get-CimInstance Win32_Process |
                    Where-Object { $_.ExecutablePath -eq $helper -and $_.ProcessId -notin $helperProcessIds } |
                    Select-Object -First 1
                if ($null -ne $child) {
                    $helperProcess = Get-Process -Id $child.ProcessId -ErrorAction SilentlyContinue
                }
            }
            if ($null -eq $helperProcess) {
                throw "$($case.Mode): the Windows UI helper did not start."
            }
            $ownedProcesses.Add($helperProcess)

            $dialog = $null
            for ($i = 0; $i -lt 100 -and $null -eq $dialog; $i++) {
                Start-Sleep -Milliseconds 100
                $dialog = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
                    [System.Windows.Automation.TreeScope]::Children,
                    [System.Windows.Automation.Condition]::TrueCondition) |
                    Where-Object { $_.Current.ProcessId -eq $helperProcess.Id } |
                    Select-Object -First 1
            }
            if ($null -eq $dialog) {
                throw "$($case.Mode): the dialog window did not appear."
            }
            $elements = @($dialog.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                [System.Windows.Automation.Condition]::TrueCondition))
            foreach ($controlName in $case.RequiredControls) {
                $matchingControls = @($elements | Where-Object { $_.Current.Name -eq $controlName })
                if ($matchingControls.Count -eq 0) {
                    throw "$($case.Mode): expected UI control '$controlName' was not accessible."
                }
                $controlBounds = $matchingControls |
                    ForEach-Object { $_.Current.BoundingRectangle } |
                    Sort-Object -Property Width -Descending |
                    Select-Object -First 1
                if ($controlBounds.Width -lt 50 -or $controlBounds.Height -lt 12) {
                    throw "$($case.Mode): UI control '$controlName' is collapsed or clipped."
                }
            }
            if ($case.Mode -eq 'Table sparse saved tiers') {
                $expectedSelections = @(
                    @{ Label='Duration tier 1'; Value='vowel' },
                    @{ Label='Duration tier 2'; Value='syllable' },
                    @{ Label='Intensity tier 1'; Value='pitch' },
                    @{ Label='Intensity tier 2'; Value='utterance' },
                    @{ Label='Interval statistic'; Value='Maximum'; Occurrence=2 }
                )
                foreach ($expected in $expectedSelections) {
                    $occurrence = 1
                    if ($expected.ContainsKey('Occurrence')) { $occurrence = $expected.Occurrence }
                    $actual = Get-ComboSelection $dialog $expected.Label $occurrence
                    if ($actual -ne $expected.Value) {
                        throw "$($case.Mode): '$($expected.Label)' restored '$actual', expected '$($expected.Value)'."
                    }
                }
            }
            if ($case.Mode -eq 'Table optional tiers') {
                if ((Test-VisibleNamedControl $dialog 'Duration tier 2') -or
                    (Test-VisibleNamedControl $dialog 'Intensity tier 2')) {
                    throw 'Optional second-tier slots should start hidden.'
                }
                Select-ComboOption $dialog 'Duration tier 1' 'word'
                if (-not (Test-VisibleNamedControl $dialog 'Duration tier 2')) {
                    throw 'Selecting the first duration tier did not reveal the second slot.'
                }
                Select-ComboOption $dialog 'Duration tier 2' 'vowel'
                if (-not (Test-VisibleNamedControl $dialog 'Duration tier 3')) {
                    throw 'Selecting the second duration tier did not reveal the third slot.'
                }
                Select-ComboOption $dialog 'Duration tier 1' '(none)'
                if ((Test-VisibleNamedControl $dialog 'Duration tier 2') -or
                    (Test-VisibleNamedControl $dialog 'Duration tier 3')) {
                    throw 'Clearing the first duration tier did not hide later slots.'
                }
                Select-ComboOption $dialog 'Duration tier 1' 'word'
                Select-ComboOption $dialog 'Duration tier 2' 'vowel'
                Select-ComboOption $dialog 'Duration tier 3' 'syllable'

                Select-ComboOption $dialog 'Intensity tier 1' 'phrase'
                if (-not (Test-VisibleNamedControl $dialog 'Intensity tier 2')) {
                    throw 'Selecting the first intensity tier did not reveal the second slot.'
                }
                Select-ComboOption $dialog 'Intensity tier 1' '(none)'
                if (Test-VisibleNamedControl $dialog 'Intensity tier 2') {
                    throw 'Clearing the first intensity tier did not hide later slots.'
                }
                Select-ComboOption $dialog 'Intensity tier 1' 'phrase'
                Select-ComboOption $dialog 'Interval statistic' 'Minimum' 1
                Select-ComboOption $dialog 'Intensity tier 2' 'pitch'
                $pointMethod = Find-ComboByLabel $dialog 'Interval statistic' 2
                if ([PlotPrototypeNative]::IsWindowEnabled($pointMethod)) {
                    throw 'The interval statistic should be disabled for a point intensity tier.'
                }
                Select-ComboOption $dialog 'Intensity tier 3' 'utterance'
                if (-not (Test-VisibleNamedControl $dialog 'Intensity tier 3')) {
                    throw 'Selecting the second intensity tier did not reveal the third slot.'
                }
                Select-ComboOption $dialog 'Interval statistic' 'Maximum' 3
                Select-ComboOption $dialog 'Formants to tabulate' 'F1'
                $elements = Get-DialogElements $dialog
            }
            $button = $elements |
                Where-Object { $_.Current.Name -eq $buttonName } |
                Select-Object -First 1
            if ($null -eq $button) {
                $availableNames = ($elements | ForEach-Object { $_.Current.Name } |
                    Where-Object { $_ -ne "" } | Sort-Object -Unique) -join ', '
                throw "$($case.Mode): button '$buttonName' was not found. Available controls: $availableNames"
            }
            [PlotPrototypeNative]::SendMessage([IntPtr]$button.Current.NativeWindowHandle,
                0xF5, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
            $helperProcessIds += $helperProcess.Id
        }

        for ($i = 0; $i -lt 600 -and -not (Test-Path -LiteralPath $result); $i++) {
            Start-Sleep -Milliseconds 100
        }
        if (-not (Test-Path -LiteralPath $result)) {
            $details = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
            throw "$($case.Mode): the Praat test did not complete. $details"
        }
        if ((Get-Content -LiteralPath $result -Raw).Trim() -ne 'PASS') {
            throw "$($case.Mode): the Praat test returned an invalid completion marker."
        }
        if ($case.Mode -eq 'PitchPlus') {
            $savedSettings = Get-Content -LiteralPath (Join-Path $vars 'pitch_plus.var') -Raw
            if ($savedSettings -notmatch ('image_title\$\s+' + [regex]::Escape($expectedTitle))) {
                throw 'The Windows plot dialog did not preserve the image title correctly.'
            }
        }
        Write-Output "Passed: $($case.Mode)."
    }
    $temporaryTitles = Join-Path $plugin 'data\temp\plot-ui'
    if (Test-Path -LiteralPath $temporaryTitles) {
        $leftoverTitles = @(Get-ChildItem -LiteralPath $temporaryTitles -File)
        if ($leftoverTitles.Count -gt 0) {
            throw 'Temporary plot titles were not cleaned up after use.'
        }
    }
}
finally {
    foreach ($process in $ownedProcesses) {
        $process.Refresh()
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id
        }
    }
}
