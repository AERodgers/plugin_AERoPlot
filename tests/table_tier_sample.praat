form Sample tier reference test
    sentence TextGrid_path
endform

aeroPrototypeInclude = 1
grid = Read from file: textGrid_path$
ui.lowestTier$ = "Element"
ui.otherTiers$ = "Speaker,Sex,Type,Context,Rep,IPA,Segment"
ui.vowelDur$ = "6"
ui.baseTierTimeOnly = 1
ui.formants2tabulate = 4
@resolveTableTierSettings: grid
assert ui.vowelDur$ = "Segment"
@tiers2Table: grid, "'ui.lowestTier$','ui.otherTiers$'", "sampleResult"
selectObject: sampleResult
rows = Get number of rows
duration1 = Get value: 1, "Segment_dur"
duration2 = Get value: 2, "Segment_dur"
assert rows = 35
assert abs(duration1 - 0.172) < 0.0001
assert abs(duration2 - 0.172) < 0.0001
removeObject: sampleResult, grid
writeInfoLine: "Sample vowel duration test passed."

include nestedTiers2Table.praat
