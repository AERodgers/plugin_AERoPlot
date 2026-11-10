sound = Create Sound from formula: "prototype sound", 1, 0, 1, 8000, "0"
grid = To TextGrid: "word", ""
Set interval text: 1, 1, "hello"
selectObject: sound
plusObject: grid
runScript: "../plotScripts/windowsTablePrototype.praat"
assert numberOfSelected("Table") = 1
table = selected("Table")
assert selected$("Table") = "aeroplot_table"
rows = Get number of rows
columns = Get number of columns
word$ = Get value: 1, "word"
start = Get value: 1, "word_tmin"
end = Get value: 1, "word_tmax"
assert rows = 1
assert columns = 3
assert word$ = "hello"
assert start = 0
assert end = 1
selectObject: sound
plusObject: grid
assert numberOfSelected() = 2
removeObject: table, sound, grid
writeInfoLine: "Windows Table prototype test passed."
