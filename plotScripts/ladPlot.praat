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

@checkPraatVersion
@purgeTempFiles
curLadVersion$ = "1.3.0.0"
plotPrefix$ = "LAD."
# Main script loop
keepGoing = 1
while keepGoing
    @defineVars
    if keepGoing = 1
        @doInputUI
    endif
    @validateTable: tableID$, headerList$
    @processInputUI

    @doOutputUI
    @hideObjs: "table", "../data/temp/", "hiddenTx"
    @setupColours:
    ... "../data/palettes/", "colrPalFile$", "curPalette", table, altColrMatch
    @retrieveObjs: "hiddenTx"

    if showAves = 1
        ave$ = "med"
    else
        ave$ = "mean"
    endif
    @doLadPlot

    # remove remaining tables
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

    # VARIABLE CORRECTION
    # Purge current averages array of all defined values (prevents previously
    # unfiltered data being used to create and draw unwanted arrows).
    for o to oLevels
        for i to iLevels
            for f to numFormants
                'ave$'FinPlot[o,i,f] = undefined
            endfor
        endfor
    endfor
    # correct local menu flags
    ellipsisSDs += 1
    showAves += 1
    # correct global menu flags
    changeAddColSch = 0
    tokenMarking += 1
    dataPointsOnTop += 1
    keepGoing = plotUses

    @writeVars: "../data/vars/", "ladPlot.var"
    viewPort$ =  "'left', 'right', 'top', 'bottom' + 'vertAdjust'"
    @saveImage: saveDir$, saveName$, quality, viewPort$, fontM, plotPrefix$
endwhile


# UI and input processing procedures
procedure doInputUI
    for n to 4
        f'n'Col$ = replace$(f'n'Col$, "?", "", 0)
    endfor
    done = 0
    comment$ = ""
    while ! done
        beginPause: "Ladefoged-style Formant Plot: input settings"
            comment:  comment$

            @addShared_UI_0

            comment: "GROUPING FACTORS (COLUMN HEADERS)"
            sentence: "Sequencing factor (x-Axis)", iFactor$
            sentence: "Comparison factor (y-axis, colour)", oFactor$
            boolean: "Use tertiary filters (remove unwanted data)",
            ... tertiaryFilters

            comment: "FORMANT COLUMNS"
            sentence: "Formant A", f1Col$
            sentence: "Formant B", f2Col$
            sentence: "Formant C", f3Col$
            sentence: "Formant D", f4Col$
            optionMenu: "Input units", inputUnits
                option: "Hertz"
                option: "Bark"

            @addShared_UI_1

        myChoice = endPause: "Exit", "Apply", 2, 1
        # respond to myChoice
        if myChoice = 1
            exit
        endif

        # error handling
        done =
        ... !(
        ... (comparison_factor$ == sequencing_factor$) or
        ...     (
        ...     table_address_or_object_number$ = "" or
        ...     comparison_factor$ = "" or
        ...     sequencing_factor$ = ""
        ...     )
        ... )
        if (formant_D$ != "" and
            ... (formant_C$ = "" or formant_B$ = "" or formant_A$ = ""))
            ... or (formant_C$ != "" and (formant_B$ = "" or formant_A$ = ""))
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
    oFactor$ = comparison_factor$
    iFactor$ = sequencing_factor$
    inputUnits = input_units
    tertiaryFilters = use_tertiary_filters
    inputUnits$[1] = "Hertz"
    inputUnits$[2] = "Bark"
    f1Col$ = formant_A$
    f2Col$ = formant_B$
    f3Col$ = formant_C$
    f4Col$ = formant_D$
    headerList$ = "'f1Col$','f2Col$','f3Col$','f4Col$'," +
    ... "'oFactor$','iFactor$'"

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


    # first pass on outer and inner factors
    if !(keepGoing > 1 and plotUses = 3)
        @summariseFactor:  table, iFactor$, "i"
        @checkMax50: iLevels, table, iFactor$, 1
        @filterLevels: table, iFactor$, "i", "newStateIsOldOne"
        table = filterLevels.table
    endif
    @summariseFactor:  table, oFactor$, "o"
    @checkMax50: oLevels, table, oFactor$, 1
    @filterLevels: table, oFactor$, "o", "newStateIsOldOne"
    table = filterLevels.table

    # run tertiary filter UI first to remove unwanted items
    if tertiaryFilters
        @filterTertFactors: table, "factorName$", numFactors,
        ... "../data/vars/", "ladTertFactor.var",
        ... headerList$
        table = filterTertFactors.table
        # recalculate outer levels based on purged table
        @summariseFactor: table, oFactor$, "o"
        @summariseFactor: table, iFactor$, "i"
    endif


    # Get list of xAxis Text Options
    xAxisOptions = 0
    selectObject: table
    for i to numFactors
        @summariseFactor:  table, factorName$[i], "cur"
        if curLevels = iLevels
            xAxisOptions += 1
            xAxisOption$[xAxisOptions] = factorName$[i]
            for j to iLevels
                xAxisLevel$[xAxisOptions, j] = curLevel$[j]
            endfor
            # always reset xAxisFactor to default in first loop.
            if !prevLoops and factorName$[i] = iFactor$
                xAxisFactor = xAxisOptions
            endif
        endif
    endfor
