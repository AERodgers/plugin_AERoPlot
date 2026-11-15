form Isolated formants-over-time dialog test
    sentence Ready_path
endform

table = Create Table with column names: "aer_ni_i", 4,
... "Context Element Rep Element_t F1 F2 F3"
for row to 4
    Set string value: row, "Context", "vowel"
    Set string value: row, "Element", string$(1 + (row - 1) mod 2)
    Set string value: row, "Rep", string$(1 + floor((row - 1) / 2))
    Set numeric value: row, "Element_t", row * 0.1
    Set numeric value: row, "F1", 500 + row * 10
    Set numeric value: row, "F2", 1500 + row * 10
    Set numeric value: row, "F3", 2500 + row * 10
endfor
other = Create Sound from formula: "other", 1, 0, 0.1, 8000, "0"
selectObject: table
runScript: "../plotScripts/fotPlot.praat"
assert numberOfSelected() = 1
selectObject: other
writeFileLine: ready_path$, table, tab$, other
