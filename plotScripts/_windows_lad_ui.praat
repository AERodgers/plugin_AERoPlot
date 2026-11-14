# Windows interface for the Ladefoged-style formant plot.
# The Windows dialog collects settings; Praat validates them and draws the plot.

procedure windowsLadLaunch
    if environment$("OS") != "Windows_NT"
        exitScript: "The Windows interface only runs on Windows. Use the Praat interface instead."
    endif
    .exe$ = preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe"
    if not fileReadable(.exe$)
        exitScript: "The Windows interface has not been built. Use the Praat interface instead."
    endif
    .callback$ = replace$(defaultDirectory$ + "/windowsLadefogedCallback.praat", "\", "/", 0)
    if not fileReadable(.callback$)
        exitScript: "The Windows Ladefoged callback script was not found. Use the Praat interface instead."
    endif
    .baseTemp$ = preferencesDirectory$ + "/plugin_AERoPlot/data/temp"
    if not folderExists(.baseTemp$)
        createFolder: .baseTemp$
    endif
    .tempDir$ = .baseTemp$ + "/lad-ui"
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
    appendFileLine: .file$, "f1Col", tab$, f1Col$
    appendFileLine: .file$, "f2Col", tab$, f2Col$
    appendFileLine: .file$, "f3Col", tab$, f3Col$
    appendFileLine: .file$, "f4Col", tab$, f4Col$
    appendFileLine: .file$, "inputUnits", tab$, inputUnits
    appendFileLine: .file$, "prevInputUnit", tab$, prevInputUnit
    appendFileLine: .file$, "title", tab$, title$
    appendFileLine: .file$, "maxFreq", tab$, maxFreq
    appendFileLine: .file$, "plotHeight", tab$, plotHeight
    appendFileLine: .file$, "xAxisFactor", tab$, xAxisFactor
    appendFileLine: .file$, "showLegend", tab$, showLegend
    appendFileLine: .file$, "legendHasFormants", tab$, legendHasFormants
    appendFileLine: .file$, "tokenMarking", tab$, tokenMarking
    appendFileLine: .file$, "addJitter", tab$, addJitter
    appendFileLine: .file$, "showAves", tab$, showAves
    appendFileLine: .file$, "showAveVals", tab$, showAveVals
    appendFileLine: .file$, "dataPointsOnTop", tab$, dataPointsOnTop
    appendFileLine: .file$, "showIQR", tab$, showIQR
    appendFileLine: .file$, "drawArrows", tab$, drawArrows
    appendFileLine: .file$, "staggerO", tab$, staggerO
    appendFileLine: .file$, "font_choice", tab$, font_choice
    appendFileLine: .file$, "baseSize", tab$, (fontM - 8) / 2
    appendFileLine: .file$, "outputUnits", tab$, outputUnits
    appendFileLine: .file$, "saveDir", tab$, saveDir$
    appendFileLine: .file$, "saveName", tab$, saveName$

    nocheck selectObject: .previous#
    asynchronous runSubprocess: .exe$, "TABLELAD", .file$, .tempDir$,
    ... preferencesDirectory$, .callback$, string$(.table)
endproc

procedure windowsLadRun
    .tempDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/temp/lad-ui"
    .responseFile$ = .tempDir$ + "/lad-response-" + cbToken$ + ".txt"
    if not fileReadable(.responseFile$)
        exitScript: "The plot request from the Windows dialog could not be found."
    endif
    .response$ = readFile$(.responseFile$)
    deleteFile: .responseFile$
    @defineVars
    @windowsLadApply: .response$
    if cbAction = 2
        @windowsLadSave: .tempDir$
    elsif cbAction = 4
        @windowsLadColours: .tempDir$
    else
        @windowsLadDraw: .tempDir$
    endif
endproc

procedure windowsLadApply: .response$
    .allowed$ = " oFactor$ iFactor$ f1Col$ f2Col$ f3Col$ f4Col$ inputUnits " +
    ... "title$ maxFreq plotHeight xAxisFactor$ showLegend legendHasFormants " +
    ... "tokenMarking addJitter showAves showAveVals dataPointsOnTop showIQR " +
    ... "drawArrows staggerO fontChoice baseSize outputUnits saveDir$ saveName$ " +
    ... "sorting changeAddColSch colourSession$ "
    keepCount = 0
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
            if .key$ = "keep"
                .tab = index(.value$, tab$)
                if .tab > 0
                    keepCount += 1
                    keepColumn$[keepCount] = left$(.value$, .tab - 1)
                    keepValue$[keepCount] = mid$(.value$, .tab + 1, length(.value$))
                endif
            elsif index(.allowed$, " " + .key$ + " ") > 0
                if right$(.key$, 1) = "$"
                    '.key$' = .value$
                else
                    '.key$' = number(.value$)
                endif
            endif
        endif
    endwhile

    inputUnits$[1] = "Hertz"
    inputUnits$[2] = "Bark"
    input_units = inputUnits
    output_units = outputUnits
    show_legend = showLegend
    font_choice = fontChoice
    base_font_size = baseSize
    modify_colour_scheme = sorting
    save_folder$ = saveDir$
    save_name$ = saveName$
    add_or_change_colour_scheme = changeAddColSch
    @processShared_UIs

    if showAves = 1
        ave$ = "mean"
    elsif showAves = 2
        ave$ = "med"
    endif
    showTail = showIQR
endproc

procedure windowsLadPrepare
    tableID$ = string$(cbTable)
    tableFormat = 1
    @validateTable: tableID$, "f1Col$,f2Col$,f3Col$,f4Col$,oFactor$,iFactor$"
    @windowsLadFilter

    if oFactor$ = ""
        selectObject: table
        Append column: "dummyInner"
        oFactor$ = "dummyInner"
    endif
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
    @summariseFactor: table, iFactor$, "i"
    @summariseFactor: table, oFactor$, "o"
    stagger = staggerO * 1 / oLevels

    xAxisOptions = 0
    selectObject: table
    for .i to numFactors
        @summariseFactor: table, factorName$[.i], "cur"
        if curLevels = iLevels
            xAxisOptions += 1
            xAxisOption$[xAxisOptions] = factorName$[.i]
            for .j to iLevels
                xAxisLevel$[xAxisOptions, .j] = curLevel$[.j]
            endfor
        endif
    endfor
    xAxisFactor = 1
    for .i to xAxisOptions
        if xAxisOption$[.i] = xAxisFactor$
            xAxisFactor = .i
        endif
    endfor
    xAxisFactor$ = xAxisOption$[xAxisFactor]
endproc

procedure windowsLadColours: .tempDir$
    if not index_regex(colourSession$, "^[a-f0-9]{32}$")
        exitScript: "The colour settings request was not valid."
    endif
    @windowsLadPrepare
    .dir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/palettes/"
    .matchFile$ = .tempDir$ + "/lad-colours-" + colourSession$ + ".txt"
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
        aeroLadColourRequest = 1
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

procedure windowsLadCancelColours
    @retrieveObjs: "hiddenTx"
    removeObject: table
    for .i to size(ladPrevious#)
        if .i = 1
            nocheck selectObject: ladPrevious#[.i]
        else
            nocheck plusObject: ladPrevious#[.i]
        endif
    endfor
    writeFile: preferencesDirectory$ + "/plugin_AERoPlot/data/temp/lad-ui/lad-complete-" + cbToken$ + ".txt", "CANCELLED"
endproc

procedure windowsLadDraw: .tempDir$
    if not index_regex(colourSession$, "^[a-f0-9]{32}$")
        exitScript: "The colour settings request was not valid."
    endif
    @windowsLadPrepare
    .dir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/palettes/"
    @setupColours: .dir$, "colrPalFile$", "curPalette", table, 0
    .matchFile$ = .tempDir$ + "/lad-colours-" + colourSession$ + ".txt"
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

    @doLadPlot
    selectObject: table
    for o to oLevels
        plusObject: plotTable[o]
        for i to iLevels
            if possRows.matrix##[o,i]
                plusObject: iTable[o,i]
            endif
        endfor
    endfor
    Remove
    for o to oLevels
        for i to iLevels
            for f to numFormants
                'ave$'FinPlot[o,i,f] = undefined
            endfor
        endfor
    endfor

    ellipsisSDs += 1
    showAves += 1
    changeAddColSch = 0
    tokenMarking += 1
    dataPointsOnTop += 1
    firstPass = 0
    prevInputUnit = inputUnits
    if oFactor$ = "dummyInner"
        oFactor$ = ""
    endif
    @writeVars: preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "ladPlot.var"
    .viewPort$ = "'left', 'right', 'top', 'bottom' + 'vertAdjust'"
    writeFile: .tempDir$ + "/lad-view.txt", .viewPort$, newline$, fontM, newline$
endproc

procedure windowsLadFilter
    .columns$ = tab$
    for .i to keepCount
        if index(.columns$, tab$ + keepColumn$[.i] + tab$) = 0
            .columns$ += keepColumn$[.i] + tab$
        endif
    endfor
    .rest$ = mid$(.columns$, 2, length(.columns$))
    while .rest$ <> ""
        .end = index(.rest$, tab$)
        .column$ = left$(.rest$, .end - 1)
        .rest$ = mid$(.rest$, .end + 1, length(.rest$))
        .keep$ = tab$
        for .i to keepCount
            if keepColumn$[.i] = .column$
                .keep$ += keepValue$[.i] + tab$
            endif
        endfor
        selectObject: table
        .rows = Get number of rows
        for .j to .rows
            .row = .rows + 1 - .j
            .value$ = Get value: .row, .column$
            if index(.keep$, tab$ + .value$ + tab$) = 0
                Remove row: .row
            endif
        endfor
    endwhile
    selectObject: table
    .left = Get number of rows
    if .left = 0
        removeObject: table
        exitScript: "No rows are left after filtering. Tick more levels and draw again."
    endif
endproc

procedure windowsLadSave: .tempDir$
    .viewFile$ = .tempDir$ + "/lad-view.txt"
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
    @dec2hex: date.index, "windowsLadSave.hexDate$"
    nowarn Viewport text: "Left", "Bottom", 0,
    ... "image ref. #" + plotPrefix$ + " " + .hexDate$ + " " +
    ... "Created using AeroPlot (github.com/AERodgers/AERoplot)"
    Font size: .fontSize
    Black
    Save as 600-dpi PNG file: prepareImageSave.path$
endproc