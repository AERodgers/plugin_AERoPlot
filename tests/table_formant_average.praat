# Interval base tiers average the defined formant samples across the whole interval.
aeroPrototypeInclude = 1
ui.baseTierTimeOnly = 1
ui.vowelDur$ = ""

sound = Create Sound as tone complex: "tone", 0, 3, 44100, "cosine", 120, 0, 0, 0
grid = Create TextGrid: 0, 3, "Seg", ""
Insert boundary: 1, 0.5
Insert boundary: 1, 2.5
Insert boundary: 1, 2.505
Set interval text: 1, 2, "long"
Set interval text: 1, 4, "tiny"

@tiers2Table: grid, "Seg", "avgTable"
selectObject: avgTable
numRows = Get number of rows
assert numRows = 2
@formantsSought: sound, avgTable, "Seg_tmin,Seg_tmax", 0, 2, 5000, 5, 0.025, 50, "Hertz"

# Independent average over every 0.00625 s step of the 2 s interval (321 samples).
selectObject: sound
formant = noprogress To Formant (burg): 0.00625, 5, 5000, 0.025, 50
total = 0
count = 0
for step from 0 to 320
    value = Get value at time: 1, 0.5 + step * 0.00625, "Hertz", "Linear"
    if value <> undefined
        total += value
        count += 1
    endif
endfor
assert count > 100
expected = total / count
removeObject: formant

selectObject: avgTable
longF1$ = Get value: 1, "F1"
longF1 = number(longF1$)
assert abs(longF1 - expected) <= 1

# An interval shorter than one step is sampled once at its midpoint and must not fail.
tinyF1$ = Get value: 2, "F1"
assert tinyF1$ <> ""

removeObject: avgTable, grid, sound
writeInfoLine: "Formant averaging test passed."

include ../plotScripts/nestedTiers2Table.praat
