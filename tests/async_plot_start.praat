form Isolated asynchronous plot test
    sentence Ready_path
endform

sound = Create Sound from formula: "PitchPlus async test", 1, 0, 61, 8000, "0.2*sin(2*pi*120*x)"
grid = Create TextGrid: 0, 61, "words points", "points"
selectObject: grid
Insert boundary: 1, 0.1
Insert boundary: 1, 60.9
Set interval text: 1, 2, "word"
selectObject: sound, grid
runScript: "../plotScripts/pitch_plus.praat"
assert numberOfSelected() = 2
other = Create Sound from formula: "other", 1, 0, 0.1, 8000, "0"
writeFileLine: ready_path$, sound, tab$, grid, tab$, other
