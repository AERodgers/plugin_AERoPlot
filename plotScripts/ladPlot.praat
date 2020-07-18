# Ladefoged-style Formant Plotter
# ==============================
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
#
# Named after style of figure in Ladefoged and Johnson (2011:193)
# ref. Ladefoged, P. and Johnson. K., A course in Pnonetics [6th ed.],
#      Boston MA: Wadsworth Cengage

curLadVersion$ = "1.0.0.2"
@checkPraatVersion

# Main script loop
keepGoing = 1
while keepGoing
    @defineVars

    @doInputUI
    @validateTable: tableID$, headerList$
    @processInputUI

    @doOutputUI
    @setupColours:
    ... "../data/palettes/", "colrPalFile$", "curPalette", table, altColrMatch

    @doLadPlot

    # remove remaining tables
    selectObject: table
    for o to outerLevels
        plusObject: plotTable[o]
    endfor
    Remove

    viewPort$ =  "'left', 'right', 'top', 'bottom' + 'vertAdjust'"
    @saveImage: saveDirectory$, saveName$, quality, viewPort$, fontM, "LAD."

    # return input flags to original state
    dataPointsOnTop += 1
    ellipsisSDs += 1
    tokenMarking += 1
    showAves += 1
    outputUnits = output_units
    @writeVars: "../data/vars/", "ladPlot.var"
endwhile

# UI and input processing procedures
procedure doInputUI
    inputIncomplete = 1
    additionalComment$ = ""
    while inputIncomplete
        beginPause: "Ladefoged-style Formant Plot: input settings"
            sentence: "Table address or object number", tableID$
            optionMenu: "Table format", tableFormat
            option: "tab-delimited file"
            option: "CSV file"

            comment:  "Grouping Factors / Column Headers"
            comment:  additionalComment$
            sentence: "Sequencing factor (x-Axis)", innerFactor$
            sentence: "Comparison factor (y-axis, colour)", outerFactor$
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

        outerFactor$ = comparison_factor$
        innerFactor$ = sequencing_factor$
        for f to 4
            f'f'Col$ = f'f'_Column$
        endfor

        headerList$ = "'f1Col$','f2Col$','f3Col$','f4Col$'," +
        ... "'outerFactor$','innerFactor$'"

        inputIncomplete = (innerFactor$ == outerFactor$)
        additionalComment$ =
        ... "NB: MAIN AND SEQUENCING FACTORS MUST BE DIFFERENT."
        if innerFactor$ = "" or outerFactor$ = ""
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

    tertiaryFilters = use_tertiary_filters
    inputUnits = input_units
    inputUnits$[1] = "Hertz"
    inputUnits$[2] = "Bark scale"

    # change default min and max F1, F2 if input scale has changed.
    if inputUnits = 1 and prevInputUnit = 2
        maxFreq = 3800
    elsif inputUnits = 2 and prevInputUnit = 1
       maxFreq = 18
    endif
    prevInputUnit = inputUnits
endproc

procedure processInputUI
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
    @filterLevels: table, innerFactor$, "inner", "newStateIsOldOne"

    # run tertiary filter UI first to remove unwanted items
    if tertiaryFilters
        @filterTertFactors: table, "factorName$", numFactors,
        ... "../data/vars", "ladTertFactor.var",
        ... headerList$
        # recalculate outer levels based on purged table
        @summariseFactor: table, outerFactor$, "outer"
        @summariseFactor: table, innerFactor$, "inner"
    endif


    # Get list of xAxis Text Options
    xAxisOptions = 0
    selectObject: table
    for i to numFactors
        @summariseFactor:  table, factorName$[i], "cur"
        if curLevels = innerLevels
            xAxisOptions += 1
            xAxisOption$[xAxisOptions] = factorName$[i]
            for j to innerLevels
                xAxisLevel$[xAxisOptions, j] = curLevel$[j]
            endfor
            # always reset xAxisFactor to default in first loop.
            if !prevLoops and factorName$[i] = innerFactor$
                xAxisFactor = xAxisOptions
            endif
        endif
    endfor
endproc

