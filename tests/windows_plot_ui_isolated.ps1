param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory
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

$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    throw 'The .NET Framework compiler was not found.'
}
$bin = Join-Path $plugin 'windows-ui\bin'
New-Item -ItemType Directory -Path $bin -Force | Out-Null
$helper = Join-Path $bin 'AERoPlotWindowsUI.exe'
& $compiler /nologo /target:winexe /optimize+ /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "/out:$helper" (Join-Path $root 'windows-ui\TableUI.cs') (Join-Path $root 'windows-ui\PlotUI.cs') (Join-Path $root 'windows-ui\TablePlotUI.cs')
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to compile the Windows UI helper.'
}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PlotPrototypeNative {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
}
'@

$ownedProcesses = New-Object 'System.Collections.Generic.List[System.Diagnostics.Process]'
try {
    $cases = @(
        @{ Mode='Table'; Script='windows_table_prototype.praat'; Button='Create Table' },
        @{ Mode='PitchPlus'; Script='windows_pitch_plus_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Plot type', 'Minimum F0 (Hz)', 'Secondary parameter') },
        @{ Mode='PitchPlus redraw'; Script='windows_pitch_plus_ui.praat'; Buttons=@('Draw', 'Draw  Exit') },
        @{ Mode='PitchPlus without TextGrid'; Script='windows_pitch_plus_sound_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Plot type', 'Minimum F0 (Hz)') },
        @{ Mode='Spectrogram'; Script='windows_spectrogram_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Draw sound waveform', 'Window width (inches)', 'Crop to interval tier', 'Display tier') },
        @{ Mode='Spectrogram without TextGrid'; Script='windows_spectrogram_sound_ui.praat'; Button='Draw  Exit'; RequiredControls=@('Draw sound waveform', 'Window width (inches)') },
        @{ Mode='PitchPlus cancellation'; Script='windows_pitch_plus_ui.praat'; Button='Cancel' }
    )
    foreach ($case in $cases) {
        $result = Join-Path $testRoot ($case.Mode.Replace(' ', '-') + '.txt')
        $env:AEROPLOT_TEST_RESULT = $result
        $stdout = Join-Path $testRoot ($case.Mode.Replace(' ', '-') + '.stdout.txt')
        $stderr = Join-Path $testRoot ($case.Mode.Replace(' ', '-') + '.stderr.txt')
        $script = Join-Path $plugin ('tests\' + $case.Script)
        $helperProcessIds = @(Get-CimInstance Win32_Process |
            Where-Object { $_.ExecutablePath -eq $helper } |
            ForEach-Object { $_.ProcessId })
        $process = Start-Process -FilePath $Praat -WorkingDirectory (Join-Path $plugin 'tests') `
            -ArgumentList @('--no-plugins', '--no-pref-files', "`"--pref-dir=$preferences`"", '--run', "`"$script`"") `
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