endproc

procedure doOutputUI
    @hideObjs: "table", "../data/temp/", "hiddenTx"
    beginPause: "Graphical Output Settings: Ladefoged-style plot"
        comment: "PLOT BASICS"
        sentence: "Title", title$

        @addShared_UI_2

        natural: "Maximum frequency (in "
        ... + inputUnits$[inputUnits] + ".)", maxFreq
        positive: "Interior plot height (inches)", plotHeight
        optionMenu: "Mark X axis using", xAxisFactor
        for i to xAxisOptions
            option: xAxisOption$[i]
        endfor
        comment: "PLOT LAYERS"

        optionMenu: "Data points", tokenMarking
            option: "Hide data points"
            option: "Show all individual data points"
            option: "Show outliers only"
        boolean: "Add jitter to data points", addJitter

        optionMenu: "Averages bar", showAves
            option: "Hide averages bar"
            option: "... shows means"
            option: "... shows median values"
        iUnit$ = inputUnits$[inputUnits]
        boolean: "Display 'iUnit$' values above averages bar" +
        ... "", showAveVals

        optionMenu: "Most prominent layer", dataPointsOnTop
            option: "averages bar / box plot"
            option: "data points"
        boolean: "Distribute ALL factors along the X axis", staggerO
        boolean: "Show boxplots", showIQR
        boolean: "Show arrows", drawArrows
        boolean: "show formants in legend", legendHasFormants

        @addShared_UI_3
    myChoice = endPause: "Exit", "Continue", 2, 1
    if myChoice = 1
        exit
    endif

    @retrieveObjs: "hiddenTx"
    # Process generic outoutUI
    @processShared_UIs
    # Process Lad plot-specific graphic UI
    plotHeight = interior_plot_height
    maxFreq = maximum_frequency
    dataPointsOnTop = most_prominent_layer - 1
    tokenMarking = data_points - 1
    showAves = averages_bar - 1
    showAveVals = display_'iUnit$'_values_above_averages_bar
    staggerO = distribute_ALL_factors_along_the_X_axis
    stagger = staggerO * 1 / oLevels
    addJitter = add_jitter_to_data_points
    showIQR = show_boxplots
    showTail = show_boxplots
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
    plotWidth =
    ... (oLevels * iLevels + (iLevels < 3) * 1.5) *
    ... (1 + staggerO * 0.1) / 2


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
    maxX = iLevels + 0.5

    # Next three lines are need to calculate real world distances before
    # drawing plots. (See also @drawAxisLater.)

    Axes: minX, maxX, minF, maxF
    xDist = Horizontal mm to world coordinates: 0.1
    yDist = Vertical mm to world coordinates: 0.1