procedure doOutputUI
    varRoot$ = "inner"

    beginPause: "Graphical Output Settings: formants over time"
        comment: "Plot basics"
        sentence: "Title", title$
        @addShared_UI_1
        optionMenu: "Mark X axis using", xAxisFactor
        for i to xAxisOptions
            option: xAxisOption$[i]
        endfor

        natural: "Maximum frequency (in "
        ... + inputUnits$[inputUnits] + ".)", maxFreq
        positive: "Interior plot height (inches)", plotHeight

        comment: "Plot layers"
        optionMenu: "Most prominent layer", dataPointsOnTop
        option: "averages bar / box plot"
        option: "data points"

        optionMenu: "Averages bar", showAves
        option: "Hide averages bar"
        option: "... shows means"
        option: "... shows median values"

        optionMenu: "Data points", tokenMarking
        option: "Hide data points"
        option: "Show all individual data points"
        option: "Show outliers only"

        boolean: "Add time jitter to data points", addJitter
        boolean: "Show IQR", showIQR
        boolean: "Show tail", showTail
        boolean: "Show arrows", drawArrows
        boolean: "show formants in legend", legendHasFormants
        @addShared_UI_2

        myChoice = endPause: "Exit", "Continue", 2, 1
        if myChoice = 1
            removeObject: table
            exit
        endif

    # Process generic outoutUI
    @processShared_UIs
    # Process Lad plot-specific graphic UI
    plotHeight = interior_plot_height
    maxFreq = maximum_frequency
    dataPointsOnTop = most_prominent_layer - 1
    tokenMarking = data_points - 1
    showAves = averages_bar - 1
    addJitter = add_time_jitter_to_data_points
    showIQR = show_IQR
    showTail = show_tail
    drawArrows = show_arrows
    xAxisFactor = mark_X_axis_using
    legendHasFormants = show_formants_in_legend
endproc

# Main drawing procedure
procedure doLadPlot
    @resetDrawSpace: fontM

    @calcLadAxisIncrements
    @calcLadAxisVals
    @calcLadPlotLayers
    @drawLadAxisLayer

    if drawArrows
        @drawArrows
    endif

    if dataPointsOnTop

        if showIQR or showTail
            @drawTailsIQR
        endif

        if showAves
            @drawAves
        endif

        if tokenMarking
            @drawDataPoints
        endif

    else

        if tokenMarking
            @drawDataPoints
        endif

        if showIQR or showTail
            @drawTailsIQR
        endif

        if showAves
            @drawAves
        endif

    endif

    if showLegend
        yList$ = ""
        for i to 4
            if f'i'Col$ != ""
                yList$ = yList$ + f'i'Col$ + "DrawValue,"
            endif
        endfor
        @drawLegendLayer: minX, maxX, minF, maxF,
        ... fontM, "left, right, top, bottom",
        ... table, "x", yList$,
        ... legBlockTolerance, bufferZone, 1, 0, - 1
    endif
    @drawTitleLayer
endproc

# Plot calculation procedures
procedure calcLadAxisIncrements
    widthBeta = innerLevels * 0.5
    plotWidth = (widthBeta) * (innerLevels <= 24) * (innerLevels >= 4) +
    ... 12 * (innerLevels > 24) +
    ... 2 * (innerLevels < 4)

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

procedure calcLadAxisVals
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

    # min and max X placeholders
    minX = 0.5
    maxX = innerLevels + 0.5
endproc

