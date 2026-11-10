sound = Create Sound from formula: "nested sound", 1, 0, 1, 8000, "0"
grid = To TextGrid: "word speaker", ""
Set interval text: 1, 1, "hello"
Set interval text: 2, 1, "AER"
selectObject: sound
plusObject: grid
runScript: "../plotScripts/windowsTablePrototype.praat"
assert numberOfSelected("Table") = 1
table = selected("Table")
rows = Get number of rows
columns = Get number of columns
word$ = Get value: 1, "word"
speaker$ = Get value: 1, "speaker"
assert rows = 1
assert columns = 4
assert word$ = "hello"
assert speaker$ = "AER"
removeObject: table, sound, grid
writeInfoLine: "Windows nested tiers test passed."
