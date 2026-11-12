param(
    [Parameter(Mandatory=$true)][string]$Praat,
    [Parameter(Mandatory=$true)][string]$TestDirectory,
    [Parameter(Mandatory=$true)][string]$SampleDirectory
)
# Runs the command-line form interface (cli_*.praat) against the sample files.
# Expects the sample TextGrid tiers: 1 Speaker ... 6 Segment, 7 IPA, 8 Element.
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $TestDirectory) { throw 'The test directory must not already exist.' }
$testRoot = [IO.Path]::GetFullPath($TestDirectory)
New-Item -ItemType Directory -Path $testRoot | Out-Null
$root = Split-Path -Parent $PSScriptRoot
$scripts = Join-Path $testRoot 'plotScripts'
Copy-Item -LiteralPath (Join-Path $root 'plotScripts') -Destination $scripts -Recurse
$pref = Join-Path $testRoot 'pref'
New-Item -ItemType Directory -Path $pref | Out-Null
$grid = Join-Path $SampleDirectory 'AER_NI_I.TextGrid'
$wav = Join-Path $SampleDirectory 'AER_NI_I.wav'
$out = Join-Path $testRoot 'out'
New-Item -ItemType Directory -Path $out | Out-Null

function Invoke-Cli($script, $arguments) {
    $n = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $so = Join-Path $testRoot "$n.out"; $se = Join-Path $testRoot "$n.err"
    $a = @('--no-plugins', '--no-pref-files', "`"--pref-dir=$pref`"", '--run', "`"$(Join-Path $scripts $script)`"")
    foreach ($x in $arguments) { $a += "`"$x`"" }
    $p = Start-Process -FilePath $Praat -ArgumentList $a -PassThru -Wait -RedirectStandardOutput $so -RedirectStandardError $se
    $text = [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($so)) + [Text.Encoding]::Unicode.GetString([IO.File]::ReadAllBytes($se))
    [pscustomobject]@{ Code = $p.ExitCode; Text = $text }
}
function Assert-True($ok, $name, $detail) {
    if (-not $ok) { throw "FAILED: $name`n$detail" }
    Write-Host "Passed: $name."
}

# Table: success, tier by number, optional off values
$table = Join-Path $out 't.Table'
$r = Invoke-Cli 'cli_table.praat' @($grid, $wav, $table, '0', '8', '1, 2, 3, 4, 5, 6, 7', '1', 'F1 and F2', '7', '6', 'Hertz', '0', '5000', '5', '0.025', '50')
Assert-True (($r.Code -eq 0) -and (Test-Path $table)) 'Table success' $r.Text
$header = (Get-Content -LiteralPath $table -TotalCount 1)
Assert-True (($header -match 'Vowel\.dur') -and ($header -match 'F1') -and ($header -match 'F2')) 'Table columns' $header

$r = Invoke-Cli 'cli_table.praat' @($grid, $wav, $table, '0', '8', '1, 2, 3, 4, 5, 6, 7', '1', 'F1 and F2', '7', '6', 'Hertz', '0', '5000', '5', '0.025', '50')
Assert-True (($r.Code -ne 0) -and ($r.Text -match 'exist|overwrite')) 'Table refuses overwrite' $r.Text

$r = Invoke-Cli 'cli_table.praat' @($grid, $wav, $table, '1', '8', '1, 2, 3, 4, 5, 6, 7', '1', 'F1 and F2', 'NONE', 'null', 'Hertz', '0', '5000', '5', '0.025', '50')
Assert-True (($r.Code -eq 0) -and ((Get-Content -LiteralPath $table -TotalCount 1) -notmatch 'Vowel\.dur')) 'Table off values and overwrite' $r.Text

$r = Invoke-Cli 'cli_table.praat' @((Join-Path $out 'missing.TextGrid'), $wav, (Join-Path $out 'x.Table'), '0', '8', '1', '1', 'F1', 'none', 'none', 'Hertz', '0', '5000', '5', '0.025', '50')
Assert-True (($r.Code -ne 0) -and -not (Test-Path (Join-Path $out 'x.Table'))) 'Table missing TextGrid' $r.Text

$r = Invoke-Cli 'cli_table.praat' @($grid, 'none', (Join-Path $out 'y.Table'), '0', '8', '1', '1', 'F1', 'none', 'none', 'Hertz', '0', '5000', '5', '0.025', '50')
Assert-True (($r.Code -ne 0) -and -not (Test-Path (Join-Path $out 'y.Table'))) 'Table formants need a Sound' $r.Text

$r = Invoke-Cli 'cli_table.praat' @($grid, $wav, (Join-Path $out 'z.Table'), '0', 'NoSuchTier', '1', '1', 'None', 'none', 'none', 'Hertz', '0', '5000', '5', '0.025', '50')
Assert-True (($r.Code -ne 0) -and -not (Test-Path (Join-Path $out 'z.Table'))) 'Table unknown tier' $r.Text

# PitchPlus and Spectrogram: success and error cases
$plotArgs = { param($png, $overwrite, $tg) @($wav, $tg, $png, $overwrite, '300 dpi', 'none', '999', '1', '0', '8', '60', '400', '30', '90', 'F0 only', 'Semitones re 1 Hz', 'Cepstral Peak Prominence', 'Times', 'none', 'none', 'Times', '0') }
$specArgs = { param($png, $overwrite, $tg) @($wav, $tg, $png, $overwrite, '300 dpi', 'none', '0', '8', 'Times', 'none', '7', 'Times', '0') }
$png = Join-Path $out 'p.png'
$r = Invoke-Cli 'cli_pitch_plus.praat' (& $plotArgs $png '0' $grid)
Assert-True (($r.Code -eq 0) -and (Test-Path $png) -and ((Get-Item $png).Length -gt 1000)) 'PitchPlus success' $r.Text
$r = Invoke-Cli 'cli_pitch_plus.praat' (& $plotArgs $png '0' $grid)
Assert-True ($r.Code -ne 0) 'PitchPlus refuses overwrite' $r.Text
$r = Invoke-Cli 'cli_pitch_plus.praat' (& $plotArgs $png '1' 'none')
Assert-True ($r.Code -eq 0) 'PitchPlus without TextGrid and with overwrite' $r.Text
$r = Invoke-Cli 'cli_pitch_plus.praat' (& $plotArgs (Join-Path $out 'q.png') '0' (Join-Path $out 'missing.TextGrid'))
Assert-True (($r.Code -ne 0) -and -not (Test-Path (Join-Path $out 'q.png'))) 'PitchPlus missing TextGrid' $r.Text

$spec = Join-Path $out 's.png'
$r = Invoke-Cli 'cli_spectrogram.praat' (& $specArgs $spec '0' $grid)
Assert-True (($r.Code -eq 0) -and (Test-Path $spec)) 'Spectrogram success' $r.Text

Write-Host 'Command-line interface tests passed.'
