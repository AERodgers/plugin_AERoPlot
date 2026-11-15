# The Windows dialog collects settings; Praat validates and draws the plot.
procedure windowsFoTLaunch
    if environment$("OS") != "Windows_NT"
        exitScript: "The Windows interface only runs on Windows. Use the Praat interface instead."
    endif
    .exe$ = preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe"
    if not fileReadable(.exe$)
        exitScript: "The Windows interface is missing. Use the Praat interface instead."
    endif
    .callback$ = replace$(defaultDirectory$ + "/windowsFoTCallback.praat", "\", "/", 0)
    if not fileReadable(.callback$)
        exitScript: "The Windows formants-over-time callback script was not found."
    endif
    .tempDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/temp"
    if not folderExists(.tempDir$)
        createFolder: .tempDir$
    endif
    .tempDir$ += "/fot-ui"
    if not folderExists(.tempDir$)
        createFolder: .tempDir$
    endif

    .previous# = selected#()
    .table = selected("Table")
    .name$ = selected$("Table")
    @defineVars
    if title$ = "Example nIE vowel and dipthongs" and .name$ <> "aer_ni_i"
        title$ = ""
    endif
    selectObject: .table
    .tableFile$ = .tempDir$ + "/table-" + string$(.table) + ".tsv"
    Save as tab-separated file: .tableFile$
    .file$ = .tempDir$ + "/settings-" + string$(.table) + ".txt"
    writeFileLine: .file$, "tableFile", tab$, .tableFile$
    appendFileLine: .file$, "tableName", tab$, .name$
    appendFileLine: .file$, "oFactor", tab$, oFactor$
    appendFileLine: .file$, "iFactor", tab$, iFactor$
    appendFileLine: .file$, "timeCol", tab$, timeCol$
    appendFileLine: .file$, "repFactor", tab$, repFactor$
    for .i to 4
        appendFileLine: .file$, "f", .i, "Col", tab$, f'.i'Col$
    endfor
    appendFileLine: .file$, "inputUnits", tab$, inputUnits
    appendFileLine: .file$, "prevInputUnit", tab$, prevInputUnit
    appendFileLine: .file$, "timeRelativeTo", tab$, timeRelativeTo
    appendFileLine: .file$, "coreLevel", tab$, coreLevel
    appendFileLine: .file$, "title", tab$, title$
    appendFileLine: .file$, "maxFreq", tab$, maxFreq
    appendFileLine: .file$, "plotWidth", tab$, plotWidth
    appendFileLine: .file$, "plotHeight", tab$, plotHeight
    appendFileLine: .file$, "showLegend", tab$, showLegend
    appendFileLine: .file$, "tokenMarking", tab$, tokenMarking
    appendFileLine: .file$, "addJitter", tab$, addJitter
    appendFileLine: .file$, "showLines", tab$, showLines
    appendFileLine: .file$, "ellipsisSDs", tab$, ellipsisSDs
    appendFileLine: .file$, "dataPointsOnTop", tab$, dataPointsOnTop
    appendFileLine: .file$, "font_choice", tab$, font_choice
    appendFileLine: .file$, "baseSize", tab$, (fontM - 8) / 2
    appendFileLine: .file$, "outputUnits", tab$, outputUnits
    appendFileLine: .file$, "saveDir", tab$, saveDir$
    appendFileLine: .file$, "saveName", tab$, saveName$
    nocheck selectObject: .previous#
    asynchronous runSubprocess: .exe$, "TABLEFOT", .file$, .tempDir$,
    ... preferencesDirectory$, .callback$, string$(.table)
endproc

procedure windowsFoTRun
    .tempDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/temp/fot-ui"
    .responseFile$ = .tempDir$ + "/fot-response-" + cbToken$ + ".txt"
    if not fileReadable(.responseFile$)
        exitScript: "The plot request from the Windows dialog could not be found."
    endif
    .response$ = readFile$(.responseFile$)
    deleteFile: .responseFile$
    @defineVars
    @windowsLadApply: .response$
    @windowsFoTApply: .response$
    if cbAction = 2
        @windowsFoTSave: .tempDir$
    elsif cbAction = 4
        @windowsFoTColours: .tempDir$
    else
        @windowsFoTDraw: .tempDir$
    endif
endproc

procedure windowsFoTApply: .response$
    .allowed$ = " timeCol$ repFactor$ referenceLevel$ coreLevelName$ plotWidth ellipsisSDs showLines "
    referenceLevel$ = ""
    coreLevelName$ = ""
    .rest$ = .response$
    while .rest$ <> ""
        .end = index(.rest$, newline$)
        if .end = 0
            .line$ = .rest$
            .rest$ = ""
        else
            .line$ = left$(.rest$, .end - 1)
            .rest$ = mid$(.rest$, .end + 1, length(.rest$))
        endif
        .tab = index(.line$, tab$)
        if .tab > 0
            .key$ = left$(.line$, .tab - 1)
            .value$ = mid$(.line$, .tab + 1, length(.line$))
            if index(.allowed$, " " + .key$ + " ") > 0
                if right$(.key$, 1) = "$"
                    '.key$' = .value$
                else
                    '.key$' = number(.value$)
                endif
            endif
        endif
    endwhile
endproc

procedure windowsFoTPrepare
    tableID$ = string$(cbTable)
    tableFormat = 1
    @validateTable: tableID$,
    ... "timeCol$,f1Col$,f2Col$,f3Col$,f4Col$,oFactor$,iFactor$,repFactor$"
    if referenceLevel$ <> ""
        # Keep the reference rows until after time has been adjusted, even if
        # their sequencing level is not included in the plotted data.
        .savedCount = keepCount
        for .i to .savedCount
            .savedColumn$[.i] = keepColumn$[.i]
            .savedValue$[.i] = keepValue$[.i]
        endfor
        keepCount = 0
        for .i to .savedCount
            if .savedColumn$[.i] <> iFactor$
                keepCount += 1
                keepColumn$[keepCount] = .savedColumn$[.i]
                keepValue$[keepCount] = .savedValue$[.i]
            endif
        endfor
        @windowsLadFilter
        @makeTimeRelative: table, oFactor$, iFactor$, timeCol$, repFactor$, referenceLevel$
        keepCount = 0
        for .i to .savedCount
            if .savedColumn$[.i] = iFactor$
                keepCount += 1
                keepColumn$[keepCount] = .savedColumn$[.i]
                keepValue$[keepCount] = .savedValue$[.i]
            endif
        endfor
    endif
    @windowsLadFilter
    selectObject: table
    numFactors = Get number of columns
    for .i to numFactors
        factorName$[.i] = Get column label: .i
    endfor
    numFormants = 0
    for .i to 4
        if f'.i'Col$ <> ""
            numFormants += 1
            formant2Plot[numFormants] = .i
        endif
    endfor
    @summariseFactor: table, oFactor$, "o"
    @checkMax50: oLevels, table, oFactor$, 1
    @summariseFactor: table, iFactor$, "i"
    @checkMax50: iLevels, table, iFactor$, 1
    coreLevel = 0
    for .i to iLevels
        if iLevel$[.i] = coreLevelName$ and coreLevelName$ <> ""
            coreLevel = .i
        endif
    endfor
endproc

procedure windowsFoTColours: .tempDir$
    if not index_regex(colourSession$, "^[a-f0-9]{32}$")
        exitScript: "The colour settings request was not valid."
    endif
    @windowsFoTPrepare
    .dir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/palettes/"
    .matchFile$ = .tempDir$ + "/fot-colours-" + colourSession$ + ".txt"
    if modify_colour_scheme = 6
        .default$ = .dir$ + "Adjusted_CB_Qualitative_Set1.palette"
        if not fileReadable(.default$)
            exitScript: "The original default colour palette could not be found."
        endif
        writeFile: .dir$ + "current.palette", readFile$(.default$)
    endif
    .pause = changeAddColSch or makeNewColSeq or altColrMatch
    if .pause
        @hideObjs: "table", preferencesDirectory$ + "/plugin_AERoPlot/data/temp/", "hiddenTx"
        aeroFoTColourRequest = 1
    endif
    @setupColours: .dir$, "colrPalFile$", "curPalette", table, altColrMatch
    if .pause
        @retrieveObjs: "hiddenTx"
    endif
    if altColrMatch
        writeFileLine: .matchFile$, oFactor$
        for .i to oLevels
            appendFileLine: .matchFile$, oLevel$[.i], tab$, oColour[.i]
        endfor
    elsif (modify_colour_scheme <> 1 or changeAddColSch) and fileReadable(.matchFile$)
        deleteFile: .matchFile$
    endif
    removeObject: table
endproc

procedure windowsFoTCancelColours
    @retrieveObjs: "hiddenTx"
    removeObject: table
    for .i to size(fotPrevious#)
        if .i = 1
            nocheck selectObject: fotPrevious#[.i]
        else
            nocheck plusObject: fotPrevious#[.i]
        endif
    endfor
    writeFile: preferencesDirectory$ + "/plugin_AERoPlot/data/temp/fot-ui/fot-complete-" + cbToken$ + ".txt", "CANCELLED"
endproc

procedure windowsFoTDraw: .tempDir$
    if not index_regex(colourSession$, "^[a-f0-9]{32}$")
        exitScript: "The colour settings request was not valid."
    endif
    @windowsFoTPrepare
    .dir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/palettes/"
    @setupColours: .dir$, "colrPalFile$", "curPalette", table, 0
    .matchFile$ = .tempDir$ + "/fot-colours-" + colourSession$ + ".txt"
    if fileReadable(.matchFile$)
        .matches = Read Strings from raw text file: .matchFile$
        .factor$ = Get string: 1
        if .factor$ = oFactor$
            .count = Get number of strings
            for .j from 2 to .count
                .line$ = Get string: .j
                .tab = index(.line$, tab$)
                if .tab > 0
                    .level$ = left$(.line$, .tab - 1)
                    .colour = number(mid$(.line$, .tab + 1, length(.line$)))
                    for .i to oLevels
                        if oLevel$[.i] = .level$ and .colour >= 1 and .colour <= curPaletteSize
                            oColour[.i] = .colour
                        endif
                    endfor
                endif
            endfor
        endif
        removeObject: .matches
    endif
    for o to oLevels
        for i to iLevels
            meanTinPlot[o,i] = undefined
            meanTAct[o,i] = undefined
            stDevTAct[o,i] = undefined
            for f to numFormants
                meanFinPlot[o,i,f] = undefined
                prevMeanFinPlot[o,i,f] = undefined
                meanFAct[o,i,f] = undefined
                stDevFAct[o,i,f] = undefined
            endfor
        endfor
    endfor
    @doFOTPlot
    selectObject: table
    for o to oLevels
        plusObject: plotTable[o]
    endfor
    Remove
    # Remember level positions in the original table, not the filtered copy.
    @summariseFactor: cbTable, iFactor$, "original"
    coreLevel = 1
    timeRelativeTo = 0
    for .i to originalLevels
        if coreLevelName$ <> "" and originalLevel$[.i] = coreLevelName$
            coreLevel = .i + 1
        endif
        if referenceLevel$ <> "" and originalLevel$[.i] = referenceLevel$
            timeRelativeTo = .i
        endif
    endfor
    ellipsisSDs += 1
    tokenMarking += 1
    dataPointsOnTop += 1
    changeAddColSch = 0
    firstPass = 0
    prevInputUnit = inputUnits
    @writeVars: preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "fotPlot.var"
    .view$ = "'left', 'right', 'top', 'bottom' + 'vertAdjust'"
    writeFile: .tempDir$ + "/fot-view-" + colourSession$ + ".txt", .view$, newline$, fontM, newline$
endproc

procedure windowsFoTSave: .tempDir$
    if not index_regex(colourSession$, "^[a-f0-9]{32}$")
        exitScript: "The save request was not valid."
    endif
    .viewFile$ = .tempDir$ + "/fot-view-" + colourSession$ + ".txt"
    if not fileReadable(.viewFile$)
        exitScript: "There is no plot to save yet. Press Draw first."
    endif
    .text$ = readFile$(.viewFile$)
    .end = index(.text$, newline$)
    .view$ = left$(.text$, .end - 1)
    .fontSize = number(mid$(.text$, .end + 1, length(.text$)))
    @prepareImageSave: saveDir$, saveName$
    Select inner viewport: '.view$'
    Font size: 2
    Colour: { 0.96, 0.96, 0.96 }
    @date
    @dec2hex: date.index, "windowsFoTSave.hexDate$"
    nowarn Viewport text: "Left", "Bottom", 0,
    ... "image ref. #" + plotPrefix$ + " " + .hexDate$ + " " +
    ... "Created using AeroPlot (github.com/AERodgers/AERoplot)"
    Font size: .fontSize
    Black
    Save as 600-dpi PNG file: prepareImageSave.path$
endproc
