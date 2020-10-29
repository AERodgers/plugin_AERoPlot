# Formant Over Time Plotter
# =========================
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
curFoTVersion$ = "1.3.0.1"
plotPrefix$ = "FOT."
# Main script loop
keepGoing = 1
while keepGoing
    @defineVars
    if keepGoing = 1
        @doInputUI
    endif
    @validateTable: tableID$,
        ... headerList$ + ",'repFactor$'"
    @processInputUI
    @doOutputUI
    @hideObjs: "table", "../data/temp/", "hiddenTx"
    @setupColours:
    ... "../data/palettes/", "colrPalFile$", "curPalette", table, altColrMatch
    @retrieveObjs: "hiddenTx"

    @doFOTPlot

    # remove remaining tables
    selectObject: table
    for o to oLevels
        plusObject: plotTable[o]
    endfor
    Remove

    # Purge current averages array of all defined values (prevents previously
    # unfiltered data being used to create and draw unwanted arrows).
    for o to oLevels
        for i to iLevels
            for f to numFormants
                meanFinPlot[o,i,f] = undefined
            endfor
        endfor
    endfor

    # correct local input flags
    coreLevel += 1
    ellipsisSDs += 1

    # correct global menu flags
    changeAddColSch = 0
    tokenMarking += 1
    dataPointsOnTop += 1
    timeRelativeTo -= (tableID$ == "../example/AER_NI_I.txt")

    keepGoing = plotUses
    @writeVars: "../data/vars/", "fotPlot.var"
    viewPort$ =  "'left', 'right', 'top', 'bottom' + 'vertAdjust'"
    @saveImage: saveDir$, saveName$, quality, viewPort$, fontM, "FOT."
endwhile



# UI and input processing procedures
procedure doInputUI
    done = 0
    comment$ = ""
    for n to 4
        f'n'Col$ = replace$(f'n'Col$, "?", "", 0)
    endfor

    while ! done
        repFactor$ = replace$(repFactor$, "?", "", 0)
        beginPause: "Formants over time plot: input settings"
            comment:  comment$

            @addShared_UI_0

            comment: "GROUPING FACTORS (COLUMN HEADERS)"
            sentence: "Repetition column", repFactor$
            sentence: "Main factor (levels compared by colour)", oFactor$
            sentence: "Sequencing factor (shown along time axis)", iFactor$
            boolean: "Use tertiary filters (remove unwanted data)",
            ... tertiaryFilters

            comment: "FORMANT / TIME COLUMNS"
            sentence: "Time Column", timeCol$
            sentence: "Formant A", f1Col$
            sentence: "Formant B", f2Col$
            sentence: "Formant C", f3Col$
            sentence: "Formant D", f4Col$
            optionMenu: "Input units", inputUnits
            option: "Hertz"
            option: "Bark"


            @addShared_UI_1

        myChoice = endPause: "Exit", "Apply", "OK", 2, 1
        # respond to myChoice
        if myChoice = 1
            exit
        endif

        # error handling
        done =
        ... !(
        ... (main_factor$ == sequencing_factor$) or
        ...     (
        ...     object_number_or_file_path$ = "" or
        ...     time_Column$ = "" or
        ...     main_factor$ = "" or
        ...     sequencing_factor$ = ""
        ...     )
        ... )
        if (formant_D$ != "" and
            ... (formant_C$ = "" or formant_B$ = "" or formant_A$ = ""))
            ... or
            ... (formant_C$ != "" and (formant_B$ = "" or formant_A$ = ""))
            ... or (formant_B$ != "" and (formant_A$ = ""))
            ... or (formant_A$) = ""
            done = 0
        endif


        if oFactor$ == iFactor$
            comment$ = "NB: MAIN and SEQUENCING factors MUST BE DIFFERENT."
        else
            comment$ = "Please ensure you FILL IN all the NECESSARY BOXES."
        endif
    endwhile


    # simplify input variables
    @processShared_UI_0
    tableID$ =  object_number_or_file_path$
    tableFormat = table_format
    repFactor$ = repetition_column$
    oFactor$ = main_factor$
    iFactor$ = sequencing_factor$
    timeCol$ = time_Column$
    tertiaryFilters = use_tertiary_filters
    inputUnits = input_units
    inputUnits$[1] = "Hertz"
    inputUnits$[2] = "Bark"
    f1Col$ = formant_A$
    f2Col$ = formant_B$
    f3Col$ = formant_C$
    f4Col$ = formant_D$
    headerList$ = "'timeCol$','f1Col$','f2Col$','f3Col$','f4Col$'," +
              ... "'oFactor$','iFactor$'"

    # change default min and max F1, F2 if input scale has changed.
    if inputUnits = 1 and prevInputUnit = 2
        maxFreq = 3800
    elsif inputUnits = 2 and prevInputUnit = 1
       maxFreq = 16
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

    # check for rogue F columns called "?"
    abcd$ = "ABCD"
    for i to 4
        n$ = string$(i)
        curABCD$ = mid$(abcd$, i, 1)
        formant_'curABCD$'$ = replace$(formant_'curABCD$'$, "?", "", 0)
        f'n$'Col$ = formant_'curABCD$'$
    endfor

    # calculate total number of formants to plot and array of formants2plot
    # (in case user only wants to plot F2 and F3 for example)
    numFormants = 0
    for i to 4
        n$ = string$(i)
        if f'n$'Col$ != ""
            numFormants += 1
            formant2Plot[numFormants] = i
        endif
    endfor

    # process oFactor
    @summariseFactor:  table, oFactor$, "o"
    @checkMax50: oLevels, table, oFactor$, 1
    @filterLevels: table, oFactor$, "o", "newStateIsOldOne"
    table = filterLevels.table
    # first pass on outer and inner factors
    @summariseFactor:  table, iFactor$, "i"
    @checkMax50: iLevels, table, iFactor$, 1


    @makeTimeRelativeMenu


    @filterLevels: table, iFactor$, "i", "newStateIsOldOne"
    table = filterLevels.table

    # run tertiary filter UI first to remove unwanted items
    if tertiaryFilters
        @filterTertFactors: table, "factorName$", numFactors,
        ... "../data/vars/", "fotTertFactor.var",
        ... headerList$
        table = filterTertFactors.table
        # recalculate outer levels based on purged table
        @summariseFactor: table, oFactor$, "o"
        @summariseFactor: table, iFactor$, "i"
    endif
