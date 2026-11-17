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
        @checkDirectoryStructure
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

    @ensureTableMeasurementDefaults

    @getObject: ui.gridID$, "textGrid", "main"
    @getSoundIfAny
    # A bad tier setting must not leave copies in the Objects list.
    aeroSoftErrors = 1
    @resolveTableTierSettings: .textGrid
    while resolveTableTierSettings.error$ != ""
        .message$ = resolveTableTierSettings.error$
        @removeCopies: .textGrid, .sound
        if variableExists("aeroNonInteractive") or variableExists("aeroWindowsTableSettings")
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
    if (ui.formants2tabulate > 1 or ui.intensityTier1$ != "" or
    ... ui.intensityTier2$ != "" or ui.intensityTier3$ != "") and not .sound
        @removeCopies: .textGrid, .sound
        exitScript: "A Sound is required for formant or intensity extraction."
    endif
    if ui.intensityTier1$ != "" or ui.intensityTier2$ != "" or ui.intensityTier3$ != ""
        selectObject: .sound
        .soundDuration = Get total duration
        if .soundDuration < 6.4 / ui.intensityPitch
            @removeCopies: .textGrid, .sound
            exitScript: "The Sound is too short for intensity extraction at this pitch floor. " +
            ... "Its duration must be at least 6.4 divided by the intensity pitch floor."
        endif
    endif
    if ui.formants2tabulate > 1 or ui.intensityTier1$ != "" or
    ... ui.intensityTier2$ != "" or ui.intensityTier3$ != ""
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
    if ui.formants2tabulate > 1
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
    if ui.intensityTier1$ != "" or ui.intensityTier2$ != "" or ui.intensityTier3$ != ""
        @tableIntensity: .sound, .textGrid, 'ui.output$', ui.lowestTier$
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

# The Sound is needed for formants and intensity; a blank entry means none.
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
    @ensureTableMeasurementDefaults
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
    .durationVar$[1] = "ui.vowelDur$"
    .durationVar$[2] = "ui.duration2$"
    .durationVar$[3] = "ui.duration3$"
    for .i to 3
        .var$ = .durationVar$[.i]
        .newDur$[.i] = '.var$'
        @isOffValue: .newDur$[.i]
        if isOffValue.off
            .newDur$[.i] = ""
        elsif .error$ = ""
            @resolveTierReference: .textGrid, .newDur$[.i], "Duration tier " + string$(.i), "interval"
            .error$ = resolveTierReference.error$
            .newDur$[.i] = resolveTierReference.name$
            if .error$ = ""
                for .j to .i - 1
                    if .newDur$[.j] = .newDur$[.i]
                        .error$ = "Choose each duration tier only once."
                        @settingError: .error$
                    endif
                endfor
            endif
        endif
    endfor
    for .i to 3
        .var$ = "ui.intensityTier" + string$(.i) + "$"
        .newIntensity$[.i] = '.var$'
        @isOffValue: .newIntensity$[.i]
        if isOffValue.off
            .newIntensity$[.i] = ""
        elsif .error$ = ""
            @resolveTierReference: .textGrid, .newIntensity$[.i], "Intensity tier " + string$(.i), "any"
            .error$ = resolveTierReference.error$
            .newIntensity$[.i] = resolveTierReference.name$
            .intensityTier[.i] = resolveTierReference.tier
            if .error$ = ""
                for .j to .i - 1
                    if .newIntensity$[.j] = .newIntensity$[.i]
                        .error$ = "Choose each intensity tier only once."
                        @settingError: .error$
                    endif
                endfor
            endif
            if .error$ = ""
                @validateIntensityMapping: .textGrid, .baseTier, .intensityTier[.i]
                .error$ = validateIntensityMapping.error$
            endif
            .var$ = "ui.intensityMethod" + string$(.i)
            .method = '.var$'
            if .error$ = "" and (.method < 1 or .method > 4 or .method != floor(.method))
                .error$ = "Choose a valid intensity statistic."
                @settingError: .error$
            endif
        endif
    endfor
    if .error$ = "" and ui.intensityPitch <= 0
        .error$ = "Intensity pitch floor must be positive."
        @settingError: .error$
    endif
    # Settings are only replaced by their resolved names when all are valid, so
    # an interface can show the user's original entries again.
    if .error$ = ""
        ui.lowestTier$ = .newBase$
        ui.otherTiers$ = .resolved$
        for .i to 3
            .var$ = .durationVar$[.i]
            '.var$' = .newDur$[.i]
            .var$ = "ui.intensityTier" + string$(.i) + "$"
            '.var$' = .newIntensity$[.i]
        endfor
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

