param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) {
    throw 'The test directory must not already exist.'
}
$testRoot = [IO.Path]::GetFullPath($TestDirectory)
New-Item -ItemType Directory -Path $testRoot | Out-Null
$root = Split-Path -Parent $PSScriptRoot
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw 'The .NET Framework compiler was not found.' }
$helper = Join-Path $testRoot 'AsyncProbe.exe'
& $compiler /nologo /target:winexe /main:AsyncUiProbe /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "/out:$helper" (Join-Path $root 'windows-ui\TableUI.cs') (Join-Path $root 'windows-ui\PlotUI.cs') (Join-Path $PSScriptRoot 'async_ui_probe.cs')
if ($LASTEXITCODE -ne 0) { throw 'Unable to compile the async probe.' }

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class AsyncProbeNative {
    public delegate bool EnumCallback(IntPtr window, IntPtr context);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumCallback callback, IntPtr context);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr window, StringBuilder name, int length);
    [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr SendMessageTimeout(IntPtr window, uint message, IntPtr wparam, IntPtr lparam, uint flags, uint timeout, out IntPtr result);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
}
'@

function Wait-File([string]$Path) {
    for ($i=0; $i -lt 200; $i++) {
        if (Test-Path -LiteralPath $Path) { return }
        Start-Sleep -Milliseconds 100
    }
    throw "Timed out waiting for $Path"
}
function Get-ShellWindow([int]$ProcessId) {
    $script:probeWindow = [IntPtr]::Zero
    $callback = [AsyncProbeNative+EnumCallback]{
        param($window, $context)
        $processIdFound = [uint32]0
        [AsyncProbeNative]::GetWindowThreadProcessId($window, [ref]$processIdFound) | Out-Null
        $name = New-Object Text.StringBuilder 256
        [AsyncProbeNative]::GetClassName($window, $name, $name.Capacity) | Out-Null
        if ($processIdFound -eq $ProcessId -and $name.ToString() -like 'PraatShell1 *') {
            $script:probeWindow = $window
            return $false
        }
        return $true
    }
    [AsyncProbeNative]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null
    if ($script:probeWindow -eq [IntPtr]::Zero) { throw "Praat shell for process $ProcessId not found." }
    return $script:probeWindow
}
function Send-IsolatedScript($Instance, [string]$Script) {
    if ($Instance.Process.HasExited) { throw 'The target Praat process has exited.' }
    $window = Get-ShellWindow $Instance.Process.Id
    $message = Join-Path $Instance.Directory 'Message.txt'
    [IO.File]::WriteAllText($message, $Script, (New-Object Text.UTF8Encoding($false)))
    $result = [IntPtr]::Zero
    $sent = [AsyncProbeNative]::SendMessageTimeout($window, 0x8000, [IntPtr]::Zero, [IntPtr]::Zero, 2, 10000, [ref]$result)
    if ($sent -eq [IntPtr]::Zero) { throw 'The target Praat window did not acknowledge the message.' }
}
function Start-Instance([string]$Name) {
    $directory = Join-Path $testRoot $Name
    New-Item -ItemType Directory -Path $directory | Out-Null
    $exe = Join-Path $directory "$Name.exe"
    Copy-Item -LiteralPath $Praat -Destination $exe
    $ready = Join-Path $directory 'ready.txt'
    $result = Join-Path $directory 'result.txt'
    $completion = Join-Path $directory 'completion.txt'
    $script = Join-Path $PSScriptRoot 'async_probe_start.praat'
    $process = Start-Process -FilePath $exe -ArgumentList @('--new-send','--no-plugins','--no-pref-files',"`"--pref-dir=$directory`"","`"$script`"","`"$helper`"","`"$result`"","`"$ready`"",$Name) -PassThru
    $instances.Add($process)
    $dialog = $null
    for ($i=0; $i -lt 100 -and $null -eq $dialog; $i++) {
        Start-Sleep -Milliseconds 100
        $child = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($process.Id)" |
            Where-Object { $_.ExecutablePath -eq $helper } | Select-Object -First 1
        if ($null -ne $child) {
            $dialog = Get-Process -Id $child.ProcessId -ErrorAction SilentlyContinue
        }
    }
    if ($null -eq $dialog) { throw 'The async dialog process did not appear.' }
    $instances.Add($dialog)
    Wait-File $ready
    for ($i=0; $i -lt 100; $i++) {
        $dialog.Refresh()
        if ($dialog.MainWindowHandle -ne 0) { break }
        Start-Sleep -Milliseconds 100
    }
    if ($dialog.MainWindowHandle -eq 0) { throw 'The async dialog window did not appear.' }
    return @{ Process=$process; Dialog=$dialog; Directory=$directory; Ready=$ready; Result=$result; Completion=$completion }
}
function Click-Dialog($Instance, [string]$ButtonName) {
    $window = [System.Windows.Automation.AutomationElement]::FromHandle($Instance.Dialog.MainWindowHandle)
    $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $ButtonName)
    $button = $window.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
    if ($null -eq $button) { throw "Dialog button $ButtonName not found." }
    [AsyncProbeNative]::SendMessage([IntPtr]$button.Current.NativeWindowHandle, 0xF5, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    Wait-File $Instance.Result
}
function Complete-Instance($Instance) {
    $callback = (Join-Path $PSScriptRoot 'async_probe_callback.praat').Replace('\','/')
    $ready = $Instance.Ready.Replace('\','/')
    $result = $Instance.Result.Replace('\','/')
    $completion = $Instance.Completion.Replace('\','/')
    Send-IsolatedScript $Instance "runScript: `"$callback`", `"$ready`", `"$result`", `"$completion`"`n"
    Wait-File $Instance.Completion
}
function Expect-MissingObjectError($Instance) {
    $callback = (Join-Path $PSScriptRoot 'async_probe_callback.praat').Replace('\','/')
    $ready = $Instance.Ready.Replace('\','/')
    $result = $Instance.Result.Replace('\','/')
    $completion = $Instance.Completion.Replace('\','/')
    $script = "runScript: `"$callback`", `"$ready`", `"$result`", `"$completion`"`n"
    [IO.File]::WriteAllText((Join-Path $Instance.Directory 'Message.txt'), $script, (New-Object Text.UTF8Encoding($false)))
    $window = Get-ShellWindow $Instance.Process.Id
    if (-not [AsyncProbeNative]::PostMessage($window, 0x8000, [IntPtr]::Zero, [IntPtr]::Zero)) { throw 'Failed to post the missing-object test.' }
    $errorWindow = $null
    for ($i=0; $i -lt 100 -and $null -eq $errorWindow; $i++) {
        Start-Sleep -Milliseconds 100
        $rootWindow = [System.Windows.Automation.AutomationElement]::RootElement
        $errorWindow = $rootWindow.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition) |
            Where-Object { $_.Current.ProcessId -eq $Instance.Process.Id -and $_.Current.Name -eq 'Message' } |
            Select-Object -First 1
    }
    if ($null -eq $errorWindow) { throw 'Expected a visible Praat error after removing an input object.' }
    $contents = $errorWindow.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition) |
        ForEach-Object { $_.Current.Name }
    if (($contents -join ' ') -notmatch 'object|Object') { throw 'The expected missing-object error was not shown.' }
    if (Test-Path -LiteralPath $Instance.Completion) { throw 'A Table was created after removing an input object.' }
}
$instances = New-Object 'System.Collections.Generic.List[System.Diagnostics.Process]'
try {
    $one = Start-Instance 'AeroProbeOne'
    $two = Start-Instance 'AeroProbeTwo'
    Send-IsolatedScript $one "Create Sound from formula: `"selection_changed`", 1, 0, 0.1, 8000, `"0`"`n"
    Click-Dialog $one 'Create Table'
    Click-Dialog $two 'Create Table'
    Complete-Instance $one
    if (-not ((Get-Content -LiteralPath $one.Completion -Raw) -match '^created\s+\d+\s+\d+\s+\d+\s+AeroProbeOne')) { throw 'The first instance did not create its Table.' }
    if (Test-Path -LiteralPath $two.Completion) { throw 'The callback reached the wrong instance.' }
    Complete-Instance $two
    if (-not ((Get-Content -LiteralPath $two.Completion -Raw) -match '^created\s+\d+\s+\d+\s+\d+\s+AeroProbeTwo')) { throw 'The second instance did not create its Table.' }
    $cancelled = Start-Instance 'AeroProbeCancel'
    Click-Dialog $cancelled 'Cancel'
    Complete-Instance $cancelled
    if ((Get-Content -LiteralPath $cancelled.Completion -Raw).Trim() -ne 'cancelled') { throw 'Cancellation was not preserved.' }
    $missing = Start-Instance 'AeroProbeMissing'
    $ids = (Get-Content -LiteralPath $missing.Ready -Raw).Trim() -split '\s+'
    Send-IsolatedScript $missing "removeObject: $($ids[1])`n"
    Click-Dialog $missing 'Create Table'
    Expect-MissingObjectError $missing
    $missingSound = Start-Instance 'AeroProbeMissingSound'
    $ids = (Get-Content -LiteralPath $missingSound.Ready -Raw).Trim() -split '\s+'
    Send-IsolatedScript $missingSound "removeObject: $($ids[0])`n"
    Click-Dialog $missingSound 'Create Table'
    Expect-MissingObjectError $missingSound
    $closed = Start-Instance 'AeroProbeClosed'
    Stop-Process -Id $closed.Process.Id
    $closed.Process.WaitForExit()
    Click-Dialog $closed 'Create Table'
    $refused = $false
    try { Complete-Instance $closed } catch {
        if ($_.Exception.Message -ne 'The target Praat process has exited.') { throw }
        $refused = $true
    }
    if (-not $refused -or (Test-Path -LiteralPath $closed.Completion)) { throw 'Closed Praat was not detected.' }
    Write-Output 'Passed: responsive Praat, changed selection, overlapping dialogs in isolated instances, cancellation, removed input errors, and closed-Praat detection.'
} finally {
    foreach ($process in $instances) {
        $process.Refresh()
        if (-not $process.HasExited) { Stop-Process -Id $process.Id }
    }
}