endproc

procedure makeTimeRelativeMenu
    if keepGoing = 1
        timeRelativeTo = timeRelativeTo +
        ... (tableID$ == "../example/AER_NI_I.txt")
        @hideObjs: "table", "../data/temp/", "hiddenTx"
        optText$ = "Make time relative to"
        beginPause: "Choose Reference Element"
            optionMenu: optText$, timeRelativeTo + 1
            option: "no element"
            for j to iLevels
                option:  iFactor$ + " " + iLevel$[j]
            endfor

            comment: "NOTE"
            comment: "Making time relative to " + oFactor$ + " " +
            ... "will not work correctly if there are multiple " +
            ... "speakers in the table."
            comment:
            ... "In such cases, make sure you adjust the time columns " +
            ... "in advance of running this script."
        myChoice = endPause: "Exit", "Continue", 2, 1

        if myChoice = 1
            exit
        endif
        @retrieveObjs: "hiddenTx"


        timeRelativeTo = make_time_relative_to - 1
        if timeRelativeTo
            timeRelativeTo$ = iLevel$[timeRelativeTo]

            if repFactor$ != ""
                @summariseFactor: table, repFactor$, "rep"
            endif
            for o to oLevels
                curOLevel$ = oLevel$[o]
                selectObject: table

                nowarn Extract rows where:
                ... "self$[oFactor$] = curOLevel$ and " +
                ... "self$[iFactor$] = timeRelativeTo$"
                Rename: curOLevel$
                tempTable = selected()
                numReps[o] = Get number of rows
                for i to numReps[o]
                    if repFactor$ = ""
                        refTime[o,i] = Get value: i, timeCol$
                    else
                        repName$[o,i] = Get value: i, repFactor$
                        refTime[o,i] = Get value: i, timeCol$
                    endif
                endfor
                removeObject: tempTable
            endfor

            selectObject: table
            for o to oLevels
                for i to numReps[o]
                    if repFactor$ = ""
                        nowarn Formula: timeCol$,
                        ... "if self$[oFactor$] = oLevel$[o] then " +
                        ... "fixed$(self - refTime[o,i], 3) else " +
                        ... "self endif"
                    else
                        nowarn Formula: timeCol$,
                        ... "if self$[oFactor$] = oLevel$[o] and " +
                        ... "self$[repFactor$] = repName$[o,i] then " +
                        ... "fixed$(self - refTime[o,i], 3) else " +
                        ... "self endif"
                    endif
                endfor
            endfor
            Save as binary file: "../data/temp/table.bin"
        endif
    elsif plotUses = 2
        oldTable = Read from file: "../data/temp/table.bin"
        removeObject: table
        table = oldTable
    endif
