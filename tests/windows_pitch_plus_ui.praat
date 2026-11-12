result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
sound = Create Sound from formula: "PitchPlus UI test", 1, 0, 1, 44100, "0.2*sin(2*pi*120*x)"
grid = Create TextGrid: 0, 1, "words points", "points"
selectObject: grid
Insert boundary: 1, 0.1
Insert boundary: 1, 0.9
Set interval text: 1, 2, "word"
Insert point: 2, 0.5, "point"
selectObject: sound, grid
runScript: "../plotScripts/windowsPitchPlusPrototype.praat"
assert selected("Sound") = sound
assert selected("TextGrid") = grid
writeFileLine: result$, "PASS"
removeObject: {sound, grid}
