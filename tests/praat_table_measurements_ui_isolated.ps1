param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) { throw 'The test directory must not already exist.' }
$root = Split-Path -Parent $PSScriptRoot
$preferences = Join-Path ([IO.Path]::GetFullPath($TestDirectory)) 'preferences'
$plugin = Join-Path $preferences 'plugin_AERoPlot'
New-Item -ItemType Directory -Path $plugin -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'plotScripts') -Destination $plugin -Recurse
$script = Join-Path $plugin 'plotScripts\praat_table_measurements_ui.praat'
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'praat_table_measurements_ui.praat'))
$source = $source.Replace('include ../plotScripts/nestedTiers2Table.praat', 'include nestedTiers2Table.praat')
[IO.File]::WriteAllText($script, $source, (New-Object Text.UTF8Encoding($false)))

Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class PraatTableNative {
    private delegate bool Callback(IntPtr window, IntPtr context);
    [DllImport("user32.dll")] private static extern bool EnumWindows(Callback callback, IntPtr context);
    [DllImport("user32.dll")] private static extern bool EnumChildWindows(IntPtr parent, Callback callback, IntPtr context);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] private static extern int GetWindowText(IntPtr window, StringBuilder text, int length);
    [DllImport("user32.dll")] private static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
    private static string Text(IntPtr window) {
        var text = new StringBuilder(512);
        GetWindowText(window, text, text.Capacity);
        return text.ToString();
    }
    public static bool Click(int processId, string caption) {
        IntPtr button = IntPtr.Zero;
        EnumWindows((window, context) => {
            uint owner;
            GetWindowThreadProcessId(window, out owner);
            if (owner == processId && IsWindowVisible(window) &&
                Text(window).Contains("Convert nested textgrid tiers to data table")) {
                EnumChildWindows(window, (child, ignored) => {
                    if (IsWindowVisible(child) && Text(child) == caption) { button = child; return false; }
                    return true;
                }, IntPtr.Zero);
            }
            return button == IntPtr.Zero;
        }, IntPtr.Zero);
        if (button == IntPtr.Zero) return false;
        SendMessage(button, 0xF5, IntPtr.Zero, IntPtr.Zero);
        return true;
    }
}
'@

$result = Join-Path $TestDirectory 'result.txt'
$stdout = Join-Path $TestDirectory 'stdout.txt'
$stderr = Join-Path $TestDirectory 'stderr.txt'
$env:AEROPLOT_TEST_RESULT = $result
$process = $null
try {
    $process = Start-Process -FilePath $Praat -WorkingDirectory (Join-Path $plugin 'plotScripts') `
        -ArgumentList @('--FULL-TRUST', '--new-send', '--no-plugins', '--no-pref-files',
            "`"--pref-dir=$preferences`"", "`"$script`"") `
        -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $clicked = $false
    for ($i = 0; $i -lt 200 -and -not $clicked -and -not $process.HasExited; $i++) {
        Start-Sleep -Milliseconds 100
        $clicked = [PraatTableNative]::Click($process.Id, 'Convert to Table')
    }
    if (-not $clicked) { throw 'The native Convert to Table button did not appear.' }
    for ($i = 0; $i -lt 200 -and -not (Test-Path -LiteralPath $result) -and -not $process.HasExited; $i++) {
        Start-Sleep -Milliseconds 100
    }
    if (-not (Test-Path -LiteralPath $result)) {
        $details = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($stderr))
        throw "The native table test failed. $details"
    }
    if ((Get-Content -LiteralPath $result -Raw).Trim() -ne 'PASS') { throw 'Invalid result.' }
    Write-Output 'Native table measurement test passed.'
}
finally {
    if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
    Remove-Item Env:\AEROPLOT_TEST_RESULT -ErrorAction SilentlyContinue
}
