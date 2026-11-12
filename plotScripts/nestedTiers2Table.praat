# Generate Data Table from TextGrid with Nested Tiers
# ===================================================================
# A data extraction tool for general use and for the AERoplot plugin.
#
# Written for Praat 6.0.60 or later
#
# script by Antoin Eoin Rodgers
#
# email:     antoin.rodgers@tcd.ie
# github:    github.com/AERodgers

if not variableExists("aeroPrototypeInclude")
    @checkPraatVersion
    @getUIMode
    if getUIMode.mode$ = "windows"
        runScript: "windowsTablePrototype.praat"
    else
        firstPass = 1
        @objsSelected: "Sound,TextGrid", "ui.soundID$,ui.gridID$"
        @purgeDirFiles: preferencesDirectory$ + "/plugin_AERoPlot/data/temp"
        @main
    endif
endif

procedure main
    .curVersion$ = "1.5.0.2"
    if variableExists("aeroNonInteractive")
        # Command-line form: settings come from cli_table.praat, not a dialog.
        @formTableSettings
    elsif variableExists("aeroWindowsTableSettings")
        # Windows dialog: settings are saved under the name the user chose, but the
        # Table is built as a fixed variable name and renamed at the end.
        @defineVars
        @windowsTableDialog
        @writeVars:
        ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "tier2Table.var"
        windowsTableUserName$ = ui.output$
        ui.output$ = "windowsTableResult"
    else
        @defineVars

        @ui

        @writeVars:
        ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "tier2Table.var"
    endif

    @getObject: ui.gridID$, "textGrid", "main"
    @getSoundIfAny
    if not variableExists("aeroWindowsTableSettings")
        # A bad tier setting must not leave copies in the Objects list. The
        # command line reports it and stops; the pause window asks again.
        aeroSoftErrors = 1
        @resolveTableTierSettings: .textGrid
        while resolveTableTierSettings.error$ != ""
            .message$ = resolveTableTierSettings.error$
            @removeCopies: .textGrid, .sound
            if variableExists("aeroNonInteractive")
                exitScript: .message$
            endif
            ui.notice$ = .message$
            @ui
            @writeVars:
            ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "tier2Table.var"
            @getObject: ui.gridID$, "textGrid", "main"
            @getSoundIfAny
            @resolveTableTierSettings: .textGrid
        endwhile
        aeroSoftErrors = 0
    endif
    if ui.formants2tabulate > 1
        @warnLongRecording: .sound
        if not warnLongRecording.proceed
            @removeCopies: .textGrid, .sound
            exit
        endif
    endif
    @tiers2Table:
    ... .textGrid,
    ... "'ui.lowestTier$','ui.otherTiers$'",
    ...  ui.output$
    # decide time columns for
    if ui.formants2tabulate
        if tiers2Table.isIntTier[1]
            .tColTiers$ = "'ui.lowestTier$'_tmin,'ui.lowestTier$'_tmax"
        else
            .tColTiers$ = "'ui.lowestTier$'_t"
        endif
        @formantsSought: .sound, 'ui.output$', .tColTiers$,
        ... ui.timeStep,
        ... ui.maxNumFormants,
        ... ui.maxFormantHz,
        ... ui.numFormants,
        ... ui.windowLen,
        ... ui.preEmph,
        ... .scale$[ui.scale]
    endif


    selectObject: .textGrid
    if .sound
        plusObject: .sound
    endif
    Remove

    if variableExists("aeroWindowsTableSettings")
        selectObject: windowsTableResult
        Rename: windowsTableUserName$
    endif
    firstPass = 0
    # @writeVars:
    # ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "tier2Table.var"
endproc

# The Sound is only needed for formants; a blank entry means none.
procedure getSoundIfAny
    main.sound = 0
    if ui.soundID$ != ""
        @getObject: ui.soundID$, "sound", "main"
    endif
endproc

procedure removeCopies: .textGrid, .sound
    selectObject: .textGrid
    if .sound
        plusObject: .sound
    endif
    Remove
endproc

## UI-RELATED PROCEDURES




