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

curF1f2Version$ = "1.0.0.0"
@checkPraatVersion

# Main script loop
keepGoing = 1
while keepGoing
    @defineVars

    @doInputUI
    @validateTable:
        ... tableID$,
        ... "'outerFactor$', 'innerFactor$', 'f1Col$', 'f2Col$'"
    @processTable

    @doOutputUI
    @setupColours: "../data/palettes/", "colrPalFile$", "curPalette", table, altColrMatch

    @drawf1f2Plot

    if sortByBrightness
        @unsortByBrightness: curPaletteSize,
                       ... "curPaletteVector$",
                       ... "curPaletteName$"
    endif
    removeObject: table
    viewPort$ =  "'left', 'right', 'top' - 'titleAdjust', 'bottom'"
    @saveImage: saveDirectory$, saveName$, quality, viewPort$, fontM, "F12."

    coreLevel += 1
    ellipsisSDs += 1
    tokenMarking += 1
    showMeans += 2
    dataPointsOnTop += 1

    # forget optional menu flags.
    changeAddColSch = 0

    @writeVars: "../data/vars/", "f1f1Plot.var"

endwhile

# UI and input processing procedures
procedure doInputUI

    beginPause: "F1-F2 plotter: input settings"
        sentence: "Table address or object number", tableID$
        optionMenu: "Table format", tableFormat
            option: "tab-delimited file"
            option: "CSV file"

        comment: "Grouping factors / column Headers"
        #sentence Main_factor (determines colour)
        #sentence Secondary_factor (used for grouping by sub-category)
        sentence: "Main factor (determines colour)", outerFactor$
        boolean: "add secondary factor (sub-category)", useInnerFactor
        sentence: "Secondary factor", innerFactor$
        sentence: "F2 Column", f2Col$
        sentence: "F1 Column", f1Col$
        comment: "Formant frequency units in table"
        optionMenu: "Input units", inputUnits
            option: "Hertz"
            option: "Bark"

        boolean: "Use tertiary filters", tertiaryFilters
    myChoice = endPause: "Exit", "Apply", "OK", 2, 1

    # respond to myChoice
    keepGoing = myChoice = 2
    if myChoice = 1
        exit
    endif

    # PROCESS DATA TABLE FORM
    tableID$ =  table_address_or_object_number$
    tableFormat = table_format
    outerFactor$ = main_factor$
    innerFactor$ = secondary_factor$
    if outerFactor$ = innerFactor$
        innerFactor$ = ""
    endif
    useInnerFactor = add_secondary_factor
        ... and innerFactor$ != ""
    f1Col$ = f1_Column$
    f2Col$ = f2_Column$
    tertiaryFilters = use_tertiary_filters
    inputUnits = input_units
    inputUnits$[1] = "Hertz"
    inputUnits$[2] = "Bark scale"

    # change default min and max F1, F2 if input scale has changed.
    if inputUnits = 1 and prevInputUnit = 2
        minF1 = 150
        maxF1 = 1400
        minF2 = 500
        maxF2 = 3800
    elsif inputUnits = 2 and prevInputUnit = 1
        minF1 = 1.5
        maxF1 = 9.5
        minF2 = 4.5
        maxF2 = 15.5
    endif
endproc

procedure processTable
    newStateIsOldOne = x_tableID$ = tableID$ and
                   ... outerFactor$ = x_outerFactor$

    selectObject: table

    numFactors = Get number of columns
    for i to numFactors
        factorName$[i] = Get column label: i
    endfor

    # UI for outer factor
    # first pass on outerFactor
    @summariseFactor:  table, outerFactor$, "outer"
    @filterLevels: table, outerFactor$, "outer", "newStateIsOldOne"

    # First pass on innerFactor
    if useInnerFactor
        @summariseFactor: table, innerFactor$, "inner"
        @filterLevels: table, outerFactor$, "inner", "newStateIsOldOne"
    endif

    # run tertiary filter UI first to remove unwanted items
    if tertiaryFilters
        @filterTertFactors: table, "factorName$", numFactors,
            ... "../data/vars/",
            ... "fpTertFactor.var",
            ... "'outerFactor$', 'innerFactor$', 'f1Col$', 'f2Col$'"

        # recalculate outer levels based on purged table
        @summariseFactor: table, outerFactor$, "outer"

        # recalculate inner levels based on purged table
        if useInnerFactor
            @summariseFactor: table, innerFactor$, "inner"
        endif

    endif
