clearinfo
aeroPrototypeInclude = 1
result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
sound = Create Sound from formula: "native table", 1, 0, 1, 16000, "0.2*sin(2*pi*200*x)"
grid = Create TextGrid: 0, 1, "word vowel points", "points"
Set interval text: 1, 1, "word"
Set interval text: 2, 1, "vowel"
Insert point: 3, 0.3, "a"
Insert point: 3, 0.7, "b"
ui.soundID$ = string$(sound)
ui.gridID$ = string$(grid)
ui.output$ = "test_table"
ui.lowestTier$ = "points"
ui.otherTiers$ = "vowel,word"
ui.baseTierTimeOnly = 1
ui.vowelDur$ = "word"
ui.duration2$ = "vowel"
ui.duration3$ = ""
ui.intensityTier1$ = "points"
ui.intensityTier2$ = "vowel"
ui.intensityTier3$ = "word"
ui.intensityMethod1 = 1
ui.intensityMethod2 = 1
ui.intensityMethod3 = 3
ui.intensityPitch = 100
ui.formants2tabulate = 1
ui.scale = 1
ui.timeStep = 0
ui.maxFormantHz = 5000
ui.numFormants = 5
ui.windowLen = 0.025
ui.preEmph = 50
overwriteVars.all = 0
@ui
assert ui.duration2$ = "vowel"
assert ui.intensityTier3$ = "word"
assert ui.intensityMethod3 = 3
@resolveTableTierSettings: grid
@tiers2Table: grid, "'ui.lowestTier$','ui.otherTiers$'", "test_table"
@tableIntensity: sound, grid, test_table, ui.lowestTier$
selectObject: "Table test_table"
table = selected("Table")
rows = Get number of rows
assert rows = 2
duration = Get value: 1, "word_dur"
assert abs(duration - 1) < 1e-10
duration = Get value: 1, "vowel_dur"
assert abs(duration - 1) < 1e-10
point = Get value: 1, "points_intensity_dB"
assert point != undefined
mean = Get value: 1, "vowel_intensity_mean_dB"
assert mean != undefined
minimum = Get value: 1, "word_intensity_minimum_dB"
assert minimum != undefined
removeObject: table, sound, grid
writeFileLine: result$, "PASS"

include ../plotScripts/nestedTiers2Table.praat