## OBJECT PROCESSING
procedure getObject: .objID$, .type$, .sourceProc$
    if fileReadable (.objID$)
        '.sourceProc$'.'.type$' = Read from file: .objID$
    elsif number(.objID$) == round(number(.objID$))
        selectObject: number(.objID$)
        '.sourceProc$'.'.type$' = Copy: "temporaryTable"
    else
        exitScript: "Cannot find valid '.type$':" + newline$ +
        ... .objID$ + newline$
    endif
endproc

## CONVERSION OF NESTED TEXTGRID TO TABLE
procedure resolveTableTierSettings: .textGrid
    .error$ = ""
    # Older settings may hold a point tier for formant times; formants are now
    # always measured on the base tier, so it is ignored.
    ui.formantTier$ = ""
    @isOffValue: ui.vowelDur$
    if isOffValue.off
        ui.vowelDur$ = ""
    endif
    @resolveTierReference: .textGrid, ui.lowestTier$, "Base tier", "any"
    .error$ = resolveTierReference.error$
    .newBase$ = resolveTierReference.name$
    .baseTier = resolveTierReference.tier
    @csvLine2Array: ui.otherTiers$, "resolveTableTierSettings.count", "resolveTableTierSettings.entries$"
    .resolved$ = ""
    for .i to .count
        if .error$ = ""
            @resolveTierReference: .textGrid, .entries$[.i], "Other tiers", "any"
            .error$ = resolveTierReference.error$
        endif
        if .error$ = ""
            @tierNested: .textGrid, .baseTier, resolveTierReference.tier
            if not tierNested.ok
                .error$ = "Other tiers: """ + resolveTierReference.name$ +
                ... """ lies inside the base tier, so it cannot fill a column. " +
                ... "Remove it, or choose a finer base tier."
                @settingError: .error$
            endif
        endif
        if .error$ = ""
            if .resolved$ != ""
                .resolved$ += ","
            endif
            .resolved$ += resolveTierReference.name$
        endif
    endfor
    .newDur$ = ui.vowelDur$
    if .error$ = "" and ui.vowelDur$ != ""
        @resolveTierReference: .textGrid, ui.vowelDur$, "Duration tier", "interval"
        .error$ = resolveTierReference.error$
        .newDur$ = resolveTierReference.name$
    endif
    # Settings are only replaced by their resolved names when all are valid, so
    # an interface can show the user's original entries again.
    if .error$ = ""
        ui.lowestTier$ = .newBase$
        ui.otherTiers$ = .resolved$
        ui.vowelDur$ = .newDur$
    endif
endproc

# Can the other tier supply a column for the base tier? True when at least one
# labelled base item lies inside some item of the other tier. Tiers that sit
# inside the base tier (for example points inside a segment) never qualify.
procedure tierNested: .grid, .base, .other
    .eps = 0.000000001
    selectObject: .grid
    .baseInt = Is interval tier: .base
    .otherInt = Is interval tier: .other
    .nb = 0
    if .baseInt
        .n = Get number of intervals: .base
        for .i to .n
            .l$ = Get label of interval: .base, .i
            if .l$ != ""
                .nb += 1
                .ba[.nb] = Get start time of interval: .base, .i
                .bb[.nb] = Get end time of interval: .base, .i
            endif
        endfor
    else
        .n = Get number of points: .base
        for .i to .n
            .l$ = Get label of point: .base, .i
            if .l$ != ""
                .nb += 1
                .ba[.nb] = Get time of point: .base, .i
                .bb[.nb] = .ba[.nb]
            endif
        endfor
    endif
    .no = 0
    if .otherInt
        .no = Get number of intervals: .other
        for .i to .no
            .oa[.i] = Get start time of interval: .other, .i
            .ob[.i] = Get end time of interval: .other, .i
        endfor
    else
        .no = Get number of points: .other
        for .i to .no
            .oa[.i] = Get time of point: .other, .i
            .ob[.i] = .oa[.i]
        endfor
    endif
    .ok = 1
    if .nb > 0
        .ok = 0
        .j = 1
        .i = 1
        while .i <= .nb and not .ok and .no > 0
            while .j < .no and .ob[.j] < .bb[.i] - .eps
                .j += 1
            endwhile
            if .oa[.j] <= .ba[.i] + .eps and .ob[.j] >= .bb[.i] - .eps
                .ok = 1
            endif
            .i += 1
        endwhile
    endif
endproc

procedure tiers2Table:
    ... .textGrid,
    ... .hierarchySSL$,
    ... .output$
    .output$ = replace$(.output$, "$", "", 1)

    # Get array showing order in which to process tiers
    @csvLine2Array: .hierarchySSL$,
    ... "tiers2Table.hierArray_N",
    ... "tiers2Table.hierArray$"

    selectObject: .textGrid
    .numTiers = Get number of tiers

    for .curTier to .numTiers
        # get Tier info
        .tierName$[.curTier] = Get tier name: .curTier
        .curIsIntTier = Is interval tier: .curTier
        .tierCode[.tierName$[.curTier]] = .curTier
        for .i to .hierArray_N
            if .tierName$[.curTier] = .hierArray$[.i]
                .tier[.i] = .curTier
                .isIntTier[.i] = .curIsIntTier
            endif
        endfor
    endfor

    # Create database table with innermost factor in tier hierarchy
    selectObject: .textGrid
    .gridTable = Down to Table: "no", 3, "yes", "no"
    '.output$' = Extract rows where column (text):
        ... "tier",
        ... "is equal to",
        ... .hierArray$[1]
    Rename: .output$
    Remove column: "tier"

    if .isIntTier[1]
        Set column label (label): "tmin", "'.hierArray$[1]'_tmin"
        Set column label (label): "tmax", "'.hierArray$[1]'_tmax"
        .tempIndex = Get column index: "'.hierArray$[1]'_tmax"
        Insert column: .tempIndex, "temp"
        Formula: "temp", "self[""'.hierArray$[1]'_tmin""]"
        Remove column: "'.hierArray$[1]'_tmin"
        Set column label (label): "temp", "'.hierArray$[1]'_tmin"
        .main_tmin$ = "'.hierArray$[1]'_tmin"
        .main_tmax$ = "'.hierArray$[1]'_tmax"
        .newColSt = -1
    else
        Remove column: "tmin"
        Set column label (label): "tmax", "'.hierArray$[1]'_t"
        .main_tmin$ = "'.hierArray$[1]'_t"
        .main_tmax$ = "'.hierArray$[1]'_t"
        .newColSt = 0
    endif
    Set column label (label): "text", .hierArray$[1]

    # create subtable for each tier in hierarchy
    for .i from 2 to .hierArray_N
        .curFactor$ = .hierArray$[.i]

        selectObject: .gridTable
        .tempTable = Extract rows where column (text):
            ... "tier",
            ... "is equal to",
            ... .curFactor$
        Remove column: "tier"

        .curNumRows = Get number of rows
        selectObject: '.output$'
       .curNumCols = Get number of columns
       Insert column: .curNumCols + .newColSt - 1, .curFactor$

        Insert column: .curNumCols + .newColSt, "'.curFactor$'_tmin"
        Insert column: .curNumCols + .newColSt + 1, "'.curFactor$'_tmax"
        for .j to .curNumRows
            selectObject: .tempTable
            .curTmin = Get value: .j, "tmin"
            .curText$ = Get value: .j, "text"
            .curTmax = Get value: .j, "tmax"
            selectObject: '.output$'
            Formula:
            ... .curFactor$,
            ... "if " +
            ...     "self[.main_tmin$] >= .curTmin  and " +
            ...     "self[.main_tmax$] <= .curTmax " +
            ... "then " +
            ...     ".curText$ " +
            ... "else " +
            ...     "self$ " +
            ... "endif"


            Formula:
            ... "'.curFactor$'_tmax",
            ... "if " +
            ...     "self[.main_tmin$] >= .curTmin  and " +
            ...     "self[.main_tmax$] <= .curTmax " +
            ... "then " +
            ...     "self[.main_tmax$] " +
            ... "else " +
            ...     "self$ " +
            ... "endif"


            Formula:
            ... "'.curFactor$'_tmin",
            ... "if " +
            ...     "self[.main_tmin$] >= .curTmin  and " +
            ...     "self[.main_tmax$] <= .curTmax " +
            ... "then " +
            ...     "self[.main_tmin$] " +
            ... "else " +
            ...     "self$ " +
            ... "endif"
        endfor

        selectObject: '.output$'
        if (.curNumRows = 1) or (ui.baseTierTimeOnly)
            Remove column: "'.curFactor$'_tmin"
            Remove column: "'.curFactor$'_tmax"
        elsif .isIntTier[.i]
            Insert column: .curNumCols + .newColSt + 1, "temp"
            Formula: "temp", "self[""'.curFactor$'_tmin""]"
            Remove column: "'.curFactor$'_tmin"
            Set column label (label): "temp", "'.curFactor$'_tmin"
        else
            Remove column: "'.curFactor$'_tmin"
            Set column label (label): "'.curFactor$'_tmax", "'.curFactor$'_t"
        endif
        removeObject: .tempTable
    endfor



    # Duration (in seconds) of the interval of the chosen tier that contains each row.
    if ui.vowelDur$ != ""
        selectObject: .gridTable

        .durTable = Extract rows where column (text):
        ... "tier",
        ... "is equal to",
        ... ui.vowelDur$

        .num_rows = Get number of rows
        .durCol$ = ui.vowelDur$ + "_dur"
        selectObject: '.output$'
        Append column: .durCol$
        for .i to .num_rows
            selectObject: .durTable
            .v_t_min = Get value: .i, "tmin"
            .v_t_max = Get value: .i, "tmax"
            .v_t_dur = number(fixed$(.v_t_max - .v_t_min, 4))
            selectObject: '.output$'
            Formula: .durCol$,
            ... "if (self[.main_tmin$] >= .v_t_min) and " +
            ...    "(self[.main_tmax$] <= .v_t_max) " +
            ... "then .v_t_dur " +
            ... "else self$ " +
            ... "endif"
        endfor
        removeObject: .durTable
    endif

    removeObject: .gridTable
endproc

## FORMANT ESTIMATION
procedure formantsSought:
        ... .sound, .table, .timeCols$, .timeStep,
        ....maxFormantsSought, .maxFormantHz, .numFormants,
        ... .windowLen, .preEmph,
        ... .scale$

    if .timeStep = 0
        .timeStep = .windowLen * 0.25
    endif

    @csvLine2Array: .timeCols$,
                ... "formantsSought.numCols",
                ..."formantsSought.colArray$"
    .firstT$ = .colArray$[1]
    if .numCols = 1
        .lastT$ = .firstT$
    else
        .lastT$ = .colArray$[2]
    endif

    selectObject: .sound
    noprogress To Formant (burg):
    ... .timeStep,
    ... .numFormants,
    ... .maxFormantHz,
    ... .windowLen,
    ... .preEmph
    .formantObj = selected()

    selectObject: .table
    for .f to .maxFormantsSought
        Append column: "F'.f'"
    endfor

    .numRows = Get number of rows
    for .curRow to .numRows
        selectObject: .table
        .startTP = Get value: .curRow, .firstT$
        .endTP = Get value: .curRow, .lastT$

        for .f to .maxFormantsSought
            selectObject: .formantObj

            # Point tiers give one sample at the point. Interval tiers give the
            # mean of the defined samples taken every time step across the
            # interval (one midpoint sample if it is shorter than a step).
            .curTotTPs = 0
            .curTotF = 0
            .span = .endTP - .startTP
            if .span < .timeStep
                .numSamples = 1
                .firstTP = (.startTP + .endTP) / 2
            else
                .numSamples = floor(.span / .timeStep) + 1
                .firstTP = .startTP
            endif
            for .s to .numSamples
                .curF = Get value at time: .f, .firstTP + (.s - 1) * .timeStep, .scale$, "Linear"
                if .curF != undefined
                    .curTotF += .curF
                    .curTotTPs += 1
                endif
            endfor
            if .curTotTPs > 0
                .meanF = .curTotF / .curTotTPs
            else
                .meanF = undefined
            endif

            selectObject: .table
            if .scale$ = "Bark"
                .decPlaces  = 3
            else
                .decPlaces  = 0
            endif
            Set string value: .curRow, "F'.f'", fixed$(.meanF, .decPlaces)
        endfor
    endfor

    removeObject:  .formantObj
endproc

## VARIABLE / PROCEDURE INTITIALISATION
procedure defineVars
    createFolder: preferencesDirectory$ + "/plugin_AERoPlot/data/"
    createFolder: preferencesDirectory$ + "/plugin_AERoPlot/data/vars"

    main.scale$[1] = "Hertz"
    main.scale$[2] = "Bark"
    if !fileReadable(preferencesDirectory$ +
        ... "/plugin_AERoPlot/data/vars/tier2Table.var")
        @initialiseVars: preferencesDirectory$ +
        ... "/plugin_AERoPlot/data/vars/tier2Table.var"
    endif
    @readVars: preferencesDirectory$ +
    ... "/plugin_AERoPlot/data/vars/", "tier2Table.var"
    if main.version$ != main.curVersion$
        @initialiseVars: preferencesDirectory$ +
        ... "/plugin_AERoPlot/data/vars/tier2Table.var"
    endif
    @readVars: preferencesDirectory$ +
    ... "/plugin_AERoPlot/data/vars/", "tier2Table.var"
    @overwriteVars

    if (ui.soundID$ != x_ui.soundID$) or (ui.gridID$ != x_ui.gridID$)
        ui.output$ = ""
        ui.lowestTier$ = ""
        ui.otherTiers$ = ""
    endif

endproc

procedure initialiseVars: .address$
    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "main.version$", tab$, main.curVersion$
    appendFileLine: .address$, "ui.gridID$", tab$,
    ... preferencesDirectory$ + "/plugin_AERoPlot/example/AER_NI_I.textgrid"
    appendFileLine: .address$, "ui.lowestTier$", tab$, "Comparible.target.int"
    appendFileLine: .address$, "ui.otherTiers$", tab$,
    ... "Speaker,Section,Phenomenon,Broad,Narrow,Comment"
    appendFileLine: .address$, "ui.baseTierTimeOnly", tab$, 1
       appendFileLine: .address$, "ui.output$", tab$, "aer_ni_i"
    appendFileLine: .address$, "ui.soundID$", tab$, preferencesDirectory$ +
    ... "/plugin_AERoPlot/example/AER_NI_I.wav"
    appendFileLine: .address$, "ui.formants2tabulate", tab$, 4
    appendFileLine: .address$, "ui.numFormants", tab$, 5
    appendFileLine: .address$, "ui.formantTier$", tab$, ""
    appendFileLine: .address$, "ui.vowelDur$", tab$, ""
    appendFileLine: .address$, "ui.scale", tab$, 1
    appendFileLine: .address$, "ui.timeStep", tab$, 0
    appendFileLine: .address$, "ui.maxFormantHz", tab$, 5000
    appendFileLine: .address$, "ui.windowLen", tab$, 0.025
    appendFileLine: .address$, "ui.preEmph", tab$, 50
    appendFileLine: .address$, "firstPass", tab$, 1
endproc


procedure check4ExampleObjs: .gridID$, .soundID$
    # Set UI menu elements if user has selected example objects.
    selectObject: '.gridID$'
    plusObject: '.soundID$'
    if extractLine$ (selected$(1), " ") = "AER_NI_I" and
        ... extractLine$ (selected$(2), " ") = "AER_NI_I"
        ui.output$ = "aer_ni_i"
        ui.lowestTier$ = "Element"
        ui.otherTiers$ = "Speaker,Sex,Type,Context,Rep,IPA,Segment"
        ui.formants2tabulate = 4

    endif

endproc

include _genFnBank.praat
include _aeroplotFns.praat
include _ui_common.praat
include _praat_table_ui.praat