endproc

procedure calcLadPlotLayers
    # make dictionary of inner levels
    for i to iLevels
        iLevel[iLevel$[i]] = i
    endfor

    selectObject: table
    # add columns for plot drawing
    Append column: "x"


    for o to oLevels
        Formula:
        ... "x",
        ... "if self$[oFactor$] = oLevel$[o] then " +
        ... "iLevel[self$[iFactor$]] + " +
        ... "stagger * (o - 1) - " +
        ... "staggerO * (oLevels - 1 ) / (2 * oLevels) else " +
        ... "self " +
        ... "endif"
    endfor
    if addJitter
        jitterAdj =
        ... jitter / oLevels * staggerO +
        ... jitter * (staggerO == 0)

        Formula: "x", "self + randomUniform(-jitterAdj, jitterAdj)"
    endif
    # calculate size of potenial tables filtered by
    # levels of outer and inner factors
    @possRows: table, "o", "i"
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

        # create plot table for outer factor
        selectObject: table
        plotTable[o] = Extract rows where: "self$[oFactor$] = curOLevel$"

        for i to iLevels
            curILevel$ = iLevel$[i]
            if possRows.matrix##[o,i]
                # Create inner sub-table of outer table
                # # Note: while "Group mean:" could be used to get mean values
                # # without creating sub-tables, it is not possible to do so
                # # for
                selectObject: table
                iTable[o,i] = Extract rows where:
                ... "self$[oFactor$] = curOLevel$ and " +
                ... "self$[iFactor$] = curILevel$"
                Rename: curOLevel$ + "_" + curILevel$
                tempNumRows = Get number of rows
                meanTInPlot[o,i] = Get mean: "x"
                # get mean formant values for current sub-table
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
            else
                prevMeanFinPlot[o,i,f] = undefined
                iTable[o,i] = undefined
                meanFinPlot[o,i,f] = undefined
            endif
        endfor
    endfor
endproc


# Plot layer procedures
procedure drawLadAxisLayer

    Select inner viewport: left, right, top, bottom + vertAdjust
    nowarn Text bottom: "yes", iFactor$

    Select inner viewport: left, right, top, bottom
    Text left: "yes", "Frequency in " + outputUnits$[outputUnits]

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
                Draw line: minX, 'curLIs$'Freq_DrawVal[line],
                ... maxX, 'curLIs$'Freq_DrawVal[line]
                if minMaj = 2
                    Colour: "Black"
                    Text: minX, "right",
                    ... majorFreq_DrawVal[line], "Half",
                    ... fixed$(majorFreq_AxisVal[line], useKHz)
                endif
            endif
        endfor
    endfor

    for x to iLevels
        Colour: lineColour$[2]
        Draw line: x - 0.5, minF,
        ... x - 0.5, maxF
    endfor
    xFactor$ = xAxisOption$[xAxisFactor]
    for level to iLevels
        Colour: "Black"
        nowarn Text:
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
    # Next three lines are repeated code since change in axis doesn't always
    # seem to register. (See also @calcLadAxisVals above.)
    Axes: minX, maxX, minF, maxF
    xDist = Horizontal mm to world coordinates: 0.1
    yDist = Vertical mm to world coordinates: 0.1
    for o to oLevels
        for i to iLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                x = meanTInPlot[o,i]
                for f to numFormants

                    yMed = medFinPlot[o,i,f]
                    yStart = q1FinPlot[o,i,f]
                    yEnd = q3FinPlot[o,i,f]

                    curColr$[1] = "Black"
                    c = (f/2 == round(f/2) - 0.5) * 0.15
                    @modifyColVectr: oColour$[o, 3], "curColr$[2]", "+'c'"
                    for bgFg to 2
                        Colour: curColr$[bgFg]
                        Line width: 7 - bgFg * 2
                        halfW = xDist * 35
                        if showIQR
                            Draw rectangle:  x - halfW, x + halfW, yStart, yEnd
                            Draw line: x - halfW, yMed, x + halfW, yMed
                        endif

                        if showTail
                            tEnd = tailEnd[o,i,f]
                            tStart = tailStart[o,i,f]
                            if showIQR
                                Draw line: x, yEnd, x, tEnd
                                Draw line: x, yStart, x, tStart
                                Draw line: x - xDist, yMed, x + xDist, yMed
                            else
                                Draw line: x, tStart, x, tEnd
                            endif
                            Draw line: x - halfW, tEnd, x + halfW, tEnd
                            Draw line: x - halfW, tStart, x + halfW, tStart
                        endif
                    endfor
                endfor
            endif
        endfor
    endfor
