form Sample tier reference test
    sentence TextGrid_path
endform

aeroPrototypeInclude = 1
grid = Read from file: textGrid_path$
ui.lowestTier$ = "Element"
ui.otherTiers$ = "Speaker,Sex,Type,Context,Rep,IPA,Segment"
ui.formantTier$ = "7"
ui.vowelDur$ = "6"
ui.baseTierTimeOnly = 1
ui.formants2tabulate = 4
@resolveTableTierSettings: grid
assert ui.formantTier$ = "IPA"
assert ui.vowelDur$ = "Segment"
@tiers2Table: grid, "'ui.lowestTier$','ui.otherTiers$'", "sampleResult"
selectObject: sampleResult
rows = Get number of rows
duration1 = Get value: 1, "Vowel.dur"
duration2 = Get value: 2, "Vowel.dur"
assert rows = 35
assert duration1 = 172
assert duration2 = 172
removeObject: sampleResult, grid
writeInfoLine: "Sample vowel duration test passed."

include nestedTiers2Table.praat
