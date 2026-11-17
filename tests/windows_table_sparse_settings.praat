sound = Create Sound from formula: "sparse saved tiers", 1, 0, 1, 8000, "0"
grid = To TextGrid: "word vowel syllable phrase utterance pitch", "pitch"
Set interval text: 1, 1, "word"
Set interval text: 2, 1, "vowel"
Set interval text: 3, 1, "syllable"
Set interval text: 4, 1, "phrase"
Set interval text: 5, 1, "utterance"
Insert point: 6, 0.5, "pitch"
selectObject: sound
plusObject: grid
runScript: "../plotScripts/windowsTablePrototype.praat"
assert numberOfSelected("Table") = 1
table = selected("Table")
columns = Get number of columns
vowelDurationFound = 0
syllableDurationFound = 0
pitchIntensityFound = 0
utteranceIntensityFound = 0
for col to columns
    label$ = Get column label: col
    if label$ = "vowel_dur"
        vowelDurationFound = 1
    elsif label$ = "syllable_dur"
        syllableDurationFound = 1
    elsif label$ = "pitch_intensity_dB"
        pitchIntensityFound = 1
    elsif label$ = "utterance_intensity_maximum_dB"
        utteranceIntensityFound = 1
    endif
endfor
assert vowelDurationFound = 1
assert syllableDurationFound = 1
assert pitchIntensityFound = 1
assert utteranceIntensityFound = 1
removeObject: table, sound, grid
result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
writeFileLine: result$, "PASS"
