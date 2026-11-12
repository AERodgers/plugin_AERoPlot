# Windows-only Create Table dialog. The Praat dialog remains available.
aeroPrototypeInclude = 1

if not variableExists("aeroPrototypeTest")
    @runWindowsTablePrototype
endif

procedure runWindowsTablePrototype
    @checkPraatVersion
    if environment$("OS") != "Windows_NT"
        exitScript: "The AERoPlot Windows interface only runs on Windows."
    endif
    if checkPraatVersion.major < 6 or (checkPraatVersion.major = 6 and
    ... (checkPraatVersion.minor < 4 or
    ... (checkPraatVersion.minor = 4 and checkPraatVersion.patch < 60)))
        exitScript: "The Windows interface requires Praat 6.4.60 or newer. Choose Praat > AERoPlot > Use Praat interface instead."
    endif
    wtExe$ = preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe"
    if not fileReadable(wtExe$)
        exitScript: "The Windows interface has not been built. See the Windows interface instructions in the AERoPlot README."
    endif
    if size(selected#()) != 2 or numberOfSelected("Sound") != 1 or numberOfSelected("TextGrid") != 1
        exitScript: "Select exactly one Sound and one TextGrid."
    endif
    wtSound = selected("Sound")
    wtGrid = selected("TextGrid")
    wtSoundName$ = selected$("Sound")
    wtGridName$ = selected$("TextGrid")
    selectObject: wtGrid
    wtNumberOfTiers = Get number of tiers
    if wtNumberOfTiers = 0
        selectObject: wtSound
        plusObject: wtGrid
        exitScript: "The selected TextGrid has no tiers."
    endif
    wtTiers$ = ""
    for .i to wtNumberOfTiers
        wtTier$[.i] = Get tier name: .i
        wtTierIsInterval[.i] = Is interval tier: .i
        if wtTier$[.i] = "" or wtTier$[.i] = "?" or
        ... index_regex(wtTier$[.i], "[,'""*?\t\n\r]") != 0 or
        ... index_regex(wtTier$[.i], "(^[ ]|[ ]$|  )") != 0
            selectObject: wtSound
            plusObject: wtGrid
            exitScript: "The Windows interface cannot use empty tier names, leading/trailing or repeated spaces, commas, quotes, wildcards, tabs, or line breaks. Use the Praat interface instead."
        endif
        for .j to .i - 1
            if wtTier$[.i] = wtTier$[.j]
                selectObject: wtSound
                plusObject: wtGrid
                exitScript: "The Windows interface requires unique tier names. Use the Praat interface instead."
            endif
        endfor
    endfor
    # Each tier line ends with one 0/1 per possible base tier: can this tier fill a column for that base?
    for .t to wtNumberOfTiers
        .nested$ = ""
        for .b to wtNumberOfTiers
            if .b = .t
                .nested$ += "1"
            else
                @tierNested: wtGrid, .b, .t
                .nested$ += string$(tierNested.ok)
            endif
        endfor
        if .t > 1
            wtTiers$ += newline$
        endif
        if wtTierIsInterval[.t]
            wtTiers$ += "I" + tab$ + wtTier$[.t] + tab$ + .nested$
        else
            wtTiers$ += "P" + tab$ + wtTier$[.t] + tab$ + .nested$
        endif
    endfor
    selectObject: wtSound
    plusObject: wtGrid
    if length(wtTiers$) + length(wtSoundName$) + length(wtGridName$) > 20000
        exitScript: "The TextGrid's tier names are too long for the Windows interface. Use the Praat interface instead."
    endif
    aeroWindowsTableSettings = 1
    @main
endproc

# Replaces the pause window: shows the Windows dialog, then copies its values
# into the settings the shared Table procedures expect.
procedure windowsTableDialog
    # Saved settings apply to the tiers only when the saved base tier is in this TextGrid.
    .name$ = "aeroplot_table"
    .base = 1
    .others$ = "-"
    .formants = 1
    .duration = 0
    .saved = 0
    for .i to wtNumberOfTiers
        if wtTier$[.i] = ui.lowestTier$
            .saved = .i
        endif
    endfor
    if .saved
        .base = .saved
        .name$ = ui.output$
        if index_regex(.name$, "^[A-Za-z][A-Za-z0-9_]*$") = 0
            .name$ = "aeroplot_table"
        endif
        .formants = min(max(round(ui.formants2tabulate), 1), 5)
        @csvLine2Array: ui.otherTiers$, "windowsTableDialog.count", "windowsTableDialog.entry$"
        .list$ = ""
        for .j to .count
            for .i to wtNumberOfTiers
                if wtTier$[.i] = .entry$[.j] and .i != .base
                    if .list$ != ""
                        .list$ += ","
                    endif
                    .list$ += string$(.i)
                endif
            endfor
        endfor
        if .list$ != ""
            .others$ = .list$
        endif
        for .i to wtNumberOfTiers
            if wtTier$[.i] = ui.vowelDur$ and wtTierIsInterval[.i]
                .duration = .i
            endif
        endfor
    endif
    .scale = min(max(round(ui.scale), 1), 2)
    .settings$ = .name$ + tab$ + string$(.base) + tab$ + .others$ + tab$ +
    ... string$(ui.baseTierTimeOnly <> 0) + tab$ + string$(.formants) + tab$ +
    ... string$(.duration) + tab$ + string$(.scale) + tab$ +
    ... string$(ui.timeStep) + tab$ + string$(ui.maxFormantHz) + tab$ +
    ... string$(ui.numFormants) + tab$ + string$(ui.windowLen) + tab$ +
    ... string$(ui.preEmph)

    .response$ = runSubprocess$(wtExe$, "TABLE", wtSoundName$, wtGridName$, wtTiers$, .settings$)
    .fields$# = splitByWhitespace$#(.response$)
    if size(.fields$#) = 1
        if .fields$#[1] = "CANCEL"
            exit
        endif
    endif
    if size(.fields$#) != 13 or .fields$#[1] != "OK"
        exitScript: "The Windows interface returned an invalid response; no Table was created."
    endif
    if index_regex(.fields$#[2], "^[A-Za-z][A-Za-z0-9_]*$") = 0 or
    ... index_regex(.fields$#[3], "^[1-9][0-9]*$") = 0 or
    ... index_regex(.fields$#[4], "^(-|[1-9][0-9]*(,[1-9][0-9]*)*)$") = 0 or
    ... index_regex(.fields$#[5], "^[01]$") = 0 or
    ... index_regex(.fields$#[6], "^[1-5]$") = 0 or
    ... index_regex(.fields$#[7], "^[0-9]+$") = 0 or
    ... index_regex(.fields$#[8], "^[12]$") = 0
        exitScript: "The Windows interface returned invalid Table settings; no Table was created."
    endif
    for .i from 9 to 13
        if index_regex(.fields$#[.i], "^[0-9]+(\.[0-9]+)?$") = 0
            exitScript: "The Windows interface returned invalid analysis settings; no Table was created."
        endif
    endfor
    .baseIndex = number(.fields$#[3])
    .durationIndex = number(.fields$#[7])
    if .baseIndex > wtNumberOfTiers or .durationIndex > wtNumberOfTiers
        exitScript: "The Windows interface returned invalid tier settings; no Table was created."
    endif
    if .durationIndex > 0 and not wtTierIsInterval[.durationIndex]
        exitScript: "The Windows interface returned invalid tier settings; no Table was created."
    endif
    .hasOthers = .fields$#[4] != "-"
    .others$ = ""
    if .hasOthers
        @csvLine2Array: .fields$#[4], "windowsTableDialog.count", "windowsTableDialog.index$"
        for .j to .count
            .index = number(.index$[.j])
            if .index > wtNumberOfTiers or .index = .baseIndex
                exitScript: "The Windows interface returned invalid tier settings; no Table was created."
            endif
            for .k to .j - 1
                if .index$[.j] = .index$[.k]
                    exitScript: "The Windows interface returned duplicate tiers; no Table was created."
                endif
            endfor
            if .others$ != ""
                .others$ += ","
            endif
            .others$ += wtTier$[.index]
        endfor
    endif
    ui.gridID$ = string$(wtGrid)
    ui.soundID$ = string$(wtSound)
    ui.output$ = .fields$#[2]
    ui.lowestTier$ = wtTier$[.baseIndex]
    ui.otherTiers$ = .others$
    ui.baseTierTimeOnly = number(.fields$#[5])
    ui.formants2tabulate = number(.fields$#[6])
    ui.maxNumFormants = ui.formants2tabulate - 1
    ui.formantTier$ = ""
    ui.vowelDur$ = ""
    if .durationIndex > 0
        ui.vowelDur$ = wtTier$[.durationIndex]
    endif
    ui.scale = number(.fields$#[8])
    ui.timeStep = number(.fields$#[9])
    ui.maxFormantHz = number(.fields$#[10])
    ui.numFormants = number(.fields$#[11])
    ui.windowLen = number(.fields$#[12])
    ui.preEmph = number(.fields$#[13])
    if ui.maxFormantHz <= 0 or ui.numFormants <= 0 or ui.windowLen <= 0 or ui.preEmph <= 0
        exitScript: "The Windows interface returned invalid analysis settings; no Table was created."
    endif
endproc

include nestedTiers2Table.praat
