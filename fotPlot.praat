# Formant Over Time Plot
  curFoTVersion$ = "1.1.1.0"

# Written for Praat 6.0.40

# script by Antoin Eoin Rodgers
# Phonetics and speech Laboratory, Trinity College Dublin
# July 5th - , 2020
#
# email:     rodgeran@tcd.ie
# twitter:   @phonetic_antoin
# github:    github.com/AERodgers


@checkPraatVersion

# Main script loop
keepGoing = 1
while keepGoing
    @defineVars

    @doInputUI
    @validateTable: tableID$,
        ... headerList$ + ",'repFactor$'"
    @processTable

    @doOutputUI
    @setupColours: dataDir$, "colrPalFile$", "stdPalette", table, altColrMatch

    @doFOTPlot

    # remove remaining tables
    selectObject: table
    for o to outerLevels
        plusObject: plotTable[o]
    endfor
    Remove

    viewPort$ =  "'left', 'right', 'top', 'bottom' + 'vertAdjust'"
    @saveImage: saveDirectory$, saveName$, quality, viewPort$, fontM, "FOT."

    # return input flags to original state
    dataPointsOnTop += 1
    coreLevel += 1
    ellipsisSDs += 1
    tokenMarking += 1
    # forget optional menu flags.
    changeAddColSch = 0
    makeNewColSeq = 0
    altColrMatch = 0

    @writeVars: dataDir$, "fotPlot.var"
endwhile

procedure defineVars
    # check / fix directory ending
    dataDir$ = "data/"

    # GET / CREATE UI VARIABLES
    # Create fotPlot.var if it doesn't exist.
    if !fileReadable(dataDir$)
        createDirectory: dataDir$
    endif

    if !fileReadable("'dataDir$'fotPlot.var")
        @createFOTVars: "'dataDir$'fotPlot.var"
    endif

    @readVars: dataDir$, "fotPlot.var"

    # Reset UI.Vars if formatPlotter has recently been updated
    if fotVersion$ != curFoTVersion$
        @createFOTVars: "'dataDir$'fotPlot.var"
        @readVars: dataDir$, "fotPlot.var"
    endif
    # CREATE COLOUR SCHEME IF NON-EXISTENT
    if !fileReadable(dataDir$ + colrPalFile$)
        before$ = dataDir$ + colrPalFile$
        @makeStdColSch: dataDir$, colrPalFile$
    endif

    # OTHER VARIABLE AND FLAGS
    # axis array
    outputUnits$[1] = "Hertz"
    outputUnits$[2] = "Hertz (bark)"
    outputUnits$[3] = "Hertz (logarithmic)"
    outputUnits$[4] = "Bark"
endproc

procedure createFOTVars: .address$

    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "fotVersion$", tab$, curFoTVersion$
    appendFileLine: .address$, "tableID$", tab$,
        ... "test/nIEdiphthongs.txt"
    appendFileLine: .address$, "timeCol$", tab$, "time"
    appendFileLine: .address$, "f1Col$", tab$, "F1"
    appendFileLine: .address$, "f2Col$", tab$, "F2"
    appendFileLine: .address$, "f3Col$", tab$, "F3"
    appendFileLine: .address$, "f4Col$", tab$, ""
    appendFileLine: .address$, "repFactor$", tab$, "rep"
    appendFileLine: .address$, "outerFactor$", tab$, "sound"
    appendFileLine: .address$, "innerFactor$", tab$, "element"
    appendFileLine: .address$, "tertiaryFilters", tab$, 0
    appendFileLine: .address$, "inputUnits", tab$, 1
    appendFileLine: .address$, "timeRelativeTo", tab$, 1
    appendFileLine: .address$, "outerBoolean#", tab$, "{0}"
    appendFileLine: .address$, "innerBoolean#", tab$, "{0}"
    appendFileLine: .address$, "formantFlag#", tab$, "{1, 1, 1, 0}"
    appendFileLine: .address$, "plotWidth", tab$, 3
    appendFileLine: .address$, "plotHeight", tab$, 5

    appendFileLine: .address$, "lineRatio", tab$, 0.9

    appendFileLine: .address$, "prevInputUnit", tab$, 1
    appendFileLine: .address$, "title$", tab$,
        ... "Formant-over-time plot for nIE diphthongs"
    appendFileLine: .address$, "outputUnits", tab$, 2
    appendFileLine: .address$, "dataPointsOnTop", tab$, 1
    appendFileLine: .address$, "maxFreq", tab$, 3800
    appendFileLine: .address$, "tokenMarking", tab$, 0
    appendFileLine: .address$, "addJitter", tab$, 1
    appendFileLine: .address$, "showLines", tab$, 1
    appendFileLine: .address$, "ellipsisSDs", tab$, 3
    appendFileLine: .address$, "coreLevel", tab$, 2
    appendFileLine: .address$, "saveName$", tab$, "Formants_over_Time.png"

    @appendGenericVars: .address$
