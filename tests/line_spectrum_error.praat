form Line spectrum error test
    sentence Case
endform

if case$ = "time"
    @validateLineSpectrumTime: 0.01, 0, 0.5, 0.025, "Time"
elsif case$ = "frequency" or case$ = "axis"
    sound = Create Sound from formula: "invalid", 1, 0, 0.5, 16000, "sin(2*pi*500*x)"
    if case$ = "frequency"
        @validateLineSpectrum: sound, 1, 0, 0.025, 0, 9000, 0, 0, 0, 0, 0, 8
    else
        @validateLineSpectrum: sound, 1, 0, 0.025, 0, 5000, 1, 10, 0, 0, 0, 8
    endif
elsif case$ = "tier"
    grid = Create TextGrid: 0, 0.5, "words", ""
    @collectLineSpectrumPoints: grid, 1, 0, 0.5, 0.025
elsif case$ = "empty"
    grid = Create TextGrid: 0, 0.5, "points", "points"
    Insert point: 1, 0.1, ""
    Insert point: 1, 0.2, "  "
    @collectLineSpectrumPoints: grid, 1, 0, 0.5, 0.025
endif

include ../plotScripts/_line_spectrum.praat
