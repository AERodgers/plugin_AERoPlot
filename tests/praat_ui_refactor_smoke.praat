form Native interface refactoring test
    sentence Workflow PitchPlus
endform

result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
if workflow$ = "PitchPlus" or workflow$ = "Spectrogram" or workflow$ = "Table"
    sound = Create Sound from formula: "native UI test", 1, 0, 0.5, 44100, "0.2*sin(2*pi*120*x)"
    grid = Create TextGrid: 0, 0.5, "words points", "points"
    selectObject: grid
    Insert boundary: 1, 0.1
    Insert boundary: 1, 0.4
    Set interval text: 1, 2, "word"
    Insert point: 2, 0.2, "point"
    selectObject: sound, grid
    if workflow$ = "PitchPlus"
        runScript: "../plotScripts/pitch_plus.praat"
    elsif workflow$ = "Spectrogram"
        runScript: "../plotScripts/spectro_plus.praat"
    else
        runScript: "../plotScripts/nestedTiers2Table.praat"
    endif
    if workflow$ = "PitchPlus" or workflow$ = "Spectrogram"
        assert selected("Sound") = sound
        assert selected("TextGrid") = grid
        Save as 300-dpi PNG file: result$ + ".png"
    endif
else
    table = Create formant table (Peterson & Barney 1952)
    if workflow$ = "F1F2"
        runScript: "../plotScripts/f1f2Plot.praat"
    elsif workflow$ = "Ladefoged"
        runScript: "../plotScripts/ladPlot.praat"
    elsif workflow$ = "FormantsOverTime"
        runScript: "../plotScripts/fotPlot.praat"
    else
        exitScript: "Unknown native interface test workflow."
    endif
endif
writeFileLine: result$, "PASS"