endproc

procedure doInputUI
    inputIncomplete = 1
    additionalComment$ = ""
    while inputIncomplete
        beginPause: "Formants over time plot: data table settings"
            sentence: "Table address or object number", tableID$
            optionMenu: "Table format", tableFormat
                option: "tab-delimited file"
                option: "CSV tile"

            comment:  "Grouping Factors / Column Headers"
            comment:  additionalComment$
            sentence: "Heading of repetition column", repFactor$
            sentence: "Main factor", outerFactor$
            sentence: "Sequencing factor", innerFactor$
            sentence: "Time Column", timeCol$
            sentence: "F1 Column",   f1Col$
            sentence: "F2 Column",   f2Col$
            sentence: "F3 Column",   f3Col$
            sentence: "F4 Column",   f4Col$
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

        repFactor$ = heading_of_repetition_column$
        outerFactor$ = main_factor$
        innerFactor$ = sequencing_factor$
        headerList$ = "'timeCol$','f1Col$','f2Col$','f3Col$','f4Col$'," +
                  ... "'outerFactor$','innerFactor$'"

        inputIncomplete = (main_factor$ == sequencing_factor$)
        additionalComment$ =
                    ... "NB: MAIN AND SEQUENCING FACTORS MUST BE DIFFERENT."
        if main_factor$ = "" or sequencing_factor$ = ""
            additionalComment$ =
                        ... "NB: YOU CANNOT LEAVE FACTORS BLANK."
            inputIncomplete = 1
        endif

    endwhile
    # PROCESS DATA TABLE FORM

    # simplify input variables
    tableID$ =  table_address_or_object_number$
    tableFormat = table_format

    for i to 4
        n$ = string$(i)
        f'n$'_Column$ = replace$(f'n$'_Column$, "?", "", 0)
        f'n$'Col$ = f'n$'_Column$
    endfor
    timeCol$ = time_Column$

    tertiaryFilters = use_tertiary_filters
    inputUnits = input_units
    inputUnits$[1] = "Hertz"
    inputUnits$[2] = "Bark scale"

    # change default min and max F1, F2 if input scale has changed.
    if inputUnits = 1 and prevInputUnit = 2
        maxFreq = 3800
    elsif inputUnits = 2 and prevInputUnit = 1
       maxFreq = 15.5
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

    # check for rogue F columns called "?"
    for i to 4
        n$ = string$(i)
        f'n$'_Column$ = replace$(f'n$'_Column$, "?", "", 0)
        f'n$'Col$ = f'n$'_Column$
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

    # process outerFactor
    @summariseFactor:  table, outerFactor$, "outer"
    @filterLevels: table, outerFactor$, "outer", "newStateIsOldOne"

    # first pass on outer and inner factors
    @summariseFactor:  table, innerFactor$, "inner"

    @makeTimeRelativeMenu

    @filterLevels: table, innerFactor$, "inner", "newStateIsOldOne"

    # run tertiary filter UI first to remove unwanted items
    if tertiaryFilters
        @filterTertFactors: table, "factorName$", numFactors,
            ... dataDir$, "fotTertFactor.var",
            ... headerList$

        # recalculate outer levels based on purged table
        @summariseFactor: table, outerFactor$, "outer"
        @summariseFactor: table, innerFactor$, "inner"

    endif
