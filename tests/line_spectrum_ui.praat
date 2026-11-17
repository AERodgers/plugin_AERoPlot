form Line spectrum native interface test
    sentence Workflow Grid
endform

result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
sound = Create Sound from formula: "native test", 1, 0, 0.5, 16000,
... "0.2*sin(2*pi*500*x)+0.1*sin(2*pi*1200*x)"
if workflow$ = "Grid"
    grid = Create TextGrid: 0, 0.5, "words points", "points"
    selectObject: grid
    Insert point: 2, 0.1, "vowel"
    Insert point: 2, 0.2, ""
    Insert point: 2, 0.3, "vowel"
    for pass to 2
        selectObject: sound, grid
        runScript: "../plotScripts/lineSpectrum.praat"
        assert selected("Sound") = sound
        assert selected("TextGrid") = grid
    endfor
    removeObject: grid
else
    if workflow$ = "Time"
        settings$ = preferencesDirectory$ + "/plugin_AERoPlot/data/vars/line_spectrum.var"
        writeFileLine: settings$, "variable", tab$, "value"
        appendFileLine: settings$, "line_soundAnalysis", tab$, "2"
    endif
    selectObject: sound
    runScript: "../plotScripts/lineSpectrum.praat"
    assert selected("Sound") = sound
endif
removeObject: sound
writeFileLine: result$, "PASS"