procedure calcLadPlotLayers
    # make dictionary of inner levels
    for i to innerLevels
        innerLevel[innerLevel$[i]] = i
    endfor

    selectObject: table

    # add columns for plot drawing
    Append column: "x"
    Formula: "x", "innerLevel[self$[innerFactor$]]"
    if addJitter
        Formula: "x", "self + randomUniform(-jitter, jitter)"
    endif

    # calculate size of potenial tables filtered by
    # levels of outer and inner factors
    @possRows: table, "outer", "inner"
    for o to outerLevels
        curOLevel$ = outerLevel$[o]
        # create LegendElement for outerLevel[o] colour
        curColVector$ = curPaletteVector$[outerColour[o]]
        curColName$ = curPaletteName$[outerColour[o]]
        @legend: "R", curColVector$, outerLevel$[o], 4

        # make o colourShades
        @modifyColVectr: curColVector$, "oColour$['o',5]", " + shading * 2"
        @modifyColVectr: curColVector$, "oColour$['o',4]", " + shading"
        oColour$[o, 3] = curColVector$
        @modifyColVectr: curColVector$, "oColour$['o',2]", " - shading"
        @modifyColVectr: curColVector$, "oColour$['o',1]", " - shading * 2"

        # create plot table for outer factor
        selectObject: table
        plotTable[o] = Extract rows where: "self$[outerFactor$] = curOLevel$"

        for i to innerLevels
            curILevel$ = innerLevel$[i]
            if possRows.matrix##[o,i]
                # Create inner sub-table of outer table
                # # Note: while "Group mean:" could be used to get mean values
                # # without creating sub-tables, it is not possible to do so
                # # for
                selectObject: table
                tempTable[o,i] = Extract rows where:
                ... "self$[outerFactor$] = curOLevel$ and " +
                ... "self$[innerFactor$] = curILevel$"
                Rename: curOLevel$ + "_" + curILevel$
                tempNumRows = Get number of rows

                # get mean formant values for current sub-table
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

                    medFinPlot[o,i,f] =
                    ... Get quantile: 'curF$' + "DrawValue", 0.5
                    medFinPlot[o,i,f] = round(medFinPlot[o,i,f] * 100) / 100
                    medFAct[o,i,f] =
                    ... Get quantile: 'curF$', 0.5

                    q1FinPlot[o,i,f] =
                    ... Get quantile: 'curF$' + "DrawValue", 0.25
                    q1FinPlot[o,i,f] = round(q1FinPlot[o,i,f] * 100) / 100
                    q1FAct[o,i,f] =
                    ... Get quantile: 'curF$', 0.25

                    q3FinPlot[o,i,f] =
                    ... Get quantile: 'curF$' + "DrawValue", 0.75
                    q3FinPlot[o,i,f] = round(q3FinPlot[o,i,f] * 100) / 100
                    q3FAct[o,i,f] =
                    ... Get quantile: 'curF$', 0.75

                    iqrF[o,i,f] = q3FinPlot[o,i,f] - q1FinPlot[o,i,f]
                    tailStart[o,i,f] = q1FinPlot[o,i,f] - iqrF[o,i,f] * 1.5
                    tailEnd[o,i,f] = q3FinPlot[o,i,f] + iqrF[o,i,f] * 1.5

                    if tempNumRows > 1
                        stDevFAct[o,i,f] = Get standard deviation:
                        ... 'curF$'
                        stDevFAct[o,i,f] = round(stDevFAct[o,i,f] * 100) / 100
                    else
                        stDevFAct[o,i,f] = undefined
                    endif
                endfor

                removeObject: tempTable[o,i]
            else
                prevMeanFinPlot[o,i,f] = undefined
                tempTable[o,i] = undefined
                meanFinPlot[o,i,f] = undefined
            endif
        endfor
    endfor
endproc

# Plot layer procedures

procedure drawLadAxisLayer
    Select inner viewport: left, right, top, bottom + vertAdjust
    Text bottom: "yes", innerFactor$

    Select inner viewport: left, right, top, bottom
    Text left: "yes", "Frequency in " + outputUnits$[outputUnits]

    Axes: minX, maxX, majorFreq_Min, majorFreq_Max
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
            Draw line: minX, 'curLIs$'Freq_DrawVal[line],
            ... maxX, 'curLIs$'Freq_DrawVal[line]
        if minMaj = 2
            Colour: "Black"
            Text: minX, "right",
            ... majorFreq_DrawVal[line], "Half",
            ... fixed$(majorFreq_AxisVal[line], useKHz)
        endif
        endfor
    endfor

    for x to innerLevels
        Colour: lineColour$[2]
        Draw line: x - 0.5, minF,
        ... x - 0.5, maxF
    endfor
    xFactor$ = xAxisOption$[xAxisFactor]
    for level to innerLevels
        Colour: "Black"
        Text:
        ... level, "centre",
        ... majorFreq_Min, "Top",
        ... "##" +  xAxisLevel$[xAxisFactor, level]
    endfor

    # Draw graph frame
    Line width: 1
    Colour: "Black"
    Draw inner box
