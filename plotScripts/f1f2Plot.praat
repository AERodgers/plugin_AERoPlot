# F1F2 Plotter
# ============
# A feature of the AERoplot plugin.
#
# Written for Praat 6.0.40 or later
#
# script by Antoin Eoin Rodgers
# Phonetics and speech Laboratory, Trinity College Dublin
# July 16th, 2020 (my parents' 60th wedding anniversary! Congratulations them!)
#
# email:     rodgeran@tcd.ie
# twitter:   @phonetic_antoin
# github:    github.com/AERodgers

@checkPraatVersion
@objsSelected: "Table", "tableID$"
@purgeDirFiles: "../data/temp"

curF1f2Version$ = "1.4.0.0"
plotPrefix$ = "F12."
# Main script loop
keepGoing = 1
while keepGoing
    @defineVars
    if keepGoing = 1
        @doInputUI
    endif
    @validateTable:
        ... tableID$,
        ... "'oFactor$', 'iFactor$', 'f1Col$', 'f2Col$'"
    @processInputUI

    @doOutputUI
    @hideObjs: "table", "../data/temp/", "hiddenTx"
    @setupColours:
    ... "../data/palettes/", "colrPalFile$",
    ... "curPalette", table, altColrMatch
    @retrieveObjs: "hiddenTx"

    @drawf1f2Plot

    removeObject: table


    # VARIABLE CORRECTION
    # correct local input flags
    coreLevel += 1
    ellipsisSDs += 1
    showMeans += 2
    if !useInnerFactor
        iFactor$ = ""
    endif
    # correct global menu flags
    changeAddColSch = 0
    tokenMarking += 1
    dataPointsOnTop += 1
    keepGoing = plotUses
    firstPass = 0
    @writeVars: "../data/vars/", "f1f1Plot.var"
    viewPort$ =  "'left', 'right', 'top' - 'titleAdjust', 'bottom'"
    @saveImage: saveDir$, saveName$, quality, viewPort$, fontM, plotPrefix$
    if variableExists("tableID$")
        if string$(number(tableID$)) = tableID$
            selectObject: 'tableID$'
        endif
    endif
endwhile


# UI and input processing procedures
procedure doInputUI
    done = 0
    comment$ = ""
    while ! done
        beginPause: "F1-F2 plotter: input settings"
        comment: comment$

            @addShared_UI_0: "Context", "Element"

            comment: "GROUPING FACTORS (COLUMN HEADERS)"
            #sentence Main_factor (determines colour)
            #sentence Secondary_factor (used for grouping by sub-category)
            sentence: "Main factor (determines colour)", oFactor$
            boolean: "Use secondary factor", useInnerFactor
            sentence: "Secondary factor (sub-category)", iFactor$
            boolean: "Use tertiary filters (remove unwanted data)",
            ... tertiaryFilters
            comment: "FORMANT COLUMNS"
            sentence: "F2 Column", f2Col$
            sentence: "F1 Column", f1Col$
            optionMenu: "Input units", inputUnits
                option: "Hertz"
                option: "Bark"


            @addShared_UI_1

        myChoice = endPause: "Exit", "Apply", 2, 1
        # respond to myChoice
        if myChoice = 1
            @selectTableID
            exit
        endif
        if !use_secondary_factor
            secondary_factor$ = ""
        endif

        # error handling
        done =
        ... !(
        ... object_number_or_file_path$ = "" or
        ... main_factor$ = "" or
        ... (secondary_factor$ = "" and use_secondary_factor) or
        ... f2_Column$ = "" or f1_Column$ = ""
        ... )
        comment$ =
        ... "Please ensure you FILL IN all the NECESSARY BOXES."
    endwhile

    # Simplify input variables
    @processShared_UI_0
    oFactor$ = main_factor$
    iFactor$ = secondary_factor$
    if oFactor$ = iFactor$
        iFactor$ = ""
    endif
    useInnerFactor = use_secondary_factor
        ... and iFactor$ != ""
    f1Col$ = f1_Column$
    f2Col$ = f2_Column$
    tertiaryFilters = use_tertiary_filters
    inputUnits = input_units
    inputUnits$[1] = "Hertz"
    inputUnits$[2] = "Bark"

    # change default min and max F1, F2 if input scale has changed.
    if inputUnits = 1 and prevInputUnit = 2
        minF1 = 150
        maxF1 = 1400
        minF2 = 500
        maxF2 = 3800
    elsif inputUnits = 2 and prevInputUnit = 1
        minF1 = 1
        maxF1 = 10
        minF2 = 4
        maxF2 = 16
    endif
    prevInputUnit = inputUnits