# A measurement tier must not supply several values for one base-tier row.
procedure validateIntensityMapping: .grid, .base, .tier
    .error$ = ""
    selectObject: .grid
    .baseName$ = Get tier name: .base
    @tableBaseTimes: .grid, .baseName$
    for .i to tableBaseTimes.count
        @findTableMeasurement: .grid, .tier, tableBaseTimes.start[.i], tableBaseTimes.end[.i]
        if findTableMeasurement.count > 1
            .error$ = "Intensity tier has multiple points matching base row " +
            ... string$(.i) + ". Use the point tier as the base tier."
            @settingError: .error$
            .i = tableBaseTimes.count
        endif
    endfor
endproc

# Intervals must contain the entire row; a point at a shared boundary belongs
# to the interval on its right, as in Praat's Get interval at time.
procedure findTableMeasurement: .grid, .tier, .start, .end
    .count = 0
    .from = undefined
    .to = undefined
    selectObject: .grid
    .interval = Is interval tier: .tier
    if .interval
        .index = Get interval at time: .tier, (.start + .end) / 2
        if .index > 0
            .label$ = Get label of interval: .tier, .index
            .from = Get start time of interval: .tier, .index
            .to = Get end time of interval: .tier, .index
            if .label$ != "" and .start >= .from - 1e-9 and .end <= .to + 1e-9
                .count = 1
            endif
        endif
    else
        .number = Get number of points: .tier
        .lowerTime = .start
        .upperTime = .end
        if .start = .end
            .lowerTime -= 1e-9
            .upperTime += 1e-9
        endif
        .low = 1
        .high = .number + 1
        while .low < .high
            .mid = floor((.low + .high) / 2)
            .time = Get time of point: .tier, .mid
            if .time < .lowerTime
                .low = .mid + 1
            else
                .high = .mid
            endif
        endwhile
        .i = .low
        while .i <= .number
            .time = Get time of point: .tier, .i
            if .time > .upperTime
                .i = .number + 1
            else
                .label$ = Get label of point: .tier, .i
                if .label$ != ""
                    if .start = .end
                        .inside = abs(.time - .start) < 1e-9
                    else
                        .inside = .time >= .start and .time < .end
                    endif
                    if .inside
                        .count += 1
                        .from = .time
                        .to = .time
                    endif
                endif
                .i += 1
            endif
        endwhile
    endif
endproc

procedure tableBaseTimes: .grid, .base$
    @resolveTierNumber: .grid, .base$, "Base tier", "any"
    .tier = resolveTierNumber.tier
    .interval = resolveTierNumber.interval
    selectObject: .grid
    .count = 0
    if .interval
        .number = Get number of intervals: .tier
    else
        .number = Get number of points: .tier
    endif
    for .i to .number
        if .interval
            .label$ = Get label of interval: .tier, .i
        else
            .label$ = Get label of point: .tier, .i
        endif
        if .label$ != ""
            .count += 1
            if .interval
                .start[.count] = Get start time of interval: .tier, .i
                .end[.count] = Get end time of interval: .tier, .i
            else
                .start[.count] = Get time of point: .tier, .i
                .end[.count] = .start[.count]
            endif
        endif
    endfor
endproc