endproc

procedure drawTailsIQR
    for o to outerLevels
        curColour$ = oColour$[o,3]
        for i to innerLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                x = i
                for f to numFormants

                    yMed = medFinPlot[o,i,f]
                    yStart = q1FinPlot[o,i,f]
                    yEnd = q3FinPlot[o,i,f]

                    curColr$[1] = "Black"
                    c = (f/2 == round(f/2) - 0.5) * 0.15
                    @modifyColVectr: oColour$[o, 3], "curColr$[2]", "+'c'"
                    for bgFg to 2
                        Colour: curColr$[bgFg]
                        Line width: 6 - bgFg * 2

                        if showIQR
                            Draw rectangle:  x - 0.1, x + 0.1, yStart, yEnd
                            Draw line: x - 0.1, yMed, x + 0.1, yMed
                        endif

                        if showTail
                            tEnd = tailEnd[o,i,f]
                            tStart = tailStart[o,i,f]
                            if showIQR
                                Draw line: x, yEnd, x, tEnd
                                Draw line: x, yStart, x, tStart
                                Draw line: x - 0.1, yMed, x + 0.1, yMed
                            else
                                Draw line: x, tStart, x, tEnd
                            endif
                            Draw line: x - 0.1, tEnd, x + 0.1, tEnd
                            Draw line: x - 0.1, tStart, x + 0.1, tStart
                        endif
                    endfor
                endfor
            endif
        endfor
    endfor
endproc

procedure drawArrows
    for o to outerLevels
        for i from 2 to innerLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                curAveX = i
                prevAveX = i - 1
                for f to numFormants
                    if showAves = 1
                        ave$ = "med"
                    else
                        ave$ = "mean"
                    endif
                    curAveF = 'ave$'FinPlot[o,i,f]
                    prevAveF = 'ave$'FinPlot[o, i - 1, f]

                    gap =  1 - lineRatio
                    xStart = prevAveX + gap / 3 * (curAveX - prevAveX)
                    xEnd = curAveX - gap / 3 * (curAveX - prevAveX)
                    yStart = prevAveF + gap / 3 * (curAveF - prevAveF)
                    yEnd = curAveF - gap / 3 * (curAveF - prevAveF)

                    @bgColr: oColour$[o,4], oColour$[o,5], oColour$[o,2],
                    ... colrAdj#, 0.19567
                    Line width: 4
                    Arrow size: 1.05
                    Draw arrow: xStart, yStart, xEnd, yEnd
                    Colour: oColour$[o, 4]
                    Line width: 2
                    Arrow size: 1
                    Draw arrow: xStart, yStart, xEnd, yEnd
                endfor
            endif
        endfor
    endfor
endproc

procedure drawAves
    if legendHasFormants
        for f to numFormants
            @legend: "'f'81", "{1,1,1}", "F'f' mean", pi^0.5 * bulletSize / 4
        endfor
    endif

    if  showAves = 1
        ave$ = "med"
    else
        ave$ = "mean"
    endif

    for o to outerLevels
        curColour$ = oColour$[o,3]
        for i to innerLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                curAveX = i
                for f to numFormants
                    curAveF = 'ave$'FinPlot[o,i,f]
                    c = (f/2 = round(f/2)) * 0.09
                    curColr$ = oColour$[o, 3]
                    @modifyColVectr: oColour$[o, 3], "curColr$", "+'c'"
                        @drawOblong:
                        ... curAveX, curAveF,
                        ... pi^0.5 * bulletSize / 1.1, pi^0.5 * bulletSize / 4,
                        ... curColr$, f, 8, 1
                endfor
            endif
        endfor
    endfor
endproc