endproc

procedure processInputUI
    newStateIsOldOne = x_tableID$ = tableID$ and
                   ... oFactor$ = x_oFactor$

    selectObject: table
    numFactors = Get number of columns
    for i to numFactors
        factorName$[i] = Get column label: i
    endfor

    # UI for outer factor
    # first pass on oFactor
    @summariseFactor:  table, oFactor$, "o"
    @checkMax50: oLevels, table, oFactor$, 1
    @filterLevels: table, oFactor$, "o", "newStateIsOldOne"
    table = filterLevels.table

    # First pass on iFactor
    if useInnerFactor
        @summariseFactor: table, iFactor$, "i"
        @checkMax50: iLevels, table, iFactor$, 1
        @filterLevels: table, oFactor$, "i", "newStateIsOldOne"
        table = filterLevels.table
    endif

    # run tertiary filter UI first to remove unwanted items
    if tertiaryFilters
        @filterTertFactors: table, "factorName$", numFactors,
            ... "../data/vars/",
            ... "fpTertFactor.var",
            ... "'oFactor$', 'iFactor$', 'f1Col$', 'f2Col$'"
        table = filterTertFactors.table

        # recalculate outer levels based on purged table
        @summariseFactor: table, oFactor$, "o"
        # recalculate inner levels based on purged table
        if useInnerFactor
            @summariseFactor: table, iFactor$, "i"
        endif
    endif
endproc

procedure doOutputUI
    if useInnerFactor
        varRoot$ = "i"
    else
        varRoot$ = "o"
    endif
    if tableID$ != x_tableID$
        tokenMarking = 1
        showMeans = 2
        coreLevel = 1
    endif

    @hideObjs: "table", "../data/temp/", "hiddenTx"
    beginPause: "Graphical Output Settings"
        comment: "PLOT BASICS"
        sentence: "Title", title$
        positive: "Interior plot size (inches)", plotSize
        @addShared_UI_2
        comment: "F1-F2 formant plot ranges (in "
            ... + inputUnits$[inputUnits] + ".)"
            natural: "F1 minimum", minF1
            natural: "F1 maximum", maxF1
            natural: "F2 minimum", minF2
            natural: "F2 maximum", maxF2

        comment: "PLOT LAYERS"

        optionMenu: "Mark individual data points using", tokenMarking
            option: "x symbol"
            for i to numFactors
                option: factorName$[i]
            endfor
            option: "Nothing"
        optionMenu: "Show means", showMeans
            option: "Don't show means."
            option: "... without text"
                    for i to numFactors
                option: "... with " + factorName$[i] + " text"
            endfor

        optionMenu: "Core " + 'varRoot$'Factor$, coreLevel
            option: "None"
            for i to 'varRoot$'Levels
                option: 'varRoot$'Level$[i]
            endfor

        optionMenu: "Most prominent layer", dataPointsOnTop
            option: "Mean values"
            option: "data points"

        optionMenu: "Draw ellipses", ellipsisSDs
            option: "No Ellipses"
            option: "One standard deviation"
            option: "Two standard deviations"
        boolean: "Show arrows", showArrows
        @addShared_UI_3
    myChoice = endPause: "Exit", "Continue", 2, 1
    if myChoice = 1
        @selectTableID
        exit
    endif
    @retrieveObjs: "hiddenTx"

    # Process generic outoutUI
    @processShared_UIs
    dataPointsOnTop = most_prominent_layer - 1
    plotSize = interior_plot_size
    outputUnits = output_units
    minF1 = f1_minimum
    maxF1 = f1_maximum
    minF2 = f2_minimum
    maxF2 = f2_maximum
    showMeans = show_means - 2
    ellipsisSDs = draw_ellipses - 1
    tokenMarking = mark_individual_data_points_using - 1
    showArrows = show_arrows
    coreLevel$ = "core_" +
    ...replace_regex$('varRoot$'Factor$, "[^A-Za-z0-9]", "_", 0)
    coreLevel = 'coreLevel$' - 1
