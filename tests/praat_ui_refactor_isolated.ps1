param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory,
    [string]$PlotScripts = ''
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
if ($PlotScripts -eq '') {
    $PlotScripts = Join-Path $root 'plotScripts'
}
Copy-Item -LiteralPath $PlotScripts -Destination (Join-Path $plugin 'plotScripts') -Recurse
Copy-Item -LiteralPath (Join-Path $root 'tests') -Destination $plugin -Recurse
New-Item -ItemType Directory -Path (Join-Path $plugin 'data\temp') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $plugin 'data\vars') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $plugin 'data\palettes') -Force | Out-Null

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class NativeUiRefactorTest {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
}
'@

$process = $null
try {
    $cases = @(
        @{ Mode='PitchPlus'; Button='Draw & Exit' },
        @{ Mode='Spectrogram'; Button='Draw & Exit' },
        @{ Mode='Table'; Button='Exit' },
        @{ Mode='F1F2'; Button='Exit' },
        @{ Mode='Ladefoged'; Button='Exit' },
        @{ Mode='FormantsOverTime'; Button='Exit' }
    )
    foreach ($case in $cases) {
        $result = Join-Path $testRoot ($case.Mode + '.txt')
        $env:AEROPLOT_TEST_RESULT = $result
        $stdout = Join-Path $testRoot ($case.Mode + '.stdout.txt')
        $stderr = Join-Path $testRoot ($case.Mode + '.stderr.txt')
        $script = Join-Path $plugin 'tests\praat_ui_refactor_smoke.praat'
        $process = Start-Process -FilePath $Praat -WorkingDirectory (Join-Path $plugin 'tests') `
            -ArgumentList @('--new-send', '--no-plugins', '--no-pref-files', "`"--pref-dir=$preferences`"", "`"$script`"", $case.Mode) `
            -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $button = $null
        $availableNames = @()
        for ($i = 0; $i -lt 200 -and $null -eq $button -and -not $process.HasExited; $i++) {
            Start-Sleep -Milliseconds 100
            $windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
                [System.Windows.Automation.TreeScope]::Children,
                [System.Windows.Automation.Condition]::TrueCondition) |
                Where-Object { $_.Current.ProcessId -eq $process.Id }
            $availableNames = @()
            foreach ($window in $windows) {
                $elements = @($window.FindAll([System.Windows.Automation.TreeScope]::Descendants,
                    [System.Windows.Automation.Condition]::TrueCondition))
                $availableNames += @($window.Current.Name)
                $availableNames += @($elements | ForEach-Object { $_.Current.Name } |
                    Where-Object { $_ -ne '' } | Sort-Object -Unique)
                $button = $elements |
                    Where-Object { $_.Current.Name -eq $case.Button } | Select-Object -First 1
                if ($null -ne $button) { break }
            }
        }
        if ($null -eq $button) {
            $details = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
            throw "$($case.Mode): native button '$($case.Button)' not found. Controls: $($availableNames -join ', '). $details"
        }
        [NativeUiRefactorTest]::SendMessage([IntPtr]$button.Current.NativeWindowHandle,
            0xF5, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        for ($i = 0; $i -lt 600 -and -not (Test-Path -LiteralPath $result) -and -not $process.HasExited; $i++) {
            Start-Sleep -Milliseconds 100
        }
        if (-not (Test-Path -LiteralPath $result)) {
            $details = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
            throw "$($case.Mode): native interface test failed. $details"
        }
        if ((Get-Content -LiteralPath $result -Raw).Trim() -ne 'PASS') {
            throw "$($case.Mode): invalid completion marker."
        }
        Write-Output "Passed: native $($case.Mode)."
        if (-not $process.HasExited) { Stop-Process -Id $process.Id }
        $process = $null
    }
}
finally {
    if ($null -ne $process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id
    }
    Remove-Item Env:\AEROPLOT_TEST_RESULT -ErrorAction SilentlyContinue
}