endproc

procedure drawArrows
    for o to oLevels
        for i from 2 to iLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                curAveX = meanTInPlot[o,i]
                prevAveX = curAveX - 1
                for f to numFormants
                    freqNameIOF$ = "'ave$'" +
                    ... "FinPlot[" +
                    ... string$(o) + "," + string$(i - 1) + "," + string$(f) +
                    ... "]"
                    if !variableExists(freqNameIOF$)
                        'freqNameIOF$' = undefined
                    endif
                    curAveF = 'ave$'FinPlot[o,i,f]
                    prevAveF = 'ave$'FinPlot[o, i - 1, f]
                    gap =  1 - lineRatio
                    xStart = prevAveX + gap / 3 * (curAveX - prevAveX)
                    xEnd = curAveX - gap / 3 * (curAveX - prevAveX)
                    yStart = prevAveF + gap / 3 * (curAveF - prevAveF)
                    yEnd = curAveF - gap / 3 * (curAveF - prevAveF)

                    if prevAveF != undefined
                        @bgColr: oColour$[o,4], oColour$[o,5], oColour$[o,2],
                        ... colrAdj#, 0.19567
                        Line width: 4
                        Arrow size: 1.05
                        Draw arrow: xStart, yStart, xEnd, yEnd
                        Colour: oColour$[o, 4]
                        Line width: 2
                        Arrow size: 1
                        Draw arrow: xStart, yStart, xEnd, yEnd
                    endif
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

    for o to oLevels
        curColour$ = oColour$[o,3]
        for i to iLevels
            # Only draw plots where plot table exists!
            if possRows.matrix##[o,i]
                curAveX = meanTInPlot[o,i]
                for f to numFormants
                    curAveF = 'ave$'FinPlot[o,i,f]
                    c = (f/2 = round(f/2)) * 0.09
                    curColr$ = oColour$[o, 3]
                    @modifyColVectr: oColour$[o, 3], "curColr$", "+'c'"
                        @drawOblong:
                        ... curAveX, curAveF,
                        ... pi^0.5 * bulletSize * 1.5, pi^0.5 * bulletSize / 4,
                        ... curColr$, f, 8, 1
                        if showAveVals
                            Colour: {1, 1, 1}
                            xDist = Horizontal mm to world coordinates: 0.1
                            yDist = Vertical mm to world coordinates: 0.1
                            Text special:
                            ... curAveX + xDist * 1.5, "centre",
                            ... curAveF - yDist * 1.5, "Bottom",
                            ... "Helvetica", fontS, "0",
                            ... "##" + fixed$('ave$'FAct[o,i,f], inputUnits = 2)
                            Colour: "Black"
                            Text special:
                            ... curAveX, "centre",
                            ... curAveF, "Bottom",
                            ... "Helvetica", fontS, "0",
                            ... "##" + fixed$('ave$'FAct[o,i,f], inputUnits = 2)
                        endif

                endfor
            endif
        endfor
    endfor
endproc

