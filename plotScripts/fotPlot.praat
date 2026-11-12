# Formant Over Time Plotter
# =========================
# A feature of the AERoplot plugin.
#
# Written for Praat 6.0.60 or later
#
# script by Antoin Eoin Rodgers
#
# email:     antoin.rodgers@tcd.ie
# github:    github.com/AERodgers

@checkPraatVersion
@objsSelected: "Table", "tableID$"
@purgeDirFiles: preferencesDirectory$ + "/plugin_AERoPlot/data/temp"
curFoTVersion$ = "1.5.0.0"
plotPrefix$ = "FOT."
# Main script loop
keepGoing = 1
while keepGoing
    @defineVars
    if keepGoing = 1
        @doInputUI
    endif
    @validateTable: tableID$,
        ... "timeCol$,f1Col$,f2Col$,f3Col$,f4Col$,oFactor$,iFactor$,repFactor$"
    headerList$ = "'timeCol$','f1Col$','f2Col$','f3Col$','f4Col$'," +
    ... "'oFactor$','iFactor$'"
    @processInputUI
    @doOutputUI
    @hideObjs: "table", preferencesDirectory$ +
    ... "/plugin_AERoPlot/data/temp/", "hiddenTx"
    @setupColours:
    ... preferencesDirectory$ + "/plugin_AERoPlot/data/palettes/",
    ... "colrPalFile$", "curPalette", table, altColrMatch
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
    timeRelativeTo -= (tableID$ ==
    ... preferencesDirectory$ + "/plugin_AERoPlot/example/AER_NI_I.txt")

    keepGoing = plotUses
    firstPass = 0
    @writeVars: preferencesDirectory$ +
    ... "/plugin_AERoPlot/data/vars/", "fotPlot.var"
    viewPort$ =  "'left', 'right', 'top', 'bottom' + 'vertAdjust'"
    @saveImage: saveDir$, saveName$, quality, viewPort$, fontM, "FOT."
    if variableExists("tableID$")
        if string$(number(tableID$)) = tableID$
            selectObject: 'tableID$'
        endif
    endif
endwhile



# UI and input processing procedures


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
        @filterTertFactors: table,
        ... "factorName$",
        ... numFactors,
        ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/",
        ... "fotTertFactor.var",
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
        ... (tableID$ == preferencesDirectory$ +
        ... "/plugin_AERoPlot/example/AER_NI_I.txt")
        @hideObjs: "table", preferencesDirectory$ +
        ... "/plugin_AERoPlot/data/temp/", "hiddenTx"
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
            comment: "Each group and repetition needs exactly one reference time."
        myChoice = endPause: "Exit", "Continue", 2, 1

        if myChoice = 1
            @selectTableID
            exit
        endif
        @retrieveObjs: "hiddenTx"


        timeRelativeTo = make_time_relative_to - 1
        if timeRelativeTo
            timeRelativeTo$ = iLevel$[timeRelativeTo]
            @makeTimeRelative: table, oFactor$, iFactor$, timeCol$,
            ... repFactor$, timeRelativeTo$
        endif
        selectObject: table
        Save as binary file: preferencesDirectory$ +
        ... "/plugin_AERoPlot/data/temp/table.bin"
    elsif plotUses = 2
        oldTable = Read from file: preferencesDirectory$ +
        ... "/plugin_AERoPlot/data/temp/table.bin"
        removeObject: table
        table = oldTable
    endif
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
    @drawSharedTitleLayer: left, right, top, bottom, fontL, fontM, title$
endproc


# Plot calculation procedures
procedure calcFOTAxisIncrements
    jitter = 0.0015

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
    @niceTimeInterval: maxT - minT
    minorTimeDist = niceTimeInterval.minor
    majorTimeDist = niceTimeInterval.major
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

    if tokenMarking and tokenMarking <= numFactors
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
        plotTable[o] = nowarn Extract rows where: "self$[oFactor$] = curOLevel$"

        for i to iLevels
            curILevel$ = iLevel$[i]
            if possRows.matrix##[o,i]

                selectObject: table
                tempTable[o,i] = nowarn Extract rows where:
                    ... "self$[oFactor$] = curOLevel$ and " +
                    ... "self$[iFactor$] = curILevel$"
                tempNumRows = nowarn Get number of rows

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
        Append column: "TAdj"
        for f to numFormants
            curFCol$ = f'f'Col$ + "DrawValue"
            # Draw scatter plot
            if mean('curColour$' * colrAdj#) < 0.19576
                Colour: 'curColour$' + 0.8
            else
                Colour: 'curColour$' - 0.5
            endif

            # draw background outline
            Append column: "F'f'Adj"
            across = 1
            down = -1
            Formula: "TAdj",
            ... "self[curTCol$] + across * xDist * 1.3"
            Formula: "F'f'Adj",
            ... "self[curFCol$] + down * yDist * 1.3"
            if tokenMarking <= numFactors
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
            if tokenMarking <= numFactors
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
                    nowarn Draw ellipses where: curTCol$, minT, maxT,
                    ... curFCol$, minF, maxF,
                    ... oFactor$,
                    ... ellipsisSDs, 0, "no",
                    ... "self$[iFactor$] = curInner$"
                    curFCol$ = f'f'Col$ + "DrawValue"
                    Line width: 2
                    Colour: oColour$[o,4]
                    nowarn Draw ellipses where: curTCol$, minT, maxT,
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
            if possRows.matrix##[o,i] and possRows.matrix##[o,i - 1]
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

# Initialisation procedures and script inclusions
procedure defineVars
    # check / fix directory ending
    @checkDirectoryStructure
    if !fileReadable(
        ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/fotPlot.var")
        @createFoTVars: 
        ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/fotPlot.var"
    endif
    @readVars:
    ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "fotPlot.var"
    if fotVersion$ != curFoTVersion$
        @createFoTVars:
        ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/fotPlot.var"
    endif
    @readVars:
    ... preferencesDirectory$ + "/plugin_AERoPlot/data/vars/", "fotPlot.var"
    @useDefaultSaveFolder
    @getGenAxisVars
    @overwriteVars

    if tableID$ != x_tableID$
        repFactor$ = ""
        timeCol$ = ""
        f3Col$ = ""
        oFactor$ = ""
        iFactor$ = ""
    endif
endproc

procedure createFoTVars: .address$
    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "fotVersion$", tab$, curFoTVersion$
    appendFileLine: .address$, "tableID$", tab$,
        ... preferencesDirectory$ + "/plugin_AERoPlot/example/AER_NI_I.txt"
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
    appendFileLine: .address$, "tokenMarking", tab$, 11
    appendFileLine: .address$, "addJitter", tab$, 1
    appendFileLine: .address$, "showLines", tab$, 1
    appendFileLine: .address$, "ellipsisSDs", tab$, 2
    appendFileLine: .address$, "coreLevel", tab$, 2
    appendFileLine: .address$, "saveName$", tab$, "Formants_over_Time.png"
    @appendSharedVars: .address$
endproc

include _aeroplotFns.praat
include _genFnBank.praat
include _ui_common.praat
include _praat_fot_ui.praat
