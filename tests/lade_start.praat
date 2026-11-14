form Isolated Ladefoged dialog test
    sentence Ready_path
endform

table = Create formant table (Peterson & Barney 1952)
other = Create Sound from formula: "other", 1, 0, 0.1, 8000, "0"
selectObject: table
runScript: "../plotScripts/ladPlot.praat"
assert numberOfSelected() = 1
selectObject: other
writeFileLine: ready_path$, table, tab$, other