endproc

procedure doOutputUI

    if useInnerFactor
        varRoot$ = "inner"
    else
        varRoot$ = "outer"
    endif

    beginPause: "Graphical Output Settings"
        comment: "Plot basics"
        sentence: "Title", title$
        positive: "Interior plot size (inches)", plotSize
        if inputUnits = 1
            optionMenu: "Output units", outputUnits
                option: "Hertz"
                option: "Hertz (displayed re bark scale)"
                option: "Hertz (displayed logarithmically)"
        else
            output_Units = 4
        endif
        comment: "F1-F2 formant plot ranges (in "
            ... + inputUnits$[inputUnits] + ".)"
            natural: "F1 minimum", minF1
            natural: "F1 maximum", maxF1
            natural: "F2 minimum", minF2
            natural: "F2 maximum", maxF2

        comment: "Plot layers"

        optionMenu: "Most prominent layer", dataPointsOnTop
            option: "Mean values"
            option: "data points"

        optionMenu: "Show means", showMeans
            option: "Don't show means."
            option: "... without text"
            for i to numFactors
                option: "... with " + factorName$[i] + " text"
            endfor

        optionMenu: "Mark individual data points using", tokenMarking
            option: "x symbol"
            for i to numFactors
                option: factorName$[i]
            endfor
            option: "Nothing"

        optionMenu: "Core " + 'varRoot$'Factor$, coreLevel
            option: "None"
            for i to 'varRoot$'Levels
                option: 'varRoot$'Level$[i]
            endfor

        optionMenu: "Draw ellipses", ellipsisSDs
            option: "No Ellipses"
            option: "One standard deviation"
            option: "Two standard deviations"

        boolean: "Show arrows", showArrows
        @outputUI_generic


        myChoice = endPause: "Exit", "Continue", 2, 1
        if myChoice = 1
            removeObject: table
            exit
        endif

    # Process generic outoutUI
    @processOutputUI_generic
    # PROCESS F1F2 PLOT SPECIFIC PARAMETERS
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


    # Make sensible coreLevel variable!
    coreLevel$ = "core_" +
    ...replace_regex$('varRoot$'Factor$, "[^A-Za-z0-9]", "_", 0)
    coreLevel = 'coreLevel$' - 1
endproc

# Main drawing procedure
procedure drawf1f2Plot

    @resetDrawSpace: fontM
    @calculateAxisIncrements
    @drawF1F2AxisLayer
    @drawPlotInterior

    if showLegend
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
        legendLeftAdjust = 4.02 - horAdjust
    else
        minorRDist = 0.5
        majorRDist = 2
        minorTDist = 0.5
        majorTDist = 2

        horAdjust = 0.25
        vertAdjust = 0
        titleAdjust = vertAdjust + 0.3
        legendLeftAdjust = 4.02 - horAdjust
    endif
endproc

procedure createSubTables
    for outerLevel to outerLevels
        #add to legend arrays
        curColVector$ = curPaletteVector$[outerColour[outerLevel]]
        curColName$ = curPaletteName$[outerColour[outerLevel]]
        @legend: "R", curColVector$, outerLevel$[outerLevel], 4
        prevMeanF1 = 0
        prevMeanF2 = 0
        for innerLevel to innerLevels
            # create sub-table
            if useInnerFactor
                subInnerFactor$ = innerFactor$
                subInnerLevel$[innerLevel] = innerLevel$[innerLevel]
                subOuterFactor$ = outerFactor$
                subOuterLevel$[outerLevel] = outerLevel$[outerLevel]
            else
                subInnerFactor$ = outerFactor$
                subInnerLevel$[innerLevel] = outerLevel$[outerLevel]
                subOuterFactor$ = outerFactor$
                subOuterLevel$[outerLevel] = outerLevel$[outerLevel]
            endif
            selectObject: table
            innerLevelTable[outerLevel, innerLevel] = Extract rows where:
                ... "self$[subInnerFactor$] = subInnerLevel$[innerLevel] and " +
                ... "self$[subOuterFactor$] = subOuterLevel$[outerLevel]"
        endfor
    endfor
