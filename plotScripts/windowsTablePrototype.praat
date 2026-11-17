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
    wtExe$ = "../windows-ui/bin/AERoPlotWindowsUI.exe"
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
    .duration2 = 0
    .duration3 = 0
    .intensity1 = 0
    .intensity2 = 0
    .intensity3 = 0
    .method1 = 1
    .method2 = 1
    .method3 = 1
    .intensityPitch = ui.intensityPitch
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
    for .i to wtNumberOfTiers
        if wtTier$[.i] = ui.duration2$ and wtTierIsInterval[.i]
            .duration2 = .i
        endif
        if wtTier$[.i] = ui.duration3$ and wtTierIsInterval[.i]
            .duration3 = .i
        endif
        if wtTier$[.i] = ui.intensityTier1$
            .intensity1 = .i
        endif
        if wtTier$[.i] = ui.intensityTier2$
            .intensity2 = .i
        endif
        if wtTier$[.i] = ui.intensityTier3$
            .intensity3 = .i
        endif
    endfor
    .method1 = min(max(round(ui.intensityMethod1), 1), 4)
    .method2 = min(max(round(ui.intensityMethod2), 1), 4)
    .method3 = min(max(round(ui.intensityMethod3), 1), 4)
    .durationTier[1] = .duration
    .durationTier[2] = .duration2
    .durationTier[3] = .duration3
    for .i from 1 to 2
        for .j from 1 to 3 - .i
            if .durationTier[.j] = 0 and .durationTier[.j + 1] > 0
                .swap = .durationTier[.j]
                .durationTier[.j] = .durationTier[.j + 1]
                .durationTier[.j + 1] = .swap
            endif
        endfor
    endfor
    .duration = .durationTier[1]
    .duration2 = .durationTier[2]
    .duration3 = .durationTier[3]
    .intensityTier[1] = .intensity1
    .intensityTier[2] = .intensity2
    .intensityTier[3] = .intensity3
    .intensityMethod[1] = .method1
    .intensityMethod[2] = .method2
    .intensityMethod[3] = .method3
    for .i from 1 to 2
        for .j from 1 to 3 - .i
            if .intensityTier[.j] = 0 and .intensityTier[.j + 1] > 0
                .swap = .intensityTier[.j]
                .intensityTier[.j] = .intensityTier[.j + 1]
                .intensityTier[.j + 1] = .swap
                .methodSwap = .intensityMethod[.j]
                .intensityMethod[.j] = .intensityMethod[.j + 1]
                .intensityMethod[.j + 1] = .methodSwap
            endif
        endfor
    endfor
    .intensity1 = .intensityTier[1]
    .intensity2 = .intensityTier[2]
    .intensity3 = .intensityTier[3]
    .method1 = .intensityMethod[1]
    .method2 = .intensityMethod[2]
    .method3 = .intensityMethod[3]
    .scale = min(max(round(ui.scale), 1), 2)
    # Current TABLE protocol appends duration2-3, intensity tiers 1-3, methods 1-3, then pitch.
    .settings$ = .name$ + tab$ + string$(.base) + tab$ + .others$ + tab$ +
    ... string$(ui.baseTierTimeOnly <> 0) + tab$ + string$(.formants) + tab$ +
    ... string$(.duration) + tab$ + string$(.scale) + tab$ +
    ... string$(ui.timeStep) + tab$ + string$(ui.maxFormantHz) + tab$ +
    ... string$(ui.numFormants) + tab$ + string$(ui.windowLen) + tab$ +
    ... string$(ui.preEmph) + tab$ + string$(.duration2) + tab$ +
    ... string$(.duration3) + tab$ + string$(.intensity1) + tab$ +
    ... string$(.intensity2) + tab$ + string$(.intensity3) + tab$ +
    ... string$(.method1) + tab$ + string$(.method2) + tab$ +
    ... string$(.method3) + tab$ + string$(.intensityPitch)

    .response$ = runSubprocess$(wtExe$, "TABLE", wtSoundName$, wtGridName$, wtTiers$, .settings$)
    .fields$# = splitByWhitespace$#(.response$)
    if size(.fields$#) = 1
        if .fields$#[1] = "CANCEL"
            exit
        endif
    endif
    if size(.fields$#) != 22 or .fields$#[1] != "OK"
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
    for .i from 14 to 18
        if index_regex(.fields$#[.i], "^(0|[1-9][0-9]*)$") = 0
            exitScript: "The Windows interface returned invalid optional tier settings; no Table was created."
        endif
    endfor
    for .i from 19 to 21
        if index_regex(.fields$#[.i], "^[1-4]$") = 0
            exitScript: "The Windows interface returned invalid intensity settings; no Table was created."
        endif
    endfor
    if index_regex(.fields$#[22], "^[0-9]+(\.[0-9]+)?$") = 0 or
    ... number(.fields$#[22]) < 0.001 or number(.fields$#[22]) > 20000 or
    ... number(.fields$#[9]) < 0 or number(.fields$#[9]) > 10 or
    ... number(.fields$#[10]) < 1000 or number(.fields$#[10]) > 20000 or
    ... number(.fields$#[11]) < 1 or number(.fields$#[11]) > 20 or
    ... number(.fields$#[12]) < 0.001 or number(.fields$#[12]) > 2 or
    ... number(.fields$#[13]) < 1 or number(.fields$#[13]) > 20000
        exitScript: "The Windows interface returned out-of-range analysis or intensity pitch settings; no Table was created."
    endif
    .baseIndex = number(.fields$#[3])
    .durationIndex = number(.fields$#[7])
    .duration2Index = number(.fields$#[14])
    .duration3Index = number(.fields$#[15])
    .intensity1Index = number(.fields$#[16])
    .intensity2Index = number(.fields$#[17])
    .intensity3Index = number(.fields$#[18])
    if .baseIndex > wtNumberOfTiers or .durationIndex > wtNumberOfTiers or
    ... .duration2Index > wtNumberOfTiers or .duration3Index > wtNumberOfTiers or
    ... .intensity1Index > wtNumberOfTiers or .intensity2Index > wtNumberOfTiers or
    ... .intensity3Index > wtNumberOfTiers
        exitScript: "The Windows interface returned invalid tier settings; no Table was created."
    endif
    if .durationIndex > 0
        if not wtTierIsInterval[.durationIndex]
            exitScript: "The Windows interface returned invalid duration tier settings; no Table was created."
        endif
    endif
    if .duration2Index > 0
        if not wtTierIsInterval[.duration2Index]
            exitScript: "The Windows interface returned invalid duration tier settings; no Table was created."
        endif
    endif
    if .duration3Index > 0
        if not wtTierIsInterval[.duration3Index]
            exitScript: "The Windows interface returned invalid duration tier settings; no Table was created."
        endif
    endif
    if (.durationIndex > 0 and (.durationIndex = .duration2Index or .durationIndex = .duration3Index)) or
    ... (.duration2Index > 0 and .duration2Index = .duration3Index) or
    ... (.intensity1Index > 0 and (.intensity1Index = .intensity2Index or .intensity1Index = .intensity3Index)) or
    ... (.intensity2Index > 0 and .intensity2Index = .intensity3Index)
        exitScript: "The Windows interface returned duplicate optional tiers; no Table was created."
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
    ui.duration2$ = ""
    ui.duration3$ = ""
    ui.intensityTier1$ = ""
    ui.intensityTier2$ = ""
    ui.intensityTier3$ = ""
    if .durationIndex > 0
        ui.vowelDur$ = wtTier$[.durationIndex]
    endif
    if .duration2Index > 0
        ui.duration2$ = wtTier$[.duration2Index]
    endif
    if .duration3Index > 0
        ui.duration3$ = wtTier$[.duration3Index]
    endif
    if .intensity1Index > 0
        ui.intensityTier1$ = wtTier$[.intensity1Index]
    endif
    if .intensity2Index > 0
        ui.intensityTier2$ = wtTier$[.intensity2Index]
    endif
    if .intensity3Index > 0
        ui.intensityTier3$ = wtTier$[.intensity3Index]
    endif
    ui.intensityMethod1 = number(.fields$#[19])
    ui.intensityMethod2 = number(.fields$#[20])
    ui.intensityMethod3 = number(.fields$#[21])
    ui.intensityPitch = number(.fields$#[22])
    ui.scale = number(.fields$#[8])
    ui.timeStep = number(.fields$#[9])
    ui.maxFormantHz = number(.fields$#[10])
    ui.numFormants = number(.fields$#[11])
    ui.windowLen = number(.fields$#[12])
    ui.preEmph = number(.fields$#[13])
endproc

include nestedTiers2Table.praat
