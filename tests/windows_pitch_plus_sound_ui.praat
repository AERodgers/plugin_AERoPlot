result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
sound = Create Sound from formula: "PitchPlus UI no-grid test", 1, 0, 1, 44100, "0.2*sin(2*pi*120*x)"
selectObject: sound
runScript: "../plotScripts/windowsPitchPlusPrototype.praat"
assert selected("Sound") = sound
writeFileLine: result$, "PASS"
removeObject: sound