endproc


# Main drawing procedure
procedure drawf1f2Plot
    @resetDrawSpace: fontM
    @calculateAxisIncrements
    @doF1F2AxisLayer
    @doPlotInterior
    if showLegend and variableExists("legend.items")
        @drawLegendLayer: majorT_Max, majorT_Min,
             ... majorR_Max, majorR_Min,
             ... fontM, "left, right, top, bottom",
             ... table, "F2DrawValue", "F1DrawValue",
             ... legBlockTolerance, bufferZone, 1, 0, -1
    endif
    @drawTitleLayer
endproc


# Plot calculation and plot table management procedures
procedure calculateAxisIncrements
    if inputUnits = 1
        minorRDist = 50
        majorRDist = 100
        minorTDist = 100
        majorTDist = 500
        horAdjust = 0.125
        vertAdjust = 0.15
        titleAdjust = vertAdjust + 0.3
    else
        minorRDist = 0.5
        majorRDist = 2
        minorTDist = 0.5
        majorTDist = 2
        horAdjust = 0.25
        vertAdjust = 0
        titleAdjust = vertAdjust + 0.3
    endif
endproc

procedure createSubTables

    # calculate potential tables
    @possRows: table, "o", "i", useInnerFactor

    for o to oLevels
        #add to legend arrays
        curColVector$ = curPaletteVector$[oColour[o]]
        curColName$ = curPaletteName$[oColour[o]]
        @legend: "R", curColVector$, oLevel$[o], 4
        prevMeanF1 = 0
        prevMeanF2 = 0
        for i to iLevels
            # create sub-table
            if useInnerFactor
                subInnerFactor$ = iFactor$
                subiLevel$[i] = iLevel$[i]
                subOuterFactor$ = oFactor$
                suboLevel$[o] = oLevel$[o]
            else
                subInnerFactor$ = oFactor$
                subiLevel$[i] = oLevel$[o]
                subOuterFactor$ = oFactor$
                suboLevel$[o] = oLevel$[o]
            endif

            if possRows.matrix##[o,i]
                selectObject: table
                iLevelTable[o, i] = Extract rows where:
                    ... "self$[subInnerFactor$] = subiLevel$[i] and " +
                    ... "self$[subOuterFactor$] = suboLevel$[o]"
            else
                iLevelTable[o, i] = undefined
            endif
        endfor
    endfor
endproc

procedure removeTables
    for o to oLevels
        for i to iLevels
            if possRows.matrix##[o,i]
                removeObject: iLevelTable[o, i]
            endif
        endfor
    endfor
endproc


# Plot layer Procedures
procedure doF1F2AxisLayer
    # set frame variables
    left = 0.7
    top = 0.92
    right = left + plotSize
    bottom = top + plotSize

    Select inner viewport: left, right, top - vertAdjust, bottom
    Text top: "yes", "F2 in " + outputUnits$[outputUnits]
    Select inner viewport: left, right - horAdjust, top, bottom
    Text right: "yes", "F1 in " + outputUnits$[outputUnits]
    Select inner viewport: left, right, top, bottom

    incCur = minorRDist
    selectObject: table
    @getOutputScales:
    ...table, "'f1Col$','f2Col$'",
    ... minF1, maxF1, minorRDist,
    ... outScaleUnit, useKHz,
    ... "minorR_"
    @getOutputScales: table, "'f1Col$','f2Col$'",
    ... minF1, maxF1, majorRDist,
    ... outScaleUnit, useKHz,
    ... "majorR_"
    @getOutputScales: table, "'f1Col$','f2Col$'",
    ... minF2, maxF2, minorTDist,
    ... outScaleUnit, useKHz,
    ... "minorT_"
    @getOutputScales: table, "'f1Col$','f2Col$'",
    ... minF2, maxF2, majorTDist,
    ... outScaleUnit, useKHz,
    ... "majorT_"

    Axes: majorT_Max, majorT_Min, majorR_Max, majorR_Min
    xDist = Horizontal mm to world coordinates: 0.1
    yDist = Vertical mm to world coordinates: 0.1
    lineColour$[1] = lightLine$
    lineColour$[2] = darkLine$

    # Draw minor horizontal lines
    Colour: lineColour$[1]
    Line width: axisLine[1]
    for line to minorR_Lines
        Draw line: majorT_Min, minorR_DrawVal[line],
        ... majorT_Max, minorR_DrawVal[line]
    endfor
    # Draw minor vertical lines
    Colour: lineColour$[1]
    Line width: axisLine[1]
    for line to minorT_Lines
        Draw line: minorT_DrawVal[line], majorR_Min,
               ... minorT_DrawVal[line], majorR_Max
    endfor
    # draw major horizontal lines
    Colour: lineColour$[2]
    Line width: axisLine[2]
    for line to majorR_Lines
        Draw line: majorT_Min, majorR_DrawVal[line],
        ... majorT_Max, majorR_DrawVal[line]
        Colour: "Black"
        Text: majorT_Min, "left",
        ... majorR_DrawVal[line], "Half",
        ... string$(majorR_AxisVal[line])
    endfor
    # Draw Major Vertical Lines
    Colour: lineColour$[2]
    Line width: axisLine[2]
    for line to majorT_Lines
        Draw line: majorT_DrawVal[line], majorR_Min,
        ... majorT_DrawVal[line], majorR_Max
        Colour: "Black"
        Text special: majorT_DrawVal[line], "Left",
        ... majorR_Min, "Half",
        ... font$, fontM, "90",
        ... string$(majorT_AxisVal[line])
    endfor

    # Draw graph frame
    Line width: 1
    Colour: "Black"
    Draw inner box
