param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory
)
# Run with Praat 7 or newer, without granting full trust.
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) { throw 'The test directory must not already exist.' }
if (-not (Test-Path -LiteralPath $Praat)) { throw 'The Praat executable was not found.' }
$root = Split-Path -Parent $PSScriptRoot
$preferences = Join-Path ([IO.Path]::GetFullPath($TestDirectory)) 'preferences'
$plugin = Join-Path $preferences 'plugin_AERoPlot'
New-Item -ItemType Directory -Path $plugin -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'setup.praat') -Destination $plugin
Copy-Item -LiteralPath (Join-Path $root 'plotScripts') -Destination $plugin -Recurse
Copy-Item -LiteralPath (Join-Path $root 'windows-ui') -Destination $plugin -Recurse
$setupRunner = Join-Path $plugin 'test_setup.praat'
[IO.File]::WriteAllText($setupRunner,
    "include setup.praat`nbeginPause: `"AEROPLOT setup complete`"`nendPause: `"OK`", 1`n",
    (New-Object Text.UTF8Encoding($false)))

Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class PraatStartupWindows {
    private delegate bool Callback(IntPtr window, IntPtr context);
    [DllImport("user32.dll")] private static extern bool EnumWindows(Callback callback, IntPtr context);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] private static extern int GetWindowText(IntPtr window, StringBuilder text, int length);
    public static string[] Titles(int processId) {
        var titles = new List<string>();
        EnumWindows((window, context) => {
            uint owner;
            GetWindowThreadProcessId(window, out owner);
            if (owner == processId && IsWindowVisible(window)) {
                var text = new StringBuilder(512);
                GetWindowText(window, text, text.Capacity);
                titles.Add(text.ToString());
            }
            return true;
        }, IntPtr.Zero);
        return titles.ToArray();
    }
}
'@

$process = $null
try {
    $process = Start-Process -FilePath $Praat -ArgumentList @(
        '--new-send', '--no-plugins', '--no-pref-files',
        "`"--pref-dir=$preferences`"", "`"$setupRunner`"") -PassThru
    $titles = @()
    for ($i = 0; $i -lt 100; $i++) {
        if ($process.HasExited) { throw 'Praat exited during startup.' }
        Start-Sleep -Milliseconds 100
        $titles = @([PraatStartupWindows]::Titles($process.Id))
        if ($titles -match 'Praat Trust window') { throw 'Praat requested trust during startup.' }
        if ($titles -match 'AEROPLOT setup complete') { break }
    }
    if (-not ($titles -match 'AEROPLOT setup complete')) {
        throw "The setup script did not finish: $titles"
    }
    Write-Output 'Praat started without a trust prompt.'
}
finally {
    if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
}
