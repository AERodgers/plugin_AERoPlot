aeroPrototypeInclude = 1
sound = Create Sound from formula: "intensity", 1, 0, 1, 16000,
... "(0.1+0.2*x)*sin(2*pi*200*x)"
grid = Create TextGrid: 0, 1, "syllable vowel points", "points"
Insert boundary: 1, 0.1
Insert boundary: 1, 0.9
Set interval text: 1, 2, "syl"
Insert boundary: 2, 0.2
Insert boundary: 2, 0.8
Set interval text: 2, 2, "vowel"
Insert point: 3, 0.3004, "a"
Insert point: 3, 0.7, "b"
Insert point: 3, 0.95, "outside"
Insert interval tier: 4, "speaker"
Set interval text: 4, 1, "speaker"
ui.lowestTier$ = "points"
ui.otherTiers$ = "vowel,syllable"
ui.vowelDur$ = "vowel"
ui.duration2$ = "syllable"
ui.duration3$ = "speaker"
ui.intensityTier1$ = "points"
ui.intensityTier2$ = "vowel"
ui.intensityTier3$ = "syllable"
ui.intensityMethod1 = 1
ui.intensityMethod2 = 2
ui.intensityMethod3 = 4
ui.intensityPitch = 100
ui.baseTierTimeOnly = 1
@resolveTableTierSettings: grid
@tiers2Table: grid, "'ui.lowestTier$','ui.otherTiers$'", "intensityResult"
@tableIntensity: sound, grid, intensityResult, "points"
selectObject: sound
expectedIntensity = To Intensity: 100, 0, "yes"
expectedPoint = Get value at time: 0.3004, "Cubic"
expectedMidpoint = Get value at time: 0.5, "Cubic"
expectedMax = Get maximum: 0.1, 0.9, "Parabolic"
selectObject: intensityResult
vowelDuration = Get value: 1, "vowel_dur"
syllableDuration = Get value: 1, "syllable_dur"
speakerDuration = Get value: 1, "speaker_dur"
assert abs(vowelDuration - 0.6) < 0.0001
assert abs(syllableDuration - 0.8) < 0.0001
assert abs(speakerDuration - 1) < 0.0001
point = Get value: 1, "points_intensity_dB"
midpoint = Get value: 1, "vowel_intensity_midpoint_dB"
maximum = Get value: 1, "syllable_intensity_maximum_dB"
assert abs(point - expectedPoint) <= 0.05000001
assert abs(midpoint - expectedMidpoint) <= 0.05000001
assert abs(maximum - expectedMax) <= 0.05000001
assert abs(10 * point - round(10 * point)) < 1e-8
assert abs(10 * midpoint - round(10 * midpoint)) < 1e-8
assert abs(10 * maximum - round(10 * maximum)) < 1e-8
unmatched = Get value: 3, "vowel_intensity_midpoint_dB"
assert unmatched = undefined
removeObject: intensityResult
for method from 1 to 4
    ui.intensityTier1$ = "vowel"
    ui.intensityTier2$ = ""
    ui.intensityTier3$ = ""
    ui.intensityMethod1 = method
    @tiers2Table: grid, "'ui.lowestTier$','ui.otherTiers$'", "intensityResult"
    @tableIntensity: sound, grid, intensityResult, "points"
    selectObject: expectedIntensity
    if method = 1
        expected = Get mean: 0.2, 0.8, "energy"
        column$ = "vowel_intensity_mean_dB"
    elsif method = 2
        expected = Get value at time: 0.5, "Cubic"
        column$ = "vowel_intensity_midpoint_dB"
    elsif method = 3
        expected = Get minimum: 0.2, 0.8, "Parabolic"
        column$ = "vowel_intensity_minimum_dB"
    else
        expected = Get maximum: 0.2, 0.8, "Parabolic"
        column$ = "vowel_intensity_maximum_dB"
    endif
    selectObject: intensityResult
    actual = Get value: 1, column$
    assert abs(actual - expected) <= 0.05000001
    assert abs(10 * actual - round(10 * actual)) < 1e-8
    removeObject: intensityResult
endfor
aeroSoftErrors = 1
ui.lowestTier$ = "vowel"
ui.otherTiers$ = ""
ui.vowelDur$ = ""
ui.duration2$ = ""
ui.intensityTier1$ = "points"
@resolveTableTierSettings: grid
assert index(resolveTableTierSettings.error$, "multiple points") > 0
ui.lowestTier$ = "points"
ui.vowelDur$ = "vowel"
ui.duration2$ = "vowel"
ui.intensityTier1$ = ""
@resolveTableTierSettings: grid
assert index(resolveTableTierSettings.error$, "only once") > 0
removeObject: {grid, sound, expectedIntensity}
writeInfoLine: "Table intensity tests passed."

include ../plotScripts/nestedTiers2Table.praat