endproc

procedure doOutputUI
    varRoot$ = "i"
    @hideObjs: "table", "../data/temp/", "hiddenTx"
    beginPause: "Graphical Output Settings: formants over time"
        comment: "PLOT BASICS"
        sentence: "Title", title$

        @addShared_UI_2

        natural: "Maximum frequency (in "
            ... + inputUnits$[inputUnits] + ".)", maxFreq
        positive: "Interior plot width (inches)", plotWidth
        positive: "Interior plot height (inches)", plotHeight

        comment: "PLOT LAYERS"
        optionMenu: "Mark individual data points using", tokenMarking
            option: "Do not Mark"
            for i to numFactors
                option: factorName$[i]
            endfor
            option: "X symbol"

        optionMenu: "Core " + iFactor$, coreLevel
            option: "None"
            for i to iLevels
                option: iLevel$[i]
            endfor

        optionMenu: "Most prominent layer", dataPointsOnTop
            option: "Mean values"
            option: "data points"

        optionMenu: "Draw ellipses", ellipsisSDs
            option: "No Ellipses"
            option: "One standard deviation"
            option: "Two standard deviations"

        boolean: "Show connecting lines", showLines
        boolean: "Add jitter to data points at reference time",
            ... addJitter

        @addShared_UI_3
    myChoice = endPause: "Exit", "Continue", 2, 1
    if myChoice = 1
        exit
    endif
    @retrieveObjs: "hiddenTx"
    # Process generic outoutUI
    @processShared_UIs
    # Process FoT plot-specific graphic UI
    plotWidth = interior_plot_width
    plotHeight = interior_plot_height
    maxFreq = maximum_frequency
    dataPointsOnTop = most_prominent_layer - 1
    ellipsisSDs = draw_ellipses - 1
    tokenMarking = mark_individual_data_points_using - 1
    addJitter = add_jitter_to_data_points_at_reference_time
    showLines = show_connecting_lines

    # Make sensible coreLevel variable!
    coreLevel$ = "core_" +
    ...replace_regex$('varRoot$'Factor$, "[^A-Za-z0-9]", "_", 0)
    coreLevel = 'coreLevel$' - 1
endproc


# Main drawing procedure
procedure doFOTPlot
    @resetDrawSpace: fontM

    @calcFOTAxisIncrements
    @calcFOTAxisVals
    @calcFOTPlotLayers
    @drawFOTAxisLayer

    if showLines
        @drawLines
    endif
    if ellipsisSDs
        @drawEllipses
    endif

    if dataPointsOnTop
        @drawMeans
        if tokenMarking
            @drawDataPoints
        endif
    else
        if tokenMarking
            @drawDataPoints
        endif
        @drawMeans
    endif

    if showLegend and variableExists("legend.items")
        yList$ = ""
        for i to 4
            if f'i'Col$ != ""
                yList$ = yList$ + f'i'Col$ + "DrawValue,"
            endif
        endfor
        @drawLegendLayer: minT, maxT,
             ... minF, maxF,
             ... fontM, "left, right, top, bottom",
             ... table, "'timeCol$'DrawValue", yList$,
             ... legBlockTolerance, bufferZone, 1, 0, - 1
    endif
    @drawTitleLayer
endproc