endproc

procedure makeTimeRelativeMenu
    optText$ = "Make time relative to"
    beginPause: "Choose Reference Element"
        optionMenu: optText$, timeRelativeTo + 1
            option: "no element"
            for j to innerLevels
                option:  innerFactor$ + " " + innerLevel$[j]
            endfor
        comment: "NOTE"
        comment: "Making time relative to " + outerFactor$ + " will not work " +
             ... "correctly if there are multiple speakers in the table."
        comment: "In such cases, make sure you adjust the time columns in " +
             ... "advance of running this script."
    myChoice = endPause: "Exit", "Continue", 2, 1

    if myChoice = 1
        removeObject: table
        exit
    endif

    timeRelativeTo = make_time_relative_to - 1
    if timeRelativeTo
        timeRelativeTo$ = innerLevel$[timeRelativeTo]

        @summariseFactor: table, repFactor$, "rep"
        selectObject: table
        Insert column: 1, "tempIndex"
        Formula: "tempIndex", "row"
        numRow = Get number of rows
        curTimeRef = undefined
        curRow = 0

        for o to outerLevels
            curOLevel$ = outerLevel$[o]
            selectObject: table
            tempTable = Extract rows where:
                ... "self$[outerFactor$] = curOLevel$ and " +
                ... "self$[innerFactor$] = timeRelativeTo$"
            Rename: curOLevel$
            numReps[o] = Get number of rows
            for i to numReps[o]
                repName$[o,i] = Get value: i, repFactor$
                refTime[o,i] = Get value: i, timeCol$
            endfor
            removeObject: tempTable
        endfor

        selectObject: table
        for o to outerLevels
            for i to numReps[o]
                Formula: timeCol$,
                    ... "if self$[outerFactor$] = outerLevel$[o] and " +
                    ... "self$[repFactor$] = repName$[o,i] then " +
                    ... "fixed$(self - refTime[o,i], 3) else self endif"
            endfor
        endfor
    endif
endproc

procedure doOutputUI

    varRoot$ = "inner"

    beginPause: "Graphical Output Settings: formants over time"
        comment: "Plot basics"
        sentence: "Title", title$
        if inputUnits = 1
            optionMenu: "Output units", outputUnits
                option: "Hertz"
                option: "Hertz (displayed re bark scale)"
                option: "Hertz (displayed logarithmically)"
        else
            output_Units = 4
        endif

        natural: "Maximum frequency (in "
            ... + inputUnits$[inputUnits] + ".)", maxFreq
        positive: "Interior plot width (inches)", plotWidth
        positive: "Interior plot height (inches)", plotHeight

        comment: "Plot layers"
        optionMenu: "Most prominent layer", dataPointsOnTop
            option: "Mean values"
            option: "Data points"

        optionMenu: "Mark individual data points using", tokenMarking
            option: "Do not Mark"
            for i to numFactors
                option: factorName$[i]
            endfor
            option: "x symbol"

        optionMenu: "Core " + innerFactor$, coreLevel
            option: "None"
            for i to innerLevels
                option: innerLevel$[i]
            endfor

        optionMenu: "Draw ellipses", ellipsisSDs
            option: "No Ellipses"
            option: "One standard deviation"
            option: "Two standard deviations"

        boolean: "Show connecting lines", showLines
        boolean: "Add time jitter to tokens at reference time",
            ... addJitter
        @outputUI_generic

        myChoice = endPause: "Exit", "Continue", 2, 1
        if myChoice = 1
            removeObject: table
            exit
        endif

    # Process generic outoutUI
    @processOutputUI_generic
    # Process FoT plot-specific graphic UI
    plotWidth = interior_plot_width
    plotHeight = interior_plot_height
    maxFreq = maximum_frequency
    dataPointsOnTop = most_prominent_layer - 1
    ellipsisSDs = draw_ellipses - 1
    tokenMarking = mark_individual_data_points_using - 1
    addJitter = add_time_jitter_to_tokens_at_reference_time
    showLines = show_connecting_lines
    outputUnits = output_units

    # Make sensible coreLevel variable!
    coreLevel$ = "core_" +
    ...replace_regex$('varRoot$'Factor$, "[^A-Za-z0-9]", "_", 0)
    coreLevel = 'coreLevel$' - 1
