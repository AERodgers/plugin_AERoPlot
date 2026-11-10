result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
sound = Create Sound from formula: "menu test", 1, 0, 1, 8000, "0"
grid = To TextGrid: "word", ""
Set interval text: 1, 1, "hello"
selectObject: sound
plusObject: grid
writeFileLine: result$, "Ready."