procedure drawDataPoints
    Line width: 2
    for o to oLevels
        selectObject: plotTable[o]
        curColour$ = oColour$[o, 3]
        curTCol$ = "x"
        for i to iLevels
            for f to numFormants
                curFCol$ = f'f'Col$ + "DrawValue"
                curColr$[1] = "Black"
                c = (f/2 == round(f/2) - 0.5) * 0.15
                @modifyColVectr: oColour$[o, 3], "curColr$[2]", "+'c'"
                for bgFg to 2
                    Colour: curColr$[bgFg]
                    if tokenMarking
                        # draw outliers
                        Line width: 6 - bgFg
                        nowarn Scatter plot where (mark):
                        ... curTCol$, minX, maxX,
                        ... curFCol$, minF, maxF,
                        ... fontM / 10, "no", "o",
                        ... "self$[oFactor$] = oLevel$[o] and " +
                        ... "!(self[curFCol$] < tailEnd[o,i,f] and " +
                        ... "self[curFCol$] > tailStart[o,i,f]) and " +
                        ... "self$[iFactor$] = iLevel$[i]"
                        if tokenMarking = 1
                            # draw non-outliers
                            nowarn Scatter plot where (mark):
                            ... curTCol$, minX, maxX,
                            ... curFCol$, minF, maxF,
                            ... fontM / 10, "no", "x",
                            ... "self$[oFactor$] = oLevel$[o] and " +
                            ... "self[curFCol$] < tailEnd[o,i,f] and " +
                            ... "self[curFCol$] > tailStart[o,i,f] and " +
                            ... "self$[iFactor$] = iLevel$[i]"
                        endif
                    endfor
                endif
            endfor
        endfor
    endfor
    Line width: 1
endproc

procedure drawTitleLayer
    Select inner viewport: left, right, top, bottom
    Font size: fontL
    nowarn Text top: "yes", "##" + title$
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
    @getGenAxisVars
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
    appendFileLine: .address$, "oFactor$", tab$, "sound"
    appendFileLine: .address$, "iFactor$", tab$, "element"
    appendFileLine: .address$, "tertiaryFilters", tab$, 0
    appendFileLine: .address$, "inputUnits", tab$, 1
    appendFileLine: .address$, "timeRelativeTo", tab$, 1
    appendFileLine: .address$, "oBoolean#", tab$, "{0}"
    appendFileLine: .address$, "iBoolean#", tab$, "{0}"
    appendFileLine: .address$, "formantFlag#", tab$, "{1, 1, 1, 0}"
    appendFileLine: .address$, "plotHeight", tab$, 5
    appendFileLine: .address$, "lineRatio", tab$, 0.5
    appendFileLine: .address$, "prevInputUnit", tab$, 1
    appendFileLine: .address$, "title$", tab$, "nIE diphthongs"
    appendFileLine: .address$, "outputUnits", tab$, 2
    appendFileLine: .address$, "dataPointsOnTop", tab$, 1
    appendFileLine: .address$, "maxFreq", tab$, 4000
    appendFileLine: .address$, "tokenMarking", tab$, 3
    appendFileLine: .address$, "showAves", tab$, 2
    appendFileLine: .address$, "showAveVals", tab$, 1
    appendFileLine: .address$, "addJitter", tab$, 0
    appendFileLine: .address$, "staggerO", tab$, 1
    appendFileLine: .address$, "jitter", tab$, 1/20
    appendFileLine: .address$, "showIQR", tab$, 1
    appendFileLine: .address$, "showTail", tab$, 1
    appendFileLine: .address$, "drawArrows", tab$, 0
    appendFileLine: .address$, "legendHasFormants", tab$, 0
    appendFileLine: .address$, "ellipsisSDs", tab$, 3
    appendFileLine: .address$, "saveName$", tab$, "LadFormantPlot.png"
    @appendSharedVars: .address$
endproc

include _aeroplotFns.praat
include _genFnBank.praat
