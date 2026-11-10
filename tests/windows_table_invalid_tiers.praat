sound = Create Sound from formula: "invalid tier", 1, 0, 1, 8000, "0"
grid = To TextGrid: "word", ""
Set tier name: 1, "bad,name"
selectObject: sound
plusObject: grid
asserterror This prototype cannot use
runScript: "../plotScripts/windowsTablePrototype.praat"
assert selected("Sound") = sound
assert selected("TextGrid") = grid
assert numberOfSelected("Table") = 0
removeObject: sound, grid
writeInfoLine: "Windows Table invalid tier test passed."