# Plot calculation procedures
procedure calcFOTAxisIncrements
    minorTimeDist = 0.01
    jitter = 0.0015
    majorTimeDist = 0.05

    vertAdjust = 0.15
    legendLeftAdjust = 4.02

    if inputUnits = 1
        minorFreqDist = 100
        majorFreqDist = 500
    else
        minorFreqDist = 1
        majorFreqDist = 5
    endif

    # set frame variables
    left = 0.7
    top = 0.54
    right = left + plotWidth
    bottom = top + plotHeight
endproc

procedure calcFOTAxisVals
    # Get calculate major and minor frequency intervals.
    @getOutputScales:
    ... table, "'f1Col$','f2Col$','f3Col$','f4Col$'",
    ... 0, maxFreq, minorFreqDist,
    ... outScaleUnit, useKHz, "minorFreq_"
    @getOutputScales:
    ... table, "'f1Col$','f2Col$','f3Col$','f4Col$'",
    ... 0, maxFreq, majorFreqDist,
    ... outScaleUnit, useKHz, "majorFreq_"

    minF = minorFreq_Min
    maxF = majorFreq_Max

    # Get calculate major and minor time intervals.
    selectObject: table
    minT = Get minimum: timeCol$
    maxT = Get maximum: timeCol$
    # get min and max T to the nearest 10th of a ms +/- space for grid edge
    minT = floor(minT * 10) / 10 - 0.049
    maxT = ceiling(maxT * 50) / 50 + 0.049
    @getOutputScales:
    ... table, "'timeCol$'",
    ... minT, maxT, minorTimeDist,
    ... 1, 0,  "minorTime_"
    @getOutputScales:
    ... table, "'timeCol$'",
    ... minT, maxT, majorTimeDist,
    ... 1, 0, "majorTime_"
endproc