endproc

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


    if showLegend
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
             ... legBlockTolerance, bufferZone, 0, - 1
    endif
    @drawTitleLayer
endproc

procedure calcFOTAxisIncrements
    minorTimeDist = 0.01
    jitter = 0.003
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
    @getOutputScales: table, "'f1Col$','f2Col$','f3Col$','f4Col$'",
            ... 0, maxFreq, minorFreqDist,
            ... outputUnits, "minorFreq_"
    @getOutputScales: table, "'f1Col$','f2Col$','f3Col$','f4Col$'",
            ... 0, maxFreq, majorFreqDist,
            ... outputUnits, "majorFreq_"

    minF = 0
    maxF = maxFreq
    if outputUnits = 2
        @hz2Bark: "minF", ""
        @hz2Bark: "maxF", ""
    elsif outputUnits = 3
        minF = 0
        maxF = ln(maxF)
    endif

    # Get calculate major and minor time intervals.
    selectObject: table
    minT = Get minimum: timeCol$
    maxT = Get maximum: timeCol$
    # get min and max T to the nearest 10th of a ms +/- space for grid edge
    minT = floor(minT * 10) / 10 - 0.049
    maxT = ceiling(maxT * 50) / 50 + 0.049
    @getOutputScales: table, "'timeCol$'",
            ... minT, maxT, minorTimeDist,
            ... 1, "minorTime_"
    @getOutputScales: table, "'timeCol$'",
            ... minT, maxT, majorTimeDist,
            ... 1, "majorTime_"
endproc