endproc

procedure removeTables
    for outerLevel to outerLevels
        for innerLevel to innerLevels
            removeObject: innerLevelTable[outerLevel, innerLevel]
        endfor
    endfor
endproc

# Plot layer Procedures
procedure drawF1F2AxisLayer

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

    @getOutputScales: table, "'f1Col$','f2Col$'",
        ... minF1, maxF1, minorRDist, outputUnits, "minorR_"
    @getOutputScales: table, "'f1Col$','f2Col$'",
        ... minF1, maxF1, majorRDist, outputUnits, "majorR_"
    @getOutputScales: table, "'f1Col$','f2Col$'",
        ... minF2, maxF2, minorTDist, outputUnits, "minorT_"
    @getOutputScales: table, "'f1Col$','f2Col$'",
        ... minF2, maxF2, majorTDist, outputUnits, "majorT_"

    Axes: majorT_Max, majorT_Min, majorR_Max, majorR_Min
    xDist = Horizontal mm to world coordinates: 0.1
    yDist = Vertical mm to world coordinates: 0.1

    lineColour$[1] = lightLine$
    lineColour$[2] = darkLine$
    lineSize[1] = 1
    lineSize[2] = 1

    # Draw minor horizontal lines
    Colour: lineColour$[1]
    Line width: lineSize[1]
    for line to minorR_Lines
        Draw line: majorT_Min, minorR_DrawVal[line],
               ... majorT_Max, minorR_DrawVal[line]
    endfor
    # Draw minor vertical lines
    Colour: lineColour$[1]
    Line width: lineSize[1]
    for line to minorT_Lines
        Draw line: minorT_DrawVal[line], majorR_Min,
               ... minorT_DrawVal[line], majorR_Max
    endfor
    # draw major horizontal lines
    Colour: lineColour$[2]
    Line width: lineSize[2]
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
    Line width: lineSize[2]
    for line to majorT_Lines
        Draw line: majorT_DrawVal[line], majorR_Min,
               ... majorT_DrawVal[line], majorR_Max
        Colour: "Black"
        Text special: majorT_DrawVal[line], "Left",
                  ... majorR_Min, "Half",
                  ... "Helvetica", fontM, "90",
                  ... string$(majorT_AxisVal[line])
    endfor

    # Draw graph frame
    Line width: 1
    Colour: "Black"
    Draw inner box
endproc