procedure drawDataPoints
    Line width: 2
    for o to outerLevels
        selectObject: plotTable[o]
        curOuter$ = outerLevel$[o]
        curColour$ = oColour$[o, 3]
        curTCol$ = "x"
        for f to numFormants
            # draw background outline
            Append column: "XAdj"
            Append column: "F'f'Adj"

            curFCol$ = f'f'Col$ + "DrawValue"
            # Draw scatter plot
            if mean('curColour$' * colrAdj#) / 1000 < 0.19576
                Colour: 'curColour$' - 0.8
            else
                Colour:  'curColour$' - 0.5
            endif
            Line width: 4
            Scatter plot where (mark):
            ... curTCol$, minX, maxX,
            ... curFCol$, minF, maxF,
            ... fontM / 12, "no", "o",
            ... "self$[outerFactor$] = outerLevel$[o]"

            Colour: curColour$
            Line width: 2
            Scatter plot where (mark):
            ... curTCol$, minX, maxX,
            ... curFCol$, minF, maxF,
            ... fontM / 12, "no", "o",
            ... "self$[outerFactor$] = outerLevel$[o]"
        endfor
    endfor
    Line width: 1
endproc

procedure drawTitleLayer
    Select inner viewport: left, right, top, bottom
    Font size: fontL
    Text top: "yes", "##" + title$
    Font size: fontM
endproc

# Initialisation procedures and script inclusions
procedure defineVars
    if !variableExists("prevLoops")
        prevLoops = 0
    else
        prevLoops = 1
    endif
    @checkDirectoryStructure
    if !fileReadable("../data/vars/ladPlot.var")
        @createLadVars: "../data/vars/ladPlot.var"
    endif
    @readVars: "../data/vars/", "ladPlot.var"
    if ladVersion$ != curLadVersion$
        @createLadVars: "../data/vars/ladPlot.var"
    endif
    @readVars: "../data/vars/", "ladPlot.var"
    @getFreqAxisNames
endproc

procedure createLadVars: .address$

    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "ladVersion$", tab$, curLadVersion$
    appendFileLine: .address$, "tableID$", tab$, "../example/nIEdiphthongs.txt"
    appendFileLine: .address$, "xAxisFactor", tab$, 1
    appendFileLine: .address$, "f1Col$", tab$, "F1"
    appendFileLine: .address$, "f2Col$", tab$, "F2"
    appendFileLine: .address$, "f3Col$", tab$, "F3"
    appendFileLine: .address$, "f4Col$", tab$, ""
    appendFileLine: .address$, "outerFactor$", tab$, "sound"
    appendFileLine: .address$, "innerFactor$", tab$, "element"
    appendFileLine: .address$, "tertiaryFilters", tab$, 0
    appendFileLine: .address$, "inputUnits", tab$, 1
    appendFileLine: .address$, "timeRelativeTo", tab$, 1
    appendFileLine: .address$, "outerBoolean#", tab$, "{0}"
    appendFileLine: .address$, "innerBoolean#", tab$, "{0}"
    appendFileLine: .address$, "formantFlag#", tab$, "{1, 1, 1, 0}"
    appendFileLine: .address$, "plotHeight", tab$, 5
    appendFileLine: .address$, "lineRatio", tab$, 0.5
    appendFileLine: .address$, "prevInputUnit", tab$, 1
    appendFileLine: .address$, "title$", tab$, "nIE diphthongs"
    appendFileLine: .address$, "outputUnits", tab$, 2
    appendFileLine: .address$, "dataPointsOnTop", tab$, 1
    appendFileLine: .address$, "maxFreq", tab$, 4000
    appendFileLine: .address$, "tokenMarking", tab$, 1
    appendFileLine: .address$, "showAves", tab$, 2
    appendFileLine: .address$, "addJitter", tab$, 1
    appendFileLine: .address$, "jitter", tab$, 1/20
    appendFileLine: .address$, "showIQR", tab$, 1
    appendFileLine: .address$, "showTail", tab$, 1
    appendFileLine: .address$, "drawArrows", tab$, 1
    appendFileLine: .address$, "legendHasFormants", tab$, 1
    appendFileLine: .address$, "ellipsisSDs", tab$, 3
    appendFileLine: .address$, "saveName$", tab$, "LadFormantPlot.png"

    @appendSharedVars: .address$
endproc

include _aeroplotFns.praat
include _genFnBank.praat
