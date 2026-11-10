sound = Create Sound from formula: "cancel sound", 1, 0, 1, 8000, "0"
grid = To TextGrid: "word", ""
selectObject: sound
plusObject: grid
runScript: "../plotScripts/windowsTablePrototype.praat"
assert numberOfSelected() = 2
assert selected("Sound") = sound
assert selected("TextGrid") = grid
assert numberOfSelected("Table") = 0
removeObject: sound, grid
writeInfoLine: "Windows Table cancellation test passed."
