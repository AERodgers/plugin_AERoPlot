aeroPrototypeInclude = 1
aeroNonInteractive = 1
sound = Create Sound from formula: "main test", 1, 0, 0.5, 16000, "0.2*sin(2*pi*200*x)"
grid = Create TextGrid: 0, 0.5, "words points", "points"
Set interval text: 1, 1, "word"
Insert point: 2, 0.2, "p"
for requestedFormants from 1 to 2
    @main
    selectObject: "Table intensity_main_result"
    value = Get value: 1, "points_intensity_dB"
    assert value != undefined
    if requestedFormants = 2
        formantColumn = Get column index: "F1"
        assert formantColumn > 0
    endif
    Remove
endfor
removeObject: {sound, grid}
writeInfoLine: "Table intensity main tests passed."

procedure formTableSettings
    main.scale$[1] = "Hertz"
    main.scale$[2] = "Bark"
    ui.gridID$ = string$(grid)
    ui.soundID$ = string$(sound)
    ui.lowestTier$ = "points"
    ui.otherTiers$ = "words"
    ui.baseTierTimeOnly = 1
    ui.output$ = "intensity_main_result"
    ui.vowelDur$ = ""
    ui.formants2tabulate = requestedFormants
    ui.maxNumFormants = requestedFormants - 1
    ui.scale = 1
    ui.timeStep = 0
    ui.maxFormantHz = 5000
    ui.numFormants = 5
    ui.windowLen = 0.025
    ui.preEmph = 50
    ui.intensityTier1$ = "points"
endproc

include ../plotScripts/nestedTiers2Table.praat