procedure calcFOTPlotLayers
    # create innerLevels[o,i] array of tables

    if tokenMarking and tokenMarking < numFactors
        selectObject: table
        Append column: "token"
        Formula: "token", """##"" + self$[factorName$[tokenMarking]]"
    endif

    @possRows: table, "outer", "inner"

    for o to outerLevels
        curOLevel$ = outerLevel$[o]
        # create LegendElement for outerLevel[o] colour
        curColVector$ = stdPaletteVector$[outerColour[o]]
        curColName$ = stdPaletteName$[outerColour[o]]
        @legend: "R", curColVector$, outerLevel$[o], 4

        # make o colourShades
        @modifyColVectr: curColVector$, "oColour$['o',5]", " + shading * 2"
        @modifyColVectr: curColVector$, "oColour$['o',4]", " + shading"
        oColour$[o, 3] = curColVector$
        @modifyColVectr: curColVector$, "oColour$['o',2]", " - shading"
        @modifyColVectr: curColVector$, "oColour$['o',1]", " - shading * 2"

        selectObject: table
        plotTable[o] = Extract rows where: "self$[outerFactor$] = curOLevel$"

        for i to innerLevels
            curILevel$ = innerLevel$[i]
            if possRows.matrix##[o,i]

                selectObject: table
                tempTable[o,i] = Extract rows where:
                    ... "self$[outerFactor$] = curOLevel$ and " +
                    ... "self$[innerFactor$] = curILevel$"
                tempNumRows = Get number of rows

                Rename: curOLevel$ + "_" + curILevel$
                meanTinPlot[o,i] = Get mean: timeCol$ + "DrawValue"
                meanTAct[o,i] = meanTinPlot[o,i]
                curMin = Get minimum: timeCol$ + "DrawValue"
                curMax = Get maximum: timeCol$ + "DrawValue"

                for f to numFormants
                    curF$ = "f" + string$(f) + "Col$"

                    if i > 1
                        prevMeanFinPlot[o,i,f] = meanFinPlot[o, i - 1, f]
                    else
                        prevMeanFinPlot[o,i,f] = undefined
                    endif

                    meanFinPlot[o,i,f] = Get mean: 'curF$' + "DrawValue"
                    meanFinPlot[o,i,f] = round(meanFinPlot[o,i,f] * 100) / 100
                    meanFAct[o,i,f] = Get mean: 'curF$'
                    meanFAct[o,i,f] = round(meanFAct[o,i,f] * 100) / 100

                    if tempNumRows > 1
                        stDevTAct[o,i] = Get standard deviation:
                            ... timeCol$ + "DrawValue"
                        stDevTAct[o,i] = round(stDevTAct[o,i] * 100) / 100
                        stDevFAct[o,i,f] = Get standard deviation:
                            ... 'curF$'
                        stDevFAct[o,i,f] = round(stDevFAct[o,i,f] * 100) / 100
                    else
                        stDevTAct[o,i] = undefined
                        stDevFAct[o,i,f] = undefined
                    endif
                endfor

                removeObject: tempTable[o,i]

                if addJitter and curMax = curMin
                    selectObject: plotTable[o]
                    Formula: timeCol$  + "DrawValue",
                        ... "if self$[innerFactor$] = curILevel$ and " +
                        ... "self$[outerFactor$] = curOLevel$ then " +
                        ... "self + randomUniform(-jitter, jitter) else " +
                        ... "self endif"
                endif

            else
                prevMeanFinPlot[o,i,f] = undefined
                tempTable[o,i] = undefined
                meanFinPlot[o,i,f] = undefined
            endif
        endfor
    endfor
endproc

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
    lineSize[1] = 1
    lineSize[2] = 1
    lineIs$[1] = "minor"
    lineIs$[2] = "major"

    for minMaj to 2
        Line width: lineSize[minMaj]
        curLIs$ = lineIs$[minMaj]
        for line to 'curLIs$'Freq_Lines

            Colour: lineColour$[minMaj]
            Draw line: 'curLIs$'Time_Min, 'curLIs$'Freq_DrawVal[line],
                   ... 'curLIs$'Time_Max, 'curLIs$'Freq_DrawVal[line]
           if minMaj = 2
               Colour: "Black"
               Text: majorTime_Min, "right",
                 ... majorFreq_DrawVal[line], "Half",
                 ... string$(majorFreq_AxisVal[line])
           endif
        endfor

        for line to 'curLIs$'Time_Lines
            Colour: lineColour$[minMaj]
            Draw line: 'curLIs$'Time_DrawVal[line], 'curLIs$'Freq_Min,
                   ... 'curLIs$'Time_DrawVal[line], 'curLIs$'Freq_Max
            if minMaj = 2
               Colour: "Black"
               Text special: majorTime_DrawVal[line], "Right",
                         ... majorFreq_Min, "Half",
                         ... "Helvetica", fontM, "90",
                         ... string$(round(majorTime_AxisVal[line] * 1000))
           endif
        endfor
    endfor

    # Draw graph frame
    Line width: 1
    Colour: "Black"
    Draw inner box
endproc

procedure drawDataPoints
    for o to outerLevels
        selectObject: plotTable[o]
        curOuter$ = outerLevel$[o]
        curColour$ = oColour$[o, 1]
        curTCol$ = timeCol$ + "DrawValue"
        for f to numFormants
            curFCol$ = f'f'Col$ + "DrawValue"
            # Draw scatter plot
            if mean('curColour$' * colrAdj#) / 1000 < 0.19576
                Colour: 'curColour$' + 0.8
            else
                Colour:  'curColour$' - 0.5
            endif

            # draw background outline
            Append column: "TAdj"
            Append column: "F'f'Adj"
            for across from -1 to 1
                for down from -1 to 1
                    if across^2 + down^2
                        curve = 2^0.5 * (across == down) + (across != down)
                        Formula: "TAdj",
                        ... "self[curTCol$] + across * xDist * 1.3 / curve"
                        Formula: "F'f'Adj",
                        ... "self[curFCol$] + down * yDist * 1.3 / curve"
                        if tokenMarking < numFactors
                            Scatter plot where:
                            ... "TAdj", minT, maxT,
                            ... "F'f'Adj", minF, maxF,
                            ... "token", fontM, "no",
                            ... "self$[outerFactor$] = outerLevel$[o]"
                        else
                            Line width: 5 - i
                            Scatter plot where (mark):
                            ... "TAdj", minT, maxT,
                            ... "F'f'Adj", minF, maxF,
                            ... fontM / 4, "no", "x",
                            ... "self$[outerFactor$] = outerLevel$[o]"
                        endif
                    else
                    endif
                endfor
            endfor

            Colour: curColour$
            if tokenMarking < numFactors
                Scatter plot where:
                ... curTCol$, minT, maxT,
                ... curFCol$, minF, maxF,
                ... factorName$[tokenMarking], fontM, "no",
                ... "self$[outerFactor$] = outerLevel$[o]"
            else
                Line width: 5 - i
                Scatter plot where (mark):
                ... curTCol$, minT, maxT,
                ... curFCol$, minF, maxF,
                ... fontM / 4, "no", "x",
                ... "self$[outerFactor$] = outerLevel$[o]"
            endif
        endfor
    endfor
endproc

procedure drawEllipses
    for o to outerLevels
        selectObject: plotTable[o]
        for i to innerLevels
            curInner$ = innerLevel$[i]
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
                                     ... outerFactor$,
                                     ... ellipsisSDs, 0, "no",
                                     ... "self$[innerFactor$] = curInner$"
                    curFCol$ = f'f'Col$ + "DrawValue"
                    Line width: 2
                    Colour: oColour$[o,4]
                    Draw ellipses where: curTCol$, minT, maxT,
                                     ... curFCol$, minF, maxF,
                                     ... outerFactor$,
                                     ... ellipsisSDs, 0, "no",
                                     ... "self$[innerFactor$] = curInner$"
                endfor
            endif
        endfor
    endfor
endproc

procedure drawMeans
    for o to outerLevels
        curColour$ = oColour$[o,3]
        for i to innerLevels
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

                    if i = 1
                        if mean('curColour$' * colrAdj#) < 0.19567
                            Colour: 'curColour$' + 0.8
                        else
                            Colour:  'curColour$' - 0.67
                        endif
                        for across from -1 to 1
                            for down from -1 to 1
                                if across^2 + down^2
                                    j = 1 /
                                    ... (
                                    ...  2^0.5 * (across == down) +
                                    ... (across != down)
                                    ... )
                                    ... * 1.3

                                    Text:
                                    ... curMeanT - xDist * (30 + across  * j),
                                    ... "Right",
                                    ... curMeanF + yDist * down * j,
                                    ... "Half",
                                    ... "##" + "F'f'"
                                endif
                            endfor
                        endfor
                        Colour: 'curColour$'
                        Text:
                        ... curMeanT - xDist * 30,
                        ... "Right",
                        ... curMeanF,
                        ... "Half",
                        ... "##" + "F'f'"
                    endif
                endfor
            endif
        endfor
    endfor
endproc

procedure drawLines
    for o to outerLevels
        for i from 2 to innerLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                curMeanT = meanTinPlot[o,i]
                prevMeanT = meanTinPlot[o, i - 1]
                for f to numFormants
                    curMeanF = meanFinPlot[o,i,f]
                    prevMeanF = meanFinPlot[o, i - 1, f]

                    gap =  1 - lineRatio
                    xStart = prevMeanT + gap / 3 * (curMeanT - prevMeanT)
                    yStart = prevMeanF + gap / 3 * (curMeanF - prevMeanF)
                    xEnd = curMeanT - gap / 3 * (curMeanT - prevMeanT)
                    yEnd = curMeanF - gap / 3 * (curMeanF - prevMeanF)

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
                endfor
            endif
        endfor
    endfor
endproc

procedure drawTitleLayer
    Select inner viewport: left, right, top, bottom
    Font size: fontL
    Text top: "yes", "##" + title$
    Font size: fontM
endproc

include genFunctions.praat