procedure calcFOTPlotLayers
    # create iLevels[o,i] array of tables

    if tokenMarking and tokenMarking < numFactors
        selectObject: table
        Append column: "token"
        Formula: "token", """##"" + self$[factorName$[tokenMarking]]"
    endif

    @possRows: table, "o", "i", 1

    for o to oLevels
        curOLevel$ = oLevel$[o]
        # create LegendElement for oLevel[o] colour
        curColVector$ = curPaletteVector$[oColour[o]]
        curColName$ = curPaletteName$[oColour[o]]
        @legend: "R", curColVector$, oLevel$[o], 4

        # make o colourShades
        @modifyColVectr: curColVector$, "oColour$['o',5]", " + shading * 2"
        @modifyColVectr: curColVector$, "oColour$['o',4]", " + shading"
        oColour$[o, 3] = curColVector$
        @modifyColVectr: curColVector$, "oColour$['o',2]", " - shading"
        @modifyColVectr: curColVector$, "oColour$['o',1]", " - shading * 2"

        selectObject: table
        plotTable[o] = Extract rows where: "self$[oFactor$] = curOLevel$"

        for i to iLevels
            curILevel$ = iLevel$[i]
            if possRows.matrix##[o,i]

                selectObject: table
                tempTable[o,i] = Extract rows where:
                    ... "self$[oFactor$] = curOLevel$ and " +
                    ... "self$[iFactor$] = curILevel$"
                tempNumRows = Get number of rows

                Rename: curOLevel$ + "_" + curILevel$
                meanTinPlot[o,i] = Get mean: timeCol$ + "DrawValue"
                meanTAct[o,i] = meanTinPlot[o,i]
                curMin = Get minimum: timeCol$ + "DrawValue"
                curMax = Get maximum: timeCol$ + "DrawValue"

                for f to numFormants
                    curF$ = "f" + string$(f) + "Col$"
                    im1 = i - 1
                    if !variableExists("meanFinPlot['o','im1','f']")
                        meanFinPlot[o, i - 1, f] = undefined
                    elsif i > 1
                        prevMeanFinPlot[o,i,f] = meanFinPlot[o, i - 1, f]
                    else
                        prevMeanFinPlot[o,i,f] = undefined
                    endif

                    meanFinPlot[o,i,f] = Get mean: 'curF$' + "DrawValue"
                    meanFinPlot[o,i,f] =
                    ... round(meanFinPlot[o,i,f] * 100) / 100
                    meanFAct[o,i,f] = Get mean: 'curF$'
                    meanFAct[o,i,f] = round(meanFAct[o,i,f] * 100) / 100

                    if tempNumRows > 1
                        stDevTAct[o,i] = Get standard deviation:
                            ... timeCol$ + "DrawValue"
                        stDevTAct[o,i] = round(stDevTAct[o,i] * 100) / 100
                        stDevFAct[o,i,f] = Get standard deviation:
                            ... 'curF$'
                        stDevFAct[o,i,f] =
                        ... round(stDevFAct[o,i,f] * 100) / 100
                    else
                        stDevTAct[o,i] = undefined
                        stDevFAct[o,i,f] = undefined
                    endif
                endfor

                removeObject: tempTable[o,i]

                if addJitter and curMax = curMin
                    selectObject: plotTable[o]
                    Formula: timeCol$  + "DrawValue",
                        ... "if self$[iFactor$] = curILevel$ and " +
                        ... "self$[oFactor$] = curOLevel$ then " +
                        ... "self + randomUniform(-jitter, jitter) else " +
                        ... "self endif"
                endif

            else
                tempTable[o,i] = undefined
                for f to numFormants
                    prevMeanFinPlot[o,i,f] = undefined
                    meanFinPlot[o,i,f] = undefined
                endfor
            endif
        endfor
    endfor
endproc


# Plot layer procedures
procedure drawFOTAxisLayer
    Select inner viewport: left, right, top, bottom + vertAdjust
    Text bottom: "yes", "Time in ms"

    Select inner viewport: left, right, top, bottom
    Text left: "yes", "Frequency in " + outputUnits$[outputUnits]
    Select inner viewport: left, right, top, bottom

    Axes: majorTime_Min, majorTime_Max, majorFreq_Min, majorFreq_Max
    xDist = Horizontal mm to world coordinates: 0.1
    yDist = Vertical mm to world coordinates: 0.1

    lineColour$[1] = lightLine$
    lineColour$[2] = darkLine$
    lineIs$[1] = "minor"
    lineIs$[2] = "major"

    for minMaj to 2
        Line width: axisLine[minMaj]
        curLIs$ = lineIs$[minMaj]
        for line to 'curLIs$'Freq_Lines
            if 'curLIs$'Freq_DrawVal[line] >= majorFreq_Min and
            ... 'curLIs$'Freq_DrawVal[line] <= majorFreq_Max
                Colour: lineColour$[minMaj]
                Draw line: 'curLIs$'Time_Min, 'curLIs$'Freq_DrawVal[line],
                ... 'curLIs$'Time_Max, 'curLIs$'Freq_DrawVal[line]
                if minMaj = 2
                Colour: "Black"
                    Text: majorTime_Min, "right",
                    ... majorFreq_DrawVal[line], "Half",
                    ... fixed$(majorFreq_AxisVal[line], useKHz)
                endif
            endif
        endfor

        for line to 'curLIs$'Time_Lines
            if 'curLIs$'Time_DrawVal[line] >= majorTime_Min and
            ... 'curLIs$'Time_DrawVal[line] <= majorTime_Max
                Colour: lineColour$[minMaj]
                Draw line: 'curLIs$'Time_DrawVal[line], 'curLIs$'Freq_Min,
                ... 'curLIs$'Time_DrawVal[line], 'curLIs$'Freq_Max
                if minMaj = 2
                   Colour: "Black"
                   Text special: majorTime_DrawVal[line], "Right",
                    ... majorFreq_Min, "Half",
                    ... font$, fontM, "90",
                    ... string$(round(majorTime_AxisVal[line] * 1000))
                endif
            endif
        endfor
    endfor

    # Draw graph frame
    Line width: 1
    Colour: "Black"
    Draw inner box
endproc

procedure drawDataPoints
    for o to oLevels
        selectObject: plotTable[o]
        curOuter$ = oLevel$[o]
        curColour$ = oColour$[o, 1]
        curTCol$ = timeCol$ + "DrawValue"
        for f to numFormants
            curFCol$ = f'f'Col$ + "DrawValue"
            # Draw scatter plot
            if mean('curColour$' * colrAdj#) / 1000 < 0.19576
                Colour: 'curColour$' + 0.8
            else
                Colour: 'curColour$' - 0.5
            endif

            # draw background outline
            Append column: "TAdj"
            Append column: "F'f'Adj"
            across = 1
            down = -1
            Formula: "TAdj",
            ... "self[curTCol$] + across * xDist * 1.3"
            Formula: "F'f'Adj",
            ... "self[curFCol$] + down * yDist * 1.3"
            if tokenMarking < numFactors
                nowarn Scatter plot where:
                ... "TAdj", minT, maxT,
                ... "F'f'Adj", minF, maxF,
                ... "token", fontM, "no",
                ... "self$[oFactor$] = oLevel$[o]"
            else
                Line width: 4
                nowarn Scatter plot where (mark):
                ... "TAdj", minT, maxT,
                ... "F'f'Adj", minF, maxF,
                ... fontM / 6, "no", "x",
                ... "self$[oFactor$] = oLevel$[o]"
            endif

            Colour: curColour$
            if tokenMarking < numFactors
                nowarn Scatter plot where:
                ... curTCol$, minT, maxT,
                ... curFCol$, minF, maxF,
                ... factorName$[tokenMarking], fontM, "no",
                ... "self$[oFactor$] = oLevel$[o]"
            else
                Line width: 2
                nowarn Scatter plot where (mark):
                ... curTCol$, minT, maxT,
                ... curFCol$, minF, maxF,
                ... fontM / 6, "no", "x",
                ... "self$[oFactor$] = oLevel$[o]"
            endif
        endfor
    endfor
endproc

procedure drawEllipses
    for o to oLevels
        selectObject: plotTable[o]
        for i to iLevels
            curInner$ = iLevel$[i]
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i] and stDevFAct[o, i, 1] != undefined
                curTCol$ = timeCol$ + "DrawValue"
                for f to numFormants
                    curFCol$ = f'f'Col$ + "DrawValue"
                    Line width: 4
                    curClr$ = oColour$[o,4]
                    curClr# = 'curClr$' * colrAdj#
                    if mean(curClr#) < 0.19567
                        Colour: oColour$[o,5]
                    else
                        Colour:  oColour$[o,2]
                    endif
                    Draw ellipses where: curTCol$, minT, maxT,
                    ... curFCol$, minF, maxF,
                    ... oFactor$,
                    ... ellipsisSDs, 0, "no",
                    ... "self$[iFactor$] = curInner$"
                    curFCol$ = f'f'Col$ + "DrawValue"
                    Line width: 2
                    Colour: oColour$[o,4]
                    Draw ellipses where: curTCol$, minT, maxT,
                    ... curFCol$, minF, maxF,
                    ... oFactor$,
                    ... ellipsisSDs, 0, "no",
                    ... "self$[iFactor$] = curInner$"
                endfor
            endif
        endfor
    endfor
endproc

procedure drawMeans
    for o to oLevels
        curColour$ = oColour$[o,3]
        for i to iLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                curMeanT = meanTinPlot[o,i]
                for f to numFormants
                    curMeanF = meanFinPlot[o,i,f]

                    if i = coreLevel
                        @drawSquare:
                        ... curMeanT, curMeanF, oColour$[o,3], bulletSize
                    else
                        @drawCircle:
                        ... curMeanT, curMeanF, oColour$[o,3], bulletSize
                    endif

                    if i = -1
                        if mean('curColour$' * colrAdj#) < 0.19567
                            Colour: 'curColour$' + 0.8
                        else
                            Colour:  'curColour$' - 0.67
                        endif
                        across = 1
                        down = -1
                        Text:
                        ... curMeanT - xDist * (30 - across), "Right",
                        ... curMeanF + yDist * down, "Half",
                        ... "##" + "F'f'"
                        Colour: 'curColour$'
                        Text:
                        ... curMeanT - xDist * 30, "Right",
                        ... curMeanF, "Half",
                        ... "##" + "F'f'"
                    endif
                endfor
            endif
        endfor
    endfor
endproc

procedure drawLines
    for o to oLevels
        for i from 2 to iLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                curMeanT = meanTinPlot[o,i]
                timeNameIOF$ = "meanTinPlot[" +
                ... string$(o) + "," + string$(i - 1) +
                ... "]"
                if variableExists(timeNameIOF$)
                    prevMeanT = meanTinPlot[o, i - 1]
                    for f to numFormants
                        curMeanF = meanFinPlot[o,i,f]
                        prevMeanF = meanFinPlot[o, i - 1, f]
                        gap =  1 - lineRatio
                        xStart = prevMeanT + gap / 3 * (curMeanT - prevMeanT)
                        yStart = prevMeanF + gap / 3 * (curMeanF - prevMeanF)
                        xEnd = curMeanT - gap / 3 * (curMeanT - prevMeanT)
                        yEnd = curMeanF - gap / 3 * (curMeanF - prevMeanF)
                        if prevMeanF != undefined
                            curClr$ = oColour$[o,4]
                            curClr# = 'curClr$' * colrAdj#
                            if mean(curClr#) < 0.19567
                                Colour: oColour$[o,5]
                            else
                                Colour:  oColour$[o,2]
                            endif
                            Line width: 4
                            Draw line: xStart, yStart, xEnd, yEnd
                            Colour: oColour$[o, 4]
                            Line width: 2
                            Draw line: xStart, yStart, xEnd, yEnd
                        endif
                    endfor
                endif
            endif
        endfor
    endfor
endproc

procedure drawTitleLayer
    Select inner viewport: left, right, top, bottom
    Font size: fontL
    nowarn Text top: "yes", "##" + title$
    Font size: fontM
endproc


# Initialisation procedures and script inclusions
procedure defineVars
    # check / fix directory ending
    @checkDirectoryStructure
    if !fileReadable("../data/vars/fotPlot.var")
        @createFoTVars: "../data/vars/fotPlot.var"
    endif
    @readVars: "../data/vars/", "fotPlot.var"
    if fotVersion$ != curFoTVersion$
        @createFoTVars: "../data/vars/fotPlot.var"
    endif
    @readVars: "../data/vars/", "fotPlot.var"
    @getGenAxisVars
    @overrideObjIDs
endproc

procedure createFoTVars: .address$
    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "fotVersion$", tab$, curFoTVersion$
    appendFileLine: .address$, "tableID$", tab$,
        ... "../example/AER_NI_I.txt"
    appendFileLine: .address$, "timeCol$", tab$, "Element_t"
    appendFileLine: .address$, "f1Col$", tab$, "F1"
    appendFileLine: .address$, "f2Col$", tab$, "F2"
    appendFileLine: .address$, "f3Col$", tab$, "F3"
    appendFileLine: .address$, "f4Col$", tab$, ""
    appendFileLine: .address$, "repFactor$", tab$, "Rep"
    appendFileLine: .address$, "oFactor$", tab$, "Context"
    appendFileLine: .address$, "iFactor$", tab$, "Element"
    appendFileLine: .address$, "tertiaryFilters", tab$, 0
    appendFileLine: .address$, "inputUnits", tab$, 1
    appendFileLine: .address$, "timeRelativeTo", tab$, 1
    appendFileLine: .address$, "oBoolean#", tab$, "{0}"
    appendFileLine: .address$, "iBoolean#", tab$, "{0}"
    appendFileLine: .address$, "formantFlag#", tab$, "{1, 1, 1, 0}"
    appendFileLine: .address$, "plotWidth", tab$, 3
    appendFileLine: .address$, "plotHeight", tab$, 5
    appendFileLine: .address$, "lineRatio", tab$, 0.9
    appendFileLine: .address$, "prevInputUnit", tab$, 1
    appendFileLine: .address$, "title$", tab$,
        ... "Example nIE vowel and dipthongs"
    appendFileLine: .address$, "outputUnits", tab$, 2
    appendFileLine: .address$, "dataPointsOnTop", tab$, 1
    appendFileLine: .address$, "maxFreq", tab$, 3800
    appendFileLine: .address$, "tokenMarking", tab$, 1
    appendFileLine: .address$, "addJitter", tab$, 1
    appendFileLine: .address$, "showLines", tab$, 1
    appendFileLine: .address$, "ellipsisSDs", tab$, 3
    appendFileLine: .address$, "coreLevel", tab$, 2
    appendFileLine: .address$, "saveName$", tab$, "Formants_over_Time.png"
    @appendSharedVars: .address$
endproc

include _aeroplotFns.praat
include _genFnBank.praat
