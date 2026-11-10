sound = Create Sound from formula: "élan", 1, 0, 1, 8000, "0"
grid = To TextGrid: "word", ""
Set tier name: 1, "voyelle_é"
Set interval text: 1, 1, "café"
selectObject: sound
plusObject: grid
runScript: "../plotScripts/windowsTablePrototype.praat"
assert numberOfSelected("Table") = 1
table = selected("Table")
label$ = Get value: 1, "voyelle_é"
assert label$ = "café"
removeObject: table, sound, grid
writeInfoLine: "Windows Table Unicode test passed."