procedure tableIntensity: .sound, .grid, .table, .base$
    selectObject: .sound
    .soundStart = Get starting time
    .soundEnd = Get end time
    .intensity = To Intensity: ui.intensityPitch, 0, "yes"
    @tableBaseTimes: .grid, .base$
    .methodName$[1] = "mean"
    .methodName$[2] = "midpoint"
    .methodName$[3] = "minimum"
    .methodName$[4] = "maximum"
    for .i to 3
        .var$ = "ui.intensityTier" + string$(.i) + "$"
        .tierName$ = '.var$'
        if .tierName$ != ""
            .var$ = "ui.intensityMethod" + string$(.i)
            .method = '.var$'
            @resolveTierNumber: .grid, .tierName$, "Intensity tier", "any"
            .tier = resolveTierNumber.tier
            .interval = resolveTierNumber.interval
            .column$ = .tierName$ + "_intensity_dB"
            if .interval
                .column$ = .tierName$ + "_intensity_" + .methodName$[.method] + "_dB"
            endif
            selectObject: .table
            Append column: .column$
            .rows = Get number of rows
            if .rows != tableBaseTimes.count
                exitScript: "Base-tier rows do not match the TextGrid; cannot extract intensity."
            endif
            .missing = 0
            for .row to .rows
                .start = tableBaseTimes.start[.row]
                .end = tableBaseTimes.end[.row]
                @findTableMeasurement: .grid, .tier, .start, .end
                .value = undefined
                if findTableMeasurement.count = 1
                    .from = findTableMeasurement.from
                    .to = findTableMeasurement.to
                    if .from >= .soundStart and .to <= .soundEnd
                        selectObject: .intensity
                        if not .interval or .method = 2
                            .value = Get value at time: (.from + .to) / 2, "Cubic"
                        elsif .method = 1
                            .value = Get mean: .from, .to, "energy"
                        elsif .method = 3
                            .value = Get minimum: .from, .to, "Parabolic"
                        else
                            .value = Get maximum: .from, .to, "Parabolic"
                        endif
                    endif
                endif
                if .value = undefined
                    .missing += 1
                else
                    .value = round(.value * 10) / 10
                endif
                selectObject: .table
                Set numeric value: .row, .column$, .value
            endfor
            if .missing > 0
                appendInfoLine: "Warning: " + string$(.missing) + " rows have undefined intensity for tier """ + .tierName$ + """."
            endif
        endif
    endfor
    removeObject: .intensity
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
    @ensureTableMeasurementDefaults
    .durationVar$[1] = "ui.vowelDur$"
    .durationVar$[2] = "ui.duration2$"
    .durationVar$[3] = "ui.duration3$"
    for .durationIndex to 3
      .var$ = .durationVar$[.durationIndex]
      .durationTier$ = '.var$'
      if .durationTier$ != ""
        selectObject: .gridTable
        .durTable = Extract rows where column (text):
        ... "tier",
        ... "is equal to",
        ... .durationTier$
        .num_rows = Get number of rows
        .durCol$ = .durationTier$ + "_dur"
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
    endfor

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
    @ensureTableMeasurementDefaults
    @ensureTableMeasurementSettings
    @overwriteVars

    if (ui.soundID$ != x_ui.soundID$) or (ui.gridID$ != x_ui.gridID$)
        ui.output$ = ""
        ui.lowestTier$ = ""
        ui.otherTiers$ = ""
    endif
    @resolveExamplePath: ui.gridID$, "AER_NI_I.textgrid"
    ui.gridID$ = resolveExamplePath.resolved$
    @resolveExamplePath: ui.soundID$, "AER_NI_I.wav"
    ui.soundID$ = resolveExamplePath.resolved$

endproc

# Supply defaults for older settings files and for callers that use the shared
# conversion procedures without opening a dialog.
procedure ensureTableMeasurementDefaults
    if not variableExists("ui.duration2$")
        ui.duration2$ = ""
    endif
    if not variableExists("ui.duration3$")
        ui.duration3$ = ""
    endif
    for .i to 3
        .var$ = "ui.intensityTier" + string$(.i) + "$"
        if not variableExists(.var$)
            '.var$' = ""
        endif
        .var$ = "ui.intensityMethod" + string$(.i)
        if not variableExists(.var$)
            '.var$' = 1
        endif
    endfor
    if not variableExists("ui.intensityPitch")
        ui.intensityPitch = 100
    endif
endproc

procedure ensureTableMeasurementSettings
    .file$ = preferencesDirectory$ + "/plugin_AERoPlot/data/vars/tier2Table.var"
    .variables$ = "ui.duration2$,ui.duration3$,ui.intensityTier1$,ui.intensityTier2$,ui.intensityTier3$," +
    ... "ui.intensityMethod1,ui.intensityMethod2,ui.intensityMethod3,ui.intensityPitch"
    @csvLine2Array: .variables$, "ensureTableMeasurementSettings.count", "ensureTableMeasurementSettings.names$"
    .added = 0
    for .i to .count
        .found = 0
        for .j to tier2TableNumVars
            if tier2TableVar$[.j] = .names$[.i]
                .found = 1
            endif
        endfor
        if not .found
            .var$ = .names$[.i]
            appendFileLine: .file$, .var$, tab$, '.var$'
            .added = 1
        endif
    endfor
    if .added
        @readVars: preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "tier2Table.var"
    endif
endproc

procedure initialiseVars: .address$
    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "main.version$", tab$, main.curVersion$
    appendFileLine: .address$, "ui.gridID$", tab$,
    ... "../example/AER_NI_I.textgrid"
    appendFileLine: .address$, "ui.lowestTier$", tab$, "Comparible.target.int"
    appendFileLine: .address$, "ui.otherTiers$", tab$,
    ... "Speaker,Section,Phenomenon,Broad,Narrow,Comment"
    appendFileLine: .address$, "ui.baseTierTimeOnly", tab$, 1
       appendFileLine: .address$, "ui.output$", tab$, "aer_ni_i"
    appendFileLine: .address$, "ui.soundID$", tab$, "../example/AER_NI_I.wav"
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
