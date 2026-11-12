# Windows interface for the F1-F2 plot.
# The dialog (windows-ui\TablePlotUI.cs) only collects settings. Everything below
# validates them and draws through the same procedures as the Praat interface.

# Opens the dialog for the selected Table. Praat stays usable while it is open.
procedure windowsF1F2Launch
    if environment$("OS") != "Windows_NT"
        exitScript: "The Windows interface only runs on Windows. Use the Praat interface instead."
    endif
    .exe$ = preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe"
    if not fileReadable(.exe$)
        exitScript: "The Windows interface has not been built. Use the Praat interface instead."
    endif
    .callback$ = replace$(defaultDirectory$ + "/windowsF1F2Callback.praat", "\", "/", 0)
    if not fileReadable(.callback$)
        exitScript: "The Windows F1-F2 callback script was not found. Use the Praat interface instead."
    endif
    .tempDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/temp"
    if not folderExists(.tempDir$)
        createFolder: .tempDir$
    endif
    .tempDir$ += "/f1f2-ui"
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
    appendFileLine: .file$, "useInnerFactor", tab$, useInnerFactor
    appendFileLine: .file$, "f1Col", tab$, f1Col$
    appendFileLine: .file$, "f2Col", tab$, f2Col$
    appendFileLine: .file$, "inputUnits", tab$, inputUnits
    appendFileLine: .file$, "title", tab$, title$
    appendFileLine: .file$, "plotSize", tab$, plotSize
    appendFileLine: .file$, "minF1", tab$, minF1
    appendFileLine: .file$, "maxF1", tab$, maxF1
    appendFileLine: .file$, "minF2", tab$, minF2
    appendFileLine: .file$, "maxF2", tab$, maxF2
    appendFileLine: .file$, "showLegend", tab$, showLegend
    appendFileLine: .file$, "fontChoice", tab$, font_choice
    appendFileLine: .file$, "baseSize", tab$, (fontM - 8) / 2
    appendFileLine: .file$, "outputUnits", tab$, outputUnits
    appendFileLine: .file$, "tokenMarking", tab$, tokenMarking
    appendFileLine: .file$, "showMeans", tab$, showMeans
    appendFileLine: .file$, "ellipsisSDs", tab$, ellipsisSDs
    appendFileLine: .file$, "showArrows", tab$, showArrows
    appendFileLine: .file$, "dataPointsOnTop", tab$, dataPointsOnTop
    appendFileLine: .file$, "saveDir", tab$, saveDir$
    appendFileLine: .file$, "saveName", tab$, saveName$

    nocheck selectObject: .previous#
    asynchronous runSubprocess: .exe$, "TABLEPLOT", .file$, .tempDir$,
    ... preferencesDirectory$, .callback$, string$(.table)
endproc

# Runs inside Praat when the dialog asks for a plot (see windowsF1F2Callback.praat).
procedure windowsF1F2Run
    .tempDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/temp/f1f2-ui"
    .responseFile$ = .tempDir$ + "/f1f2-response-" + cbToken$ + ".txt"
    if not fileReadable(.responseFile$)
        exitScript: "The plot request from the Windows dialog could not be found."
    endif
    .response$ = readFile$(.responseFile$)
    deleteFile: .responseFile$
    @defineVars
    @windowsF1F2Apply: .response$
    if cbAction = 2
        @windowsF1F2Save: .tempDir$
    else
        @windowsF1F2Draw: .tempDir$
    endif
endproc

# Copies the dialog's settings into the variables the Praat interface would set.
procedure windowsF1F2Apply: .response$
    .allowed$ = " oFactor$ iFactor$ useInnerFactor f1Col$ f2Col$ inputUnits title$ " +
    ... "plotSize minF1 maxF1 minF2 maxF2 showLegend fontChoice baseSize outputUnits " +
    ... "tokenMarking showMeans ellipsisSDs showArrows coreLevelName$ dataPointsOnTop " +
    ... "saveDir$ saveName$ sorting changeAddColSch "
    keepCount = 0
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

    output_units = outputUnits
    show_legend = showLegend
    font_choice = fontChoice
    base_font_size = baseSize
    modify_colour_scheme = sorting
    save_folder$ = saveDir$
    save_name$ = saveName$
    add_or_change_colour_scheme = changeAddColSch
    @processShared_UIs
endproc

procedure windowsF1F2Draw: .tempDir$
    tableID$ = string$(cbTable)
    tableFormat = 1
    @validateTable: tableID$, "oFactor$,iFactor$,f1Col$,f2Col$"
    @windowsF1F2Filter
    @summariseFactor: table, oFactor$, "o"
    if useInnerFactor
        @summariseFactor: table, iFactor$, "i"
        .root$ = "i"
    else
        .root$ = "o"
    endif
    selectObject: table
    numFactors = Get number of columns
    for .i to numFactors
        factorName$[.i] = Get column label: .i
    endfor
    coreLevel = 0
    for .i to '.root$'Levels
        .level$ = '.root$'Level$[.i]
        if .level$ = coreLevelName$ and coreLevelName$ <> ""
            coreLevel = .i
        endif
    endfor

    .dir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/palettes/"
    .pause = changeAddColSch or makeNewColSeq or altColrMatch
    if .pause
        @hideObjs: "table", preferencesDirectory$ +
        ... "/plugin_AERoPlot/data/temp/", "hiddenTx"
    endif
    @setupColours: .dir$, "colrPalFile$", "curPalette", table, altColrMatch
    if .pause
        @retrieveObjs: "hiddenTx"
    endif

    @drawf1f2Plot
    removeObject: table

    viewPort$ = "'left', 'right', 'top' - 'titleAdjust', 'bottom'"
    writeFile: .tempDir$ + "/f1f2-view.txt", viewPort$, newline$, fontM, newline$

    # Same corrections the Praat interface makes before remembering the settings.
    coreLevel += 1
    ellipsisSDs += 1
    showMeans += 2
    tokenMarking += 1
    dataPointsOnTop += 1
    if !useInnerFactor
        iFactor$ = ""
    endif
    changeAddColSch = 0
    prevInputUnit = inputUnits
    @writeVars: preferencesDirectory$ +
    ... "/plugin_AERoPlot/data/vars/", "f1f1Plot.var"
endproc

# Removes the rows that do not match the levels ticked in the dialog.
procedure windowsF1F2Filter
    .columns$ = tab$
    for .i to keepCount
        if index(.columns$, tab$ + keepColumn$[.i] + tab$) = 0
            .columns$ += keepColumn$[.i] + tab$
        endif
    endfor
    .rest$ = .columns$
    .rest$ = mid$(.rest$, 2, length(.rest$))
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

# Saves the plot now shown in the Picture window.
procedure windowsF1F2Save: .tempDir$
    .viewFile$ = .tempDir$ + "/f1f2-view.txt"
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
    @dec2hex: date.index, "windowsF1F2Save.hexDate$"
    nowarn Viewport text: "Left", "Bottom", 0,
    ... "image ref. #" + plotPrefix$ + .hexDate$ + " " +
    ... "Created using AeroPlot (github.com/AERodgers/AERoplot)"
    Font size: .fontSize
    Black
    Save as 600-dpi PNG file: prepareImageSave.path$
endproc