endproc

procedure doPlotInterior
    # set up viewport
    Font size: fontM
    Select inner viewport: left, right, top, bottom

    # prepare mean text Column
    if showMeans > 0
        selectObject: table
        Append column: "meansText"
        Formula: "meansText", "self$[factorName$[showMeans]]"
    endif

    # correct arrays if no iFactor
    if not useInnerFactor or iFactor$ = oFactor$
        iLevels = oLevels
        iFactor$ = oFactor$
        for i to iLevels
            iLevel$[i] = oLevel$[i]
        endfor
    endif

    selectObject: table
    if tokenMarking < numFactors and tokenMarking
        Append column: "token"
        Formula: "token", """##"" + self$[factorName$[tokenMarking]]"
    endif

    #create column for shading and spacing
    Axes: majorT_Max, majorT_Min, majorR_Max, majorR_Min
    xDiff = Horizontal mm to world coordinates: 0.1
    yDiff = Vertical mm to world coordinates: 0.1
    Append column: "F1Adj"
    Append column: "F2Adj"
    Formula: "F2Adj", "self[""F2DrawValue""] + xDiff"
    Formula: "F1Adj", "self[""F1DrawValue""] - yDiff"

    if !useInnerFactor
        iLevels = 1
    endif
    @createSubTables
    @doEllipses
    @doArrows
    if dataPointsOnTop
        @doMeansText
        @doScatterplots
    else
        @doScatterplots
        @doMeansText
    endif
    @removeTables
endproc

procedure doEllipses
    for o to oLevels
        # set current colours
        curColVector$ = curPaletteVector$[oColour[o]]
        curColName$ = curPaletteName$[oColour[o]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"
        for i to iLevels

            # set criteria for drawing ellipses based on useInnerFactor.
            if useInnerFactor
                criteria$ =
                ... "self$[subInnerFactor$] = subiLevel$[i]"
            else
                criteria$ = "1"
            endif

            if possRows.matrix##[o,i]
                selectObject: iLevelTable[o, i]
                curMeanF1 = Get mean: "F1DrawValue"
                curMeanF2 = Get mean: "F2DrawValue"
                # draw ellipses
                if ellipsisSDs
                    Line width: 4
                    if mean('curColour$[4]' * colrAdj#) < 0.19567
                        Colour: 'curColour$[5]'
                    else
                        Colour:  'curColour$[2]'
                    endif
                    nowarn Draw ellipses where:
                    ... "F2DrawValue", majorT_Max, majorT_Min,
                    ... "F1DrawValue", majorR_Max, majorR_Min,
                    ... subInnerFactor$,  ellipsisSDs, 0, "no",
                    ... criteria$
                    Line width: 2
                    Colour: curColour$[4]
                    nowarn Draw ellipses where:
                    ... "F2DrawValue", majorT_Max, majorT_Min,
                    ... "F1DrawValue", majorR_Max, majorR_Min,
                    ... subInnerFactor$,  ellipsisSDs, 0, "no",
                    ... criteria$
                endif
            endif
        endfor
    endfor
endproc

procedure doArrows
    for o to oLevels
        # set current colours
        curColVector$ = curPaletteVector$[oColour[o]]
        curColName$ = curPaletteName$[oColour[o]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"
        prevMeanF1 = 0
        prevMeanF2 = 0
        for i to iLevels
            if possRows.matrix##[o,i]
                selectObject: iLevelTable[o, i]
                hasRows = Get number of rows
                if hasRows
                    curMeanF1 = Get mean: "F1DrawValue"
                    curMeanF2 = Get mean: "F2DrawValue"
                    #Draw arrows
                    if showArrows and prevMeanF1
                        gap =  1 - arrowRatio
                        xStart = prevMeanF2 + gap / 3 * (curMeanF2 - prevMeanF2)
                        yStart = prevMeanF1 + gap / 3 * (curMeanF1 - prevMeanF1)
                        xEnd =
                        ... curMeanF2 - gap * 2 / 3 * (curMeanF2 - prevMeanF2)
                        yEnd =
                        ... curMeanF1 - gap * 2 / 3 * (curMeanF1 - prevMeanF1)
                        Line width: 4
                        Arrow size: 1.05
                        if mean('curColour$[4]' * colrAdj#) < 0.19567
                            Colour: 'curColour$[5]'
                        else
                            Colour:  'curColour$[2]'
                        endif
                        Draw arrow: xStart, yStart, xEnd, yEnd
                        Line width: 2
                        Arrow size: 1
                        Colour: curColour$[4]
                        Draw arrow: xStart, yStart, xEnd, yEnd
                    endif
                    prevMeanF1 = curMeanF1
                    prevMeanF2 = curMeanF2
                endif
            endif
        endfor
    endfor
endproc

procedure doScatterplots
    for o to oLevels
        # set current colours
        curColVector$ = curPaletteVector$[oColour[o]]
        curColName$ = curPaletteName$[oColour[o]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"
        for i to iLevels
            # set draw criters depending on useInnerFactor
            if useInnerFactor
                criteria$ = "self$[subInnerFactor$] = subiLevel$[i]"
            else
                criteria$ = "1"
            endif
            if possRows.matrix##[o,i]
                selectObject: iLevelTable[o, i]
                # Draw scatter plot
                # colour brightness weights based on:
                # https://www.w3.org/TR/AERT/#color-contrast
                # threshold value = 587 / 3, assuming anything
                # brighter than [0,1,0] needs a dark shadow
                if mean('curColour$[2]' * colrAdj#) < 0.19567
                    Colour: 'curColour$[2]' + 0.8
                else
                    Colour:  'curColour$[2]' - 0.5
                endif
                if !tokenMarking
                    Line width: 4
                    nowarn Scatter plot where (mark):
                    ... "F2DrawValue", majorT_Max, majorT_Min,
                    ... "F1DrawValue", majorR_Max, majorR_Min,
                    ... fontM / 5, "no", "x", criteria$
                elsif tokenMarking < numFactors
                    nowarn Scatter plot where:
                    ... "F2Adj", majorT_Max, majorT_Min,
                    ... "F1Adj", majorR_Max, majorR_Min,
                    ... "token", fontM, "no", criteria$
                endif
                Colour: curColour$[1]
                if !tokenMarking
                    Line width: 2
                     nowarn Scatter plot where (mark):
                    ... "F2DrawValue", majorT_Max, majorT_Min,
                    ... "F1DrawValue", majorR_Max, majorR_Min,
                    ... fontM / 5, "no", "x", criteria$
                elsif tokenMarking < numFactors
                    nowarn Scatter plot where: "F2DrawValue",
                    ... majorT_Max, majorT_Min,
                    ... "F1DrawValue", majorR_Max, majorR_Min,
                    ... factorName$[tokenMarking], fontM, "no", criteria$
                endif
            endif
        endfor
    endfor
endproc

procedure doMeansText
    for o to oLevels
        # set current colours
        curColVector$ = curPaletteVector$[oColour[o]]
        curColName$ = curPaletteName$[oColour[o]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"
        for i to iLevels
            if possRows.matrix##[o,i]
                selectObject: iLevelTable[o, i]
                hasRows = Get number of rows
                if hasRows
                    curMeanF1 = Get mean: "F1DrawValue"
                    curMeanF2 = Get mean: "F2DrawValue"
                    # draw mean
                    if showMeans >= 0
                        outlineColr$ = "Black"
                        if i = coreLevel
                            @drawSquare: curMeanF2, curMeanF1,
                            ... curColour$[3], bulletSize
                        else
                            @drawCircle: curMeanF2, curMeanF1,
                            ... curColour$[3], bulletSize
                        endif
                    endif
                    # write text
                    if showMeans > 0
                        curMeanText$ = Get value: 1, "meansText"
                        18
                        Select inner viewport: left, right, top, bottom
                        Colour: "{0.9, 0.9, 0.9}"
                        Text: curMeanF2 + xDiff, "centre",
                        ... curMeanF1 - yDiff, "bottom",
                        ... "##" + curMeanText$
                        # draw black text
                        Colour: "Black"
                        Text: curMeanF2, "centre",
                        ... curMeanF1, "bottom",
                        ... "##" + curMeanText$
                        12
                        Select inner viewport: left, right, top, bottom
                    endif
                endif
            endif
        endfor
    endfor
endproc

procedure drawTitleLayer
    Select inner viewport: left, right, top - titleAdjust, bottom
    Font size: fontL
    nowarn Text top: "yes", "##" + title$
    Font size: fontM
endproc


# Initialisation procedures and script inclusions
procedure defineVars
    @checkDirectoryStructure


    if !fileReadable("../data/vars/f1f1Plot.var")
        @createF1F2Vars
    endif
    @readVars: "../data/vars/", "f1f1Plot.var"

    if f1f2Version$ != curF1f2Version$
        @createF1F2Vars: "../data/vars/f1f1Plot.var"
    endif
    @readVars: "../data/vars/", "f1f1Plot.var"
    @getGenAxisVars

    @overwriteVars

endproc

procedure createF1F2Vars:
     .address$ =  "../data/vars/f1f1Plot.var"
    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "f1f2Version$", tab$, curF1f2Version$
    appendFileLine: .address$, "plotSize", tab$, 5
    appendFileLine: .address$, "tableID$", tab$,
    ... "../example/AER_NI_I.txt"
    appendFileLine: .address$, "oFactor$", tab$, "Context"
    appendFileLine: .address$, "iFactor$", tab$, "Element"
    appendFileLine: .address$, "useInnerFactor", tab$, 1
    appendFileLine: .address$, "f1Col$", tab$, "F1"
    appendFileLine: .address$, "f2Col$", tab$, "F2"
    appendFileLine: .address$, "tertiaryFilters", tab$, 0
    appendFileLine: .address$, "inputUnits", tab$, 1
    appendFileLine: .address$, "iBoolean#", tab$, "{0}"
    appendFileLine: .address$, "oBoolean#", tab$, "{0}"
    appendFileLine: .address$, "arrowRatio", tab$, 0.75
    appendFileLine: .address$, "prevInputUnit", tab$, 1
    appendFileLine: .address$, "title$", tab$,
        ... "Example nIE vowel and dipthongs"
    appendFileLine: .address$, "outputUnits", tab$, 2
    appendFileLine: .address$, "minF1", tab$, 150
    appendFileLine: .address$, "maxF1", tab$, 1400
    appendFileLine: .address$, "minF2", tab$, 500
    appendFileLine: .address$, "maxF2", tab$, 3600
    appendFileLine: .address$, "tokenMarking", tab$, 11
    appendFileLine: .address$, "showMeans", tab$, 2
    appendFileLine: .address$, "showArrows", tab$, 1
    appendFileLine: .address$, "ellipsisSDs", tab$, 3
    appendFileLine: .address$, "coreLevel", tab$, 2
    appendFileLine: .address$, "dataPointsOnTop", tab$, 1
    appendFileLine: .address$, "saveName$", tab$, "F1F2_Plot.png"
    @appendSharedVars: .address$
endproc

include _aeroplotFns.praat
include _genFnBank.praat