procedure drawPlotInterior

    # set up viewport
    Font size: fontM
    Select inner viewport: left, right, top, bottom


    # prepare mean text Column
    if showMeans > 0
        selectObject: table
        Append column: "meansText"
        Formula: "meansText", "self$[factorName$[showMeans]]"
    endif

    # correct arrays if no innerFactor
    if not useInnerFactor or innerFactor$ = outerFactor$
        innerLevels = outerLevels
        innerFactor$ = outerFactor$
        for i to innerLevels
            innerLevel$[i] = outerLevel$[i]
        endfor
    endif

    selectObject: table
    if tokenMarking < numFactors and tokenMarking
        Append column: "token"
        Formula: "token", """##"" + self$[factorName$[tokenMarking]]"
    endif

    #calculate increments for shading and spacing
    xDiff = Horizontal mm to world coordinates: 0.1
    xDiff = abs(xDiff)
    yDiff = Vertical mm to world coordinates: 0.1
    yDiff = abs(yDiff)

    if !useInnerFactor
        innerLevels = 1
    endif
    @createSubTables
    @drawEllipses
    @drawArrows
    if dataPointsOnTop
        @drawMeansText
        @drawScatterplots
    else
        @drawScatterplots
        @drawMeansText
    endif
    @removeTables
endproc

procedure drawEllipses
    for outerLevel to outerLevels
        # set current colours
        curColVector$ = curPaletteVector$[outerColour[outerLevel]]
        curColName$ = curPaletteName$[outerColour[outerLevel]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"
        for innerLevel to innerLevels
            # set criteria for drawing ellipses based on useInnerFactor.
            if useInnerFactor
                criteria$ =
                ... "self$[subInnerFactor$] = subInnerLevel$[innerLevel]"
            else
                criteria$ = "1"
            endif
            selectObject: innerLevelTable[outerLevel, innerLevel]
            hasRows = Get number of rows
            if hasRows
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
                    Draw ellipses where: "F2DrawValue", majorT_Max, majorT_Min,
                                 ... "F1DrawValue", majorR_Max, majorR_Min,
                                 ... subInnerFactor$,  ellipsisSDs, 0, "no",
                                 ... criteria$
                    Line width: 2
                    Colour: curColour$[4]
                    Draw ellipses where: "F2DrawValue", majorT_Max, majorT_Min,
                                 ... "F1DrawValue", majorR_Max, majorR_Min,
                                 ... subInnerFactor$,  ellipsisSDs, 0, "no",
                                 ... criteria$
                endif
            endif
        endfor
    endfor
endproc

procedure drawArrows
    for outerLevel to outerLevels
        # set current colours
        curColVector$ = curPaletteVector$[outerColour[outerLevel]]
        curColName$ = curPaletteName$[outerColour[outerLevel]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"
        prevMeanF1 = 0
        prevMeanF2 = 0
        for innerLevel to innerLevels
            selectObject: innerLevelTable[outerLevel, innerLevel]
            hasRows = Get number of rows
            if hasRows
                curMeanF1 = Get mean: "F1DrawValue"
                curMeanF2 = Get mean: "F2DrawValue"

                #Draw arrows
                if showArrows and prevMeanF1
                    gap =  1 - arrowRatio
                    xStart = prevMeanF2 + gap / 3 * (curMeanF2 - prevMeanF2)
                    yStart = prevMeanF1 + gap / 3 * (curMeanF1 - prevMeanF1)
                    xEnd = curMeanF2 - gap * 2 / 3 * (curMeanF2 - prevMeanF2)
                    yEnd = curMeanF1 - gap * 2 / 3 * (curMeanF1 - prevMeanF1)
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

        endfor
    endfor
endproc

procedure drawScatterplots
    for outerLevel to outerLevels
        # set current colours
        curColVector$ = curPaletteVector$[outerColour[outerLevel]]
        curColName$ = curPaletteName$[outerColour[outerLevel]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"
        for innerLevel to innerLevels
            # set draw criters depending on useInnerFactor
            if useInnerFactor
                criteria$ = "self$[subInnerFactor$] = subInnerLevel$[innerLevel]"
            else
                criteria$ = "1"
            endif

            selectObject: innerLevelTable[outerLevel, innerLevel]
            if hasRows
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

                Append column: "F2Adj"
                Append column: "F1Adj"
                for across from -1 to 1
                    for down from -1 to 1
                        if across^2 + down^2
                            j = 1 /
                            ... (2^0.5 * (across == down) + (across != down))
                            ... * 1.3
                            Formula: "F2Adj",
                                ... "self[""F2DrawValue""] + across * xDiff * j"
                            Formula: "F1Adj",
                                ... "self[""F1DrawValue""] + down * yDiff * j"
                            if !tokenMarking
                                Line width: 5 - i
                                Scatter plot where (mark):
                                    ... "F2Adj", majorT_Max, majorT_Min,
                                    ... "F1Adj", majorR_Max, majorR_Min,
                                    ... fontM / 4, "no", "x", criteria$

                            elsif tokenMarking < numFactors
                                Scatter plot where: "F2Adj",
                                    ... majorT_Max, majorT_Min,
                                    ... "F1Adj", majorR_Max, majorR_Min,
                                    ... "token", fontM, "no", criteria$
                            endif
                        endif
                    endfor
                endfor

                Colour: curColour$[1]
                if !tokenMarking
                    Line width: 5 - i
                    Scatter plot where (mark):
                        ... "F2DrawValue", majorT_Max, majorT_Min,
                        ... "F1DrawValue", majorR_Max, majorR_Min,
                        ... fontM / 4, "no", "x", criteria$
                elsif tokenMarking < numFactors
                    Scatter plot where: "F2DrawValue", majorT_Max, majorT_Min,
                        ... "F1DrawValue", majorR_Max, majorR_Min,
                        ... factorName$[tokenMarking], fontM, "no", criteria$
                endif
            endif
        endfor
    endfor
endproc

procedure drawMeansText
    for outerLevel to outerLevels

        # set current colours
        curColVector$ = curPaletteVector$[outerColour[outerLevel]]
        curColName$ = curPaletteName$[outerColour[outerLevel]]
        @modifyColVectr: curColVector$, "curColour$[5]", " + shading * 2"
        @modifyColVectr: curColVector$, "curColour$[4]", " + shading"
        curColour$[3] = curColVector$
        @modifyColVectr: curColVector$, "curColour$[2]", " - shading"
        @modifyColVectr: curColVector$, "curColour$[1]", " - shading"

        for innerLevel to innerLevels
            selectObject: innerLevelTable[outerLevel, innerLevel]
            hasRows = Get number of rows

            if hasRows
                curMeanF1 = Get mean: "F1DrawValue"
                curMeanF2 = Get mean: "F2DrawValue"

                # draw mean
                if showMeans >= 0
                    outlineColr$ = "Black"
                    if innerLevel = coreLevel
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
                    for across from -1 to 1
                        for down from -1 to 1
                            Colour: "{0.9, 0.9, 0.9}"
                            if across and down
                                Text: curMeanF2 + across * xDiff, "centre",
                                  ... curMeanF1 + down * yDiff, "bottom",
                                  ... "##" + curMeanText$
                            endif
                        endfor
                    endfor
                    # draw black text
                    Colour: "Black"
                    Text: curMeanF2, "centre",
                      ... curMeanF1, "bottom",
                      ... "##" + curMeanText$
                    12
                    Select inner viewport: left, right, top, bottom
                endif

            endif
        endfor
    endfor
endproc


procedure drawTitleLayer
    Select inner viewport: left, right, top - titleAdjust, bottom
    Font size: fontL
    Text top: "yes", "##" + title$
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
        @createF1F2ars: "../data/vars/f1f1Plot.var"
    endif
    @readVars: "../data/vars/", "f1f1Plot.var"
    outputUnits$[1] = "Hertz"
    outputUnits$[2] = "Hertz (bark)"
    outputUnits$[3] = "Hertz (logarithmic)"
    outputUnits$[4] = "Bark"
endproc

procedure createF1F2Vars:
     .address$ =  "../data/vars/f1f1Plot.var"
    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "f1f2Version$", tab$, curF1f2Version$
    appendFileLine: .address$, "plotSize", tab$, 5
    appendFileLine: .address$, "tableID$", tab$,
        ... "../example/nIEdiphthongs.txt"
    appendFileLine: .address$, "outerFactor$", tab$, "sound"
    appendFileLine: .address$, "innerFactor$", tab$, "element"
    appendFileLine: .address$, "useInnerFactor", tab$, 1
    appendFileLine: .address$, "f1Col$", tab$, "F1"
    appendFileLine: .address$, "f2Col$", tab$, "F2"
    appendFileLine: .address$, "tertiaryFilters", tab$, 0
    appendFileLine: .address$, "inputUnits", tab$, 1
    appendFileLine: .address$, "innerBoolean#", tab$, "{0}"
    appendFileLine: .address$, "outerBoolean#", tab$, "{0}"
    appendFileLine: .address$, "arrowRatio", tab$, 0.75
    appendFileLine: .address$, "prevInputUnit", tab$, 1
    appendFileLine: .address$, "title$", tab$,
        ... "F1-F2 plot for nIE diphthongs"
    appendFileLine: .address$, "outputUnits", tab$, 2
    appendFileLine: .address$, "minF1", tab$, 150
    appendFileLine: .address$, "maxF1", tab$, 1400
    appendFileLine: .address$, "minF2", tab$, 500
    appendFileLine: .address$, "maxF2", tab$, 3600
    appendFileLine: .address$, "tokenMarking", tab$, 7
    appendFileLine: .address$, "showMeans", tab$, 1
    appendFileLine: .address$, "showArrows", tab$, 1
    appendFileLine: .address$, "ellipsisSDs", tab$, 3
    appendFileLine: .address$, "coreLevel", tab$, 2
    appendFileLine: .address$, "dataPointsOnTop", tab$, 1
    appendFileLine: .address$, "saveName$", tab$, "F1F2_Plot.png"

    @appendGenericVars: .address$
endproc

include _aeroplotFns.praat
include _genFnBank.praat
