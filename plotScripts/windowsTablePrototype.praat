# Experimental Windows-only interface. The original action remains available.
aeroPrototypeInclude = 1

if not variableExists("aeroPrototypeTest")
    @runWindowsTablePrototype
endif

procedure runWindowsTablePrototype
    @checkPraatVersion
    if environment$("OS") != "Windows_NT"
        exitScript: "The AERoPlot Windows UI prototype only runs on Windows."
    endif
    if checkPraatVersion.major < 6 or (checkPraatVersion.major = 6 and
    ... (checkPraatVersion.minor < 4 or
    ... (checkPraatVersion.minor = 4 and checkPraatVersion.patch < 60)))
        exitScript: "The Windows UI prototype requires Praat 6.4.60 or newer. The original Table action is still available."
    endif
    .exe$ = preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe"
    if not fileReadable(.exe$)
        exitScript: "The Windows UI prototype has not been built. See the prototype instructions in the AERoPlot README."
    endif
    if size(selected#()) != 2 or numberOfSelected("Sound") != 1 or numberOfSelected("TextGrid") != 1
        exitScript: "Select exactly one Sound and one TextGrid."
    endif
    .sound = selected("Sound")
    .grid = selected("TextGrid")
    .soundName$ = selected$("Sound")
    .gridName$ = selected$("TextGrid")
    selectObject: .grid
    .numberOfTiers = Get number of tiers
    if .numberOfTiers = 0
        selectObject: .sound
        plusObject: .grid
        exitScript: "The selected TextGrid has no tiers."
    endif
    .tiers$ = ""
    for .i to .numberOfTiers
        .tier$[.i] = Get tier name: .i
        if .tier$[.i] = "" or .tier$[.i] = "?" or
        ... index_regex(.tier$[.i], "[,'""*?\t\n\r]") != 0 or
        ... index_regex(.tier$[.i], "(^[ ]|[ ]$|  )") != 0
            selectObject: .sound
            plusObject: .grid
            exitScript: "This prototype cannot use empty tier names, leading/trailing or repeated spaces, commas, quotes, wildcards, tabs, or line breaks. Use the original Table action instead."
        endif
        for .j to .i - 1
            if .tier$[.i] = .tier$[.j]
                selectObject: .sound
                plusObject: .grid
                exitScript: "The prototype requires unique tier names. Use the original Table action instead."
            endif
        endfor
        if .i > 1
            .tiers$ += newline$
        endif
        .tiers$ += .tier$[.i]
    endfor
    selectObject: .sound
    plusObject: .grid
    if length(.tiers$) + length(.soundName$) + length(.gridName$) > 20000
        exitScript: "The TextGrid's tier names are too long for the prototype. Use the original Table action instead."
    endif
    .response$ = runSubprocess$(.exe$, .soundName$, .gridName$, .tiers$)
    .fields$# = splitByWhitespace$#(.response$)
    if size(.fields$#) = 1
        if .fields$#[1] = "CANCEL"
            exit
        endif
    endif
    if size(.fields$#) != 5
        exitScript: "The Windows UI returned an invalid response; no Table was created."
    endif
    if .fields$#[1] != "OK" or index_regex(.fields$#[2], "^[A-Za-z][A-Za-z0-9_]*$") = 0
        exitScript: "The Windows UI returned invalid Table settings; no Table was created."
    endif
    if index_regex(.fields$#[3], "^[1-9][0-9]*$") = 0 or
    ... index_regex(.fields$#[4], "^[01]$") = 0
        exitScript: "The Windows UI returned invalid tier settings; no Table was created."
    endif
    .base = number(.fields$#[3])
    .times = number(.fields$#[4])
    if .base != round(.base) or .base < 1 or .base > .numberOfTiers or (.times != 0 and .times != 1)
        exitScript: "The Windows UI returned invalid tier settings; no Table was created."
    endif
    .hierarchy$ = .tier$[.base]
    if .fields$#[5] != "-"
        @csvLine2Array: .fields$#[5], "runWindowsTablePrototype.count", "runWindowsTablePrototype.index$"
        for .i to .count
            if index_regex(.index$[.i], "^[1-9][0-9]*$") = 0
                exitScript: "The Windows UI returned invalid tier settings; no Table was created."
            endif
            .index = number(.index$[.i])
            if .index != round(.index) or .index < 1 or .index > .numberOfTiers or .index = .base
                exitScript: "The Windows UI returned invalid tier settings; no Table was created."
            endif
            for .j to .i - 1
                if .index$[.i] = .index$[.j]
                    exitScript: "The Windows UI returned duplicate tiers; no Table was created."
                endif
            endfor
            .hierarchy$ += "," + .tier$[.index]
        endfor
    endif
    @prototypeConvert: .grid, .hierarchy$, .fields$#[2], .times
endproc

procedure prototypeConvert: .grid, .hierarchy$, .name$, .times
    ui.baseTierTimeOnly = .times
    ui.formants2tabulate = 0
    ui.vowelDur$ = ""
    ui.formantTier$ = ""
    @tiers2Table: .grid, .hierarchy$, "prototypeResult"
    selectObject: prototypeResult
    Rename: .name$
endproc

include nestedTiers2Table.praat
