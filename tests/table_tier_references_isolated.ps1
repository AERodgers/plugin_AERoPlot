param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory,
    [string]$SampleTextGrid = ''
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
$scripts = Join-Path $testRoot 'plotScripts'
Copy-Item -LiteralPath (Join-Path $root 'plotScripts') -Destination $scripts -Recurse
foreach ($name in @('table_tier_reference_error.praat', 'table_tier_sample.praat')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $scripts $name)
}
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'table_tier_references.praat'))
$source = $source.Replace('include ../plotScripts/nestedTiers2Table.praat', 'include nestedTiers2Table.praat')
[IO.File]::WriteAllText((Join-Path $scripts 'table_tier_references.praat'), $source, (New-Object Text.UTF8Encoding($false)))
$source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'table_formant_average.praat'))
$source = $source.Replace('include ../plotScripts/nestedTiers2Table.praat', 'include nestedTiers2Table.praat')
[IO.File]::WriteAllText((Join-Path $scripts 'table_formant_average.praat'), $source, (New-Object Text.UTF8Encoding($false)))

$cases = @(
    @{ Script='table_tier_references.praat'; Marker='Table tier reference tests passed.'; Args=@() },
    @{ Script='table_formant_average.praat'; Marker='Formant averaging test passed.'; Args=@() }
)
if ($SampleTextGrid -ne '') {
    if (-not (Test-Path -LiteralPath $SampleTextGrid)) {
        throw 'The sample TextGrid was not found.'
    }
    $cases += @{ Script='table_tier_sample.praat'; Marker='Sample vowel duration test passed.'; Args=@($SampleTextGrid) }
}
foreach ($case in $cases) {
    $stdout = Join-Path $testRoot ($case.Script + '.stdout.txt')
    $stderr = Join-Path $testRoot ($case.Script + '.stderr.txt')
    $script = Join-Path $scripts $case.Script
    $arguments = @('--no-plugins', '--no-pref-files', '--run', "`"$script`"")
    foreach ($arg in $case.Args) { $arguments += "`"$arg`"" }
    $process = Start-Process -FilePath $Praat -ArgumentList $arguments -PassThru -Wait `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $output = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($stdout))
    $errors = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($stderr))
    if ($process.ExitCode -ne 0 -or $output -notlike ('*' + $case.Marker + '*') -or $errors) {
        throw "$($case.Script) failed. $errors $output"
    }
    Write-Output $case.Marker
}
