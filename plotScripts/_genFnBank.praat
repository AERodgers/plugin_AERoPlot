# General Functions
# =================
# A component of the AERoplot plugin.
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
# This bank of procedures are used in but are not specific to AERoPlot.
# They contain a variety of maths functions; file, table, and variable
# management functions, as well as a suite of colour management, drawing,
# and legend functions.
#
# As these procedures can be used in other context, I have provided some expl-
# ation about their internal logic in case you want to use or adapt them.
#
# Some of these form groups of procedures which are to be used together (e.g.,
# you need to have been using @legend if you want to use @drawLegendLayer).
# Some procedures are called from with other procedures, e.g. @csvLine2Array
# if called from @calcEdges. If you wish to used such procedures, make sure you
# include the full suite and their dependencies.
#
# With a few exceptions, each procedure uses only local variables (prefixed
# with a dot). Therefore, whenever one procedure is called from inside another,
# input parameters to the procedure being called MUST be written in the form of:
#     @nextProcedure: callingProcedureName.variableName
# This is due to fact that local variables in Praat are not truly local
# variables but essentially global variables with the procedure name as prefix.
#
# While many languages take the syntax: x = myFunction(inptParameter),
# this is not how user generated procedures work in praat.
# In order to simulate the more typical syntax as far as possible, several
# procedures take the form:
#     @myProcedure: inputParameters, "outputParameters"
# In other langauges, this would be equivalent to:
#     outputParameters = myProcedure(inputParameters)
# NOTE: any output parameters which are inputs to the procedure must be
# written as strings. For arrays, indices are not included. e.g., if the output
# is an myArray$[1:10], it would be fed into the procedure as: "myArray$"
#
# Some procedures use an output variable root rather than a variable name.
# For example, in @summariseFactor, .rt$ (root string) is an input to the
# procedure. If rt$ = "myFactor", the procedure will then generate three
# variables which use that as a root:
#     - myFactorLevels     = the number of levels (n) in the factor
#     - myFactorLevel$[n]  = an array of the names of each level
#     - myFactorCount[n]   = an array of the count for each level

procedure checkPraatVersion
    .version$ = praatVersion$
    if number(left$(.version$, 1)) < 6
        echo You are running Praat 'praatVersion$'.
        ... 'newline$'This script runs on Praat version 6.0.40 or later.
        ... 'newline$'To run this script, update to the latest
        ... version at praat.org
        exit
    endif
endproc

# file and variable handling
procedure csvLine2Array: .csvLine$, .size$, .array$

    # correct variable name Strings
    .size$ = replace$(.size$, "$", "", 0)
    if right$(.array$, 1) != "$"
        .array$ += "$"
    endif

    # fix input csvLine array
    .csvLine$ = replace$(.csvLine$, ", ", ",", 0)
    while index(.csvLine$, "  ")
        .csvLine$ = replace$(.csvLine$, "  ", " ", 0)
    endwhile
    .csvLine$ = replace_regex$ (.csvLine$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0)
    .csvLine$ += ","

    # generate output array
    '.size$' = 0
    while length(.csvLine$) > 0
        '.size$' += 1
        .nextElementEnds = index(.csvLine$, ",")
        '.array$'['.size$'] = left$(.csvLine$, .nextElementEnds)
        .csvLine$ = replace$(.csvLine$, '.array$'['.size$'], "", 1)
        '.array$'['.size$'] = replace$('.array$'['.size$'], ",", "", 1)
        if '.array$'['.size$'] = "" or '.array$'['.size$'] = "?"
            '.size$' -= 1
        endif
    endwhile
endproc

procedure vector2Str: .vectorVar$
    # converts a vector to a string with the same variable where # --> $

    .stringVar$ = replace$(.vectorVar$, "#", "$", 0)
    .vector# = '.vectorVar$'
    '.stringVar$' = "{"
    for .i to size(.vector#)
        '.stringVar$' += string$(.vector#[.i]) + ","
    endfor
    '.stringVar$' = left$('.stringVar$', length('.stringVar$') - 1) + "}"
endproc

# Variable Storage and retrieval
#    - Accepts scalar, string, vector, and matrix variables.
#    - stores variables in a TSV file with the headers "variable" and "value"
procedure readVars: .dir$, .file$
    # reads list of variables from TSV .file$ (headers, "variable, "value")
    .vars = Read Table from tab-separated file: "'.dir$''.file$'"
    .prefix$ = left$(.file$, rindex(.file$, ".") - 1)
    '.prefix$'NumVars = Get number of rows
    for .i to '.prefix$'NumVars
        '.prefix$'Var$[.i] = Get value: .i, "variable"
        .curVar$ = '.prefix$'Var$[.i]
        .curValue$ = Get value: .i, "value"

        if right$(.curVar$, 1) = "]"
            # extract array
            .leftBracket = index(.curVar$, "[")
            .curArray$ = left$(.curVar$, .leftBracket - 1)
            .index$ = mid$(.curVar$,
                       ... .leftBracket + 1,
                       ... length(.curVar$) - .leftBracket - 1
                       ... )
            .curVar$ = .curArray$ + "[" + .index$ + "]"
            if right$(.curArray$, 1) = "$"
                # cope with string array value
                '.curVar$' = .curValue$
            else
                # cope with number array value
                '.curVar$' = number(.curValue$)
            endif
        elsif right$(.curVar$, 1) = "$"
            # extract string
            '.curVar$' = .curValue$
        elsif right$(.curVar$, 1) = "#"
            # extract vector
            '.curVar$' = '.curValue$'
        else
            # extract number
            '.curVar$' = number(.curValue$)
        endif
        x_'.curVar$' = '.curVar$'
    endfor
    Remove
endproc

procedure writeVars: .dir$, .file$
    # Writes list of variables to TSV .file$ (headers, "variable, "value")
    .prefix$ = left$(.file$, rindex(.file$, ".") - 1)
    .vars = Read Table from tab-separated file: .dir$ + .file$
    for i to '.prefix$'NumVars
        .curVar$ = '.prefix$'Var$[i]
        if right$(.curVar$, 1) = "$"
            # set string or string array value
            Set string value: i, "value", '.curVar$'
        elsif right$(.curVar$, 1) = "#"
            # set vector
            @vector2Str: .curVar$
            .curVar$ = replace$(.curVar$, "#", "$", 1)
            Set string value: i, "value", '.curVar$'
        else
            # set number or numeric array value
            Set numeric value: i, "value", '.curVar$'
        endif
    endfor
    Save as tab-separated file: "'.dir$''.file$'"
    Remove
endproc

# Table metadata and filtering functions
procedure getFactors: .table, .outputVarRoot$
    selectObject: .table
    '.outputVarRoot$'Factors = Get number of columns
    for i to '.outputVarRoot$'Factors
        '.outputVarRoot$'Factor$[i] = Get column label: i
    endfor
endproc

procedure summariseFactor: .df, .factor$, .rt$
    # Treats table as dataframe, with column headers as factors, and
    # and each unique column entry as a level.

    #create temp copy to sort
    selectObject: .df
    .tempTable = Copy: "Temp"
    Sort rows: .factor$
    # Check column exists
    .factor_exists = Get column index: .factor$
    if not .factor_exists
        exitScript: "Factor (column heading) not found."
    endif

    #correct name of output array
    if right$(.rt$, 1) != "$"
        #create variable name for unique count
        .rt$ += "$"
    endif

    #create names for output variables
    .levels$ = replace$(.rt$, "$", "Levels", 1)
    .levelCount$ = replace$(.rt$, "$", "Count", 1)
    .rt$ = replace$(.rt$, "$", "Level$", 1)

    .num_rows = Get number of rows
    '.levels$' = 1
    '.rt$'[1] = Get value: 1, .factor$

    for .i to .num_rows
        .cur_string$ = Get value: .i, .factor$
        .string_is_new = 1
        for j to '.levels$'
            if .cur_string$ = '.rt$'[j]
                .string_is_new = 0
            endif
        endfor
        if .string_is_new
            '.levels$' += 1
            '.rt$'['.levels$'] = .cur_string$
        endif
    endfor

    # look for number of entries for each unique entry value
    for .i to '.levels$'

        #find first entry for current unique entry value
        .curRow = Search column: .factor$, '.rt$'[.i]

        # populate first element in each array
        '.levelCount$'[.i] = 1
        .curStimMetre$ = '.rt$'[.i]

        # create "done" flag to end array (i.e. end if the last entry was not
        # one of the unique entries or if there are no more table rows)
        .done = (.curRow >= .num_rows) or (.curStimMetre$ != '.rt$'[.i])

        # search the table until there done
        while not .done
            .curRow += 1
            if .curRow < .num_rows
                .curStimMetre$ = Get value: .curRow, .factor$
                if .curStimMetre$ = '.rt$'[.i]
                    '.levelCount$'[.i] += 1
                endif
            endif
            .done = (.curRow >= .num_rows) or (.curStimMetre$ != '.rt$'[.i])
        endwhile

    endfor

    #remove the temp table
    Remove
endproc

procedure filterLevels: .table, .factor$, .rt$, .stateVar$
    # Check x outerBoolean choices
    '.rt$'Boolean# = zero#('.rt$'Levels)
    if '.stateVar$' and
            ... size('.rt$'Boolean#) = size(x_'.rt$'Boolean#) and
            ... sum(x_'.rt$'Boolean#)
         '.rt$'Boolean# = x_'.rt$'Boolean#
    else
        # avoid index error first time script is run
        '.stateVar$' = 0
        x_'.rt$'Boolean# = '.rt$'Boolean#
    endif

    .varRoot$ = replace_regex$('.rt$'Factor$, "^.", "\l&", 1)

    .comment$ = ""
    .levelsChosen = 0
    while ! .levelsChosen
        beginPause: "Levels to display in graphic."
            comment:
            ... "Select entries from """ + '.rt$'Factor$ + """  to display:"
            comment: .comment$
                for .i to '.rt$'Levels
                    '.rt$'Boolean$[.i] = .varRoot$ + "_" +
                    ... replace_regex$('.rt$'Level$[.i], "[^A-Za-z0-9]", "_", 0)
                    boolean: '.rt$'Boolean$[.i], '.rt$'Boolean#[.i]
                endfor
        .myChoice = endPause: "Exit", "Continue", 2, 1
        .comment$ = "You must choose AT LEAST ONE level."
        if .myChoice = 1
            removeObject: .table
            exit
        endif
        for .i to '.rt$'Levels
            .curBoolean$ = '.rt$'Boolean$[.i]
            '.rt$'Boolean#[.i] = '.curBoolean$'
        endfor
        .levelsChosen = sum('.rt$'Boolean#)
    endwhile
    # Calculate index and count of outer levels to plot
    '.rt$'LevelsToPlot = 0
    for .i to '.rt$'Levels
        .curBoolean$ = '.rt$'Boolean$[.i]
        if '.curBoolean$'
            '.rt$'LevelsToPlot += 1
            '.rt$'LevelToPlot['.rt$'LevelsToPlot] = .i
        endif
    endfor

    # Purge table of outer levels which will not be plotted.
    for .i to '.rt$'Levels
        .deleteMe = 1
        for .j to '.rt$'LevelsToPlot
            if .i = '.rt$'LevelToPlot[.j]
                .deleteMe = 0
            endif
        endfor
        if .deleteMe
            .deleteThis$ = '.rt$'Level$[.i]
            @removeRowsWhereStr: .table,
                             ... '.rt$'Factor$,
                             ... " = filterLevels.deleteThis$"
        endif
    endfor

    # recalculate outer levels based on purged table
    @summariseFactor: filterLevels.table, '.rt$'Factor$, .rt$
endproc

procedure filterTertFactors: .table, .factorArray$, .numFactors,
    ... .dir$, .file$,
    ... .exclusions$
    # NB: This functions still uses the global variables:
    #    - tertiaryFilters
    #    - x_tertiaryFilters
    #    - newStateIsOldOne

    # process exclusions
    @csvLine2Array: .exclusions$,
        ... "filterTertFactors.numHeaders",
        ... "filterTertFactors.headerArray$"

    selectObject: .table
    .maxLevels = Get number of rows
    .posTertFactrs = 0

    #get list of potential tertiary filtering factors
    for .i to .numFactors
        .validFactor = 1
        for .j to .numHeaders
            if '.factorArray$'[.i] = .headerArray$[.j]
                .validFactor = 0
                .j = .numHeaders
            endif
        endfor
        if .validFactor
            @summariseFactor:  .table, '.factorArray$'[.i], "filterTertFactors.curFactr"
            if .curFactrLevels > 1 and .curFactrLevels < .maxLevels
                # not possible to filter a factor with only one level
                # and if num level = max levels, every row is unique
                # and not suitable for filtering
                .posTertFactrs += 1
                .posTertFactr$[.posTertFactrs] = '.factorArray$'[.i]
                .tertFactorBoolean[.posTertFactrs] = 0
                .posTertFactrLevels[.posTertFactrs] = .curFactrLevels
            endif
        endif
    endfor

    if .posTertFactrs

        newStateIsOldOne = newStateIsOldOne and
                       ... fileReadable("'.dir$''.file$'") and
                       ... tertiaryFilters= x_tertiaryFilters
        # create set of possible tertiary factor variable flags
        for .i to .posTertFactrs
            .factorVar$[.i] = replace_regex$("factor "  + .posTertFactr$[.i],
                                      ... "[^A-Za-z0-9]", "_", 0)
            .curVar$ = .factorVar$[.i]
            '.curVar$' = 0
        endfor

        #populate possible tertiary factor variable flags
        if newStateIsOldOne
            @readVars: .dir$, .file$
        endif

        # UI to select tertiary factors
        beginPause: "Tertiary Filters"
            comment: "Choose tertiary factors for filtering your data."
            for .i to .posTertFactrs
                .curVar$ = .factorVar$[.i]
                boolean: .curVar$, '.curVar$'
            endfor
        .myChoice = endPause: "Exit", "Continue", 2, 1

        if .myChoice = 1
            removeObject: .table
            exit
        endif

        writeFileLine: "'.dir$''.file$'", "variable", tab$, "value"
        for .i to .posTertFactrs
            .curVar$ = .factorVar$[.i]
            appendFileLine: "'.dir$''.file$'", .curVar$, tab$,  '.curVar$'
            .oldTertIsNewTert[.i] = 0
        endfor

        # Create array of tertiary filters
        .tertFactors = 0
        for .i to .posTertFactrs
            .curVar$ = .factorVar$[.i]
            if '.curVar$'
                .tertFactors += 1
                .tertFactor$[.tertFactors] = .posTertFactr$[.i]
                appendFileLine: "'.dir$''.file$'",
                    ... ".tertFactor$[" + string$(.tertFactors) + "]", tab$,
                    ... .tertFactor$[.tertFactors]
                # check for parity between (potential) old and new factor names.
                if variableExists("x_.tertFactor$['.tertFactors']")
                    if x_.tertFactor$[.tertFactors] = .tertFactor$[.tertFactors]
                        .oldTertIsNewTert[.i] = 1
                    endif
                endif

            endif
        endfor

        # Tertiary factor filter UIs
        for .i to .tertFactors

            # reassess factor in table
            @summariseFactor:  .table, .tertFactor$[.i], "filterTertFactors.curFactr"

            if .curFactrLevels > 1

                # Some factors may be pruned to 1 level from iterations of loop.

                # level filter UI
                beginPause: "Filter " + .tertFactor$[.i]
                    comment: "Filter """ + .tertFactor$[.i] + """."

                    for .j to .curFactrLevels
                        .levelVar$[.j] = replace_regex$(
                                            ... "value "  + .curFactrLevel$[.j],
                                            ... "[^A-Za-z0-9]", "_", 0)
                        .curVar$ = .levelVar$[.j]
                        if variableExists(.curVar$) and .oldTertIsNewTert[.i]
                            .curBoolean = '.curVar$'
                        else
                            .curBoolean = 1
                        endif
                        boolean: .curVar$, .curBoolean
                    endfor
                .myChoice = endPause: "Exit", "Continue", 2, 1

                if .myChoice = 1
                    removeObject: .table
                    exit
                endif

                for .j to .curFactrLevels
                    # add .curFactrLevel choices to tertFactor.var
                    .curVar$ = .levelVar$[.j]
                    .curBoolean = '.curVar$'
                    appendFileLine: "'.dir$''.file$'",
                        ... .curVar$, tab$, '.curVar$'
                endfor

                # purge table of unwanted factor levels
                for .j to .curFactrLevels
                    .curVar$ = .levelVar$[.j]
                    if !'.curVar$'
                        .curLevel$ = .curFactrLevel$[.j]
                        @removeRowsWhereStr: .table,
                                ... .tertFactor$[.i],
                                ... " = ""'.curLevel$'"""
                    endif
                endfor

            endif

        endfor

    endif
endproc

procedure removeRowsWhereStr: .table, .col$, .criteria$

    selectObject: .table
    .num_rows = Get number of rows

    for .i to .num_rows
        .cur_row = .num_rows + 1 - .i
        .cur_value$ = Get value: .cur_row, .col$
        if .cur_value$ '.criteria$'
            Remove row: .cur_row
        endif
    endfor
endproc

procedure possRows: .table, .outer$, .inner$
    # creates a matrix## of table sizes for tables which might be generated
    # by column filtering.
    selectObject: .table
    .numRows = Get number of rows
    .matrix## = zero##('.outer$'Levels, '.inner$'Levels)
    for .o to '.outer$'Levels
        .curOLvl$ = '.outer$'Level$[.o]
        for .i to '.inner$'Levels
            .curILvl$ = '.inner$'Level$[.i]
            for .curRow to .numRows
                .curOVal$ = Get value: .curRow, '.outer$'Factor$
                .curIVal$ = Get value: .curRow, '.inner$'Factor$
                if .curOVal$ = .curOLvl$ and .curIVal$ = .curILvl$
                    .matrix##[.o,.i] = .matrix##[.o,.i] + 1
                endif
            endfor
        endfor
    endfor
endproc

# Useful date function to create unique timestamps in date.index (measured in
# seconds from  Jan 1, 2020) and date.index$ ("YY.MM.DD.HH.MM.SS" format)
procedure date
    .zeros$ = "00"
    month.num["Jan"] = 1
    month.num["Feb"] = 2
    month.num["Mar"] = 3
    month.num["Apr"] = 4
    month.num["May"] = 5
    month.num["Jun"] = 6
    month.num["Jul"] = 7
    month.num["Aug"] = 8
    month.num["Sep"] = 9
    month.num["Oct"] = 10
    month.num["Nov"] = 11
    month.num["Dec"] = 12

    .day$ = left$(date$(),3)
    .day = number(mid$(date$(),9,2))
    .day0$ = mid$(date$(),9,2)

    .month$ = mid$(date$(),5, 3)
    .month = month.num[.month$]
    .month0$ = left$(.zeros$, 2-length(string$(.month))) +  string$(.month)

    .year$ = right$(date$(),4)
    .year = number(.year$)
    .time$ = mid$(date$(), 12, 5)
    .hour = number(mid$(date$(), 12, 2))
    .min = number(mid$(date$(), 15, 2))
    .sec = number(mid$(date$(), 18, 2))

    .index = .sec
    ... + .min           * 60
    ... + .hour          * 60 * 60
    ... + (.day -1)      * 60 * 60 * 24
    ... + (.month - 1)   * 60 * 60 * 24 * 31
    ... + (.year - 2020) * 60 * 60 * 24 * 31 * 12

    .index$ = .year$
    ... + "." + .month0$
    ... + "." + .day0$
    ... + "." + mid$(date$(), 12, 2)
    ... + "." + mid$(date$(), 15, 2)
    ... + "." + mid$(date$(), 18, 2)
endproc

# Maths functions
procedure hz2Bark: .inputObject$, .dummyParam$
    if  right$(.inputObject$, 2) = "##"
        # Calculate answer for 2D matrix
        for .row to numberOfRows('.inputObject$')
            for .col to numberOfColumns('.inputObject$')
                .curNum = '.inputObject$'[.row, .col]
                '.inputObject$'[.row, .col] = 13 * arctan(7.6e-4 * .curNum) +
                    ... 3.5 * ((.curNum / 7500)^2)
            endfor
        endfor

    elsif right$(.inputObject$, 1) = "#"
        # Calculate answer for vector
        for .i to size('.inputObject$')
            .curNum = '.inputObject$'[.i]
            '.inputObject$'[.i] = 13 * arctan(7.6e-4 * .curNum) +
                ... 3.5 * ((.curNum / 7500)^2)
        endfor

    elsif variableExists(.inputObject$) and .dummyParam$ = ""
        '.inputObject$' = 13 * arctan(7.6e-4 * '.inputObject$') +
                    ... 3.5 * (('.inputObject$' / 7500)^2)

    elsif .dummyParam$ != ""
        # Calculate answer for range of columns in a table.
        .inputVar = '.inputObject$'
        selectObject: .inputVar

        .leftMost$ = left$(.dummyParam$, index(.dummyParam$, " ") - 1)
        .rightMost$ = right$(.dummyParam$,
                         ... length(.dummyParam$) - rindex(.dummyParam$, " "))

        if .leftMost$ = ""
            .leftMost$ = .rightMost$
        endif

        Formula (column range): .leftMost$, .rightMost$,
            ... "fixed$(13 * arctan(7.6e-4 * self) + " +
            ... "3.5 * ((self / 7500)^2), 3)"

    elsif .inputObject$ = string$(number(.inputObject$)) and .dummyParam$ = ""
        # Calculate answer for number.
       .ans = 13 * arctan(7.6e-4 *'.inputObject$') +
          ... 3.5 * (('.inputObject$' / 7500)^2)

       if variableExists(.inputObject$)
           '.inputObject$' = .ans
       endif

   elsif .dummyParam$ != ""
       # Calculate answer for range of columns in a table.
       .inputVar = '.inputObject$'
       selectObject: .inputVar

       .leftMost$ = left$(.dummyParam$, index(.dummyParam$, " ") - 1)
       .rightMost$ = right$(.dummyParam$,
                        ... length(.dummyParam$) - rindex(.dummyParam$, " "))

       if .leftMost$ = ""
           .leftMost$ = .rightMost$
       endif

       Formula (column range): .leftMost$, .rightMost$,
           ... "fixed$(13 * arctan(7.6e-4 * self) + " +
           ... "3.5 * ((self / 7500)^2), 3)"
    else
        .ans = undefined
    endif
endproc

procedure factorialNat0: .in, .out$
    # '.out$' = .in!, where .in is a natural number (including 0)
    if .in != abs(round(.in))
        '.out$' = undefined
    elsif .in = 0
        '.out$' = 1
    else
        '.out$' = .in
        for .i from 2 to .in - 1
            '.out$' = '.out$' * .i
        endfor
    endif
endproc

procedure dec2hex: .in, .out$
    if right$(.out$) != "$"
        .out$ = .out$ + "$"
    endif
    .hex$[0] = "0"
    .hex$[1] = "1"
    .hex$[2] = "2"
    .hex$[3] = "3"
    .hex$[4] = "4"
    .hex$[5] = "5"
    .hex$[6] = "6"
    .hex$[7] = "7"
    .hex$[8] = "8"
    .hex$[9] = "9"
    .hex$[10] = "A"
    .hex$[11] = "B"
    .hex$[12] = "C"
    .hex$[13] = "D"
    .hex$[14] = "E"
    .hex$[15] = "F"

    .q = .in
    '.out$' = ""
    while .q > 0
        .q = floor(.in / 16)
        .r = .in - .q * 16
        '.out$' =  .hex$[.r] + '.out$'
        .in = .q
    endwhile
endproc

procedure calcEdges: .inputTable, .weighting#, .dimensions$
    # Generates a table of edges (edge length and two vertices) for a complete
    # graph.
    # Each vertex is located in n-dimensional space, with coordinates defined
    # by the table columns listed in the dimensions$ CSV array.
    # The .weighting# vector performs elementwise multiplication on each set
    # of coordinates ().
    # Edge length is then determined by the Euclidean distance between each
    # vertex number.

    selectObject: .inputTable
    @csvLine2Array: .dimensions$, "calcEdges.numDims", "calcEdges.dim$"
    .numRows = Get number of rows
    .totEdges = .numRows * (.numRows - 1) / 2
    .table = Create Table with column names:
                 ... "edgeTable", .totEdges, "node1 node2 edge"
    .numEdges = 0
    .curRow# = zero#(.numDims)
    .curClm# = zero#(.numDims)

    for .row to .numRows
        selectObject: .inputTable
        for .curDim to .numDims
            .curRow#[.curDim] = Get value: .row, .dim$[.curDim]
        endfor
        for .clm from 1 to .row - 1
            selectObject: .inputTable
            for .curDim to .numDims
                .curClm#[.curDim] = Get value: .clm, .dim$[.curDim]
            endfor

            .curClm# =
            ... (size(.weighting#) == .numDims) * .curClm# * .weighting# +
            ... (size(.weighting#) != .numDims) * .curClm#

            .numEdges += 1

        selectObject: .table
        Set numeric value: .numEdges, "node1", .row
        Set numeric value: .numEdges, "node2", .clm
        Set numeric value: .numEdges, "edge", sum((.curClm# - .curRow#)^2)^0.5
        endfor
    endfor
endproc

procedure calcLongWalk: .table
    # This attempts to find the least optimal path in a complete graph (i.e.
    # where all vertices are connected) where the walk must pass through each
    # once.
    # It assumes that the least optimal path is the one where -- for each new
    # edge -- the next vertex visited will be maximally distant from all the
    # vertices passed previously.
    # The sum of the distances from the next vertex to all vertices already
    # passed is used to calculate the efficiency of the path from that vertex.
    # (NOTE, this is essentially a heuristic and may not be the best approach.)
    selectObject: .table
    .totEdges = Get number of rows
    .numNodes = 0.5 *  (((8 * .totEdges + 1)^0.5) + 1)
    .visited#  = zero#(.totEdges)

    ### populate first row of .visitedTable
    Sort rows: "edge"
    .startAt[1] = Get value: .totEdges, "node1"
    .journey[1] = Get value: .totEdges, "edge"
    .stopAt[1] = Get value: .totEdges, "node2"
    .visited#[.startAt[1]] = 1

    ### main loop
    for .curStop from 2 to .numNodes
        .startAt[.curStop] = .stopAt[.curStop - 1]

        # flag current stop as visited#
        .visited#[.startAt[.curStop]] = 1
        .numUnvisited = .numNodes - sum(.visited#)
        .numVisited = sum(.visited#)

        # get vector or places to try visiting next and to potentially revisit
        .tryVisiting# = zero#(.numUnvisited)
        .returnTo# = zero#(.numVisited - 1)

        .nextVisit = 0
        .alreadyVisited = 0
        for .i to .numNodes
            if .visited#[.i] and .i != .startAt[.curStop]
                .alreadyVisited += 1
                .returnTo#[.alreadyVisited] = .i
            elsif !.visited#[.i]
                .nextVisit += 1
                .tryVisiting#[.nextVisit] = .i
            endif
        endfor

        for .i to .numUnvisited
            selectObject: .table
            .vTempTable = Extract rows where:
                    ... "self[""node1""] = .tryVisiting#[.i] or " +
                    ... "self[""node2""] = .tryVisiting#[.i]"
                .inNode1 = Search column: "node1", string$(.startAt[.curStop])
                .inNode2 = Search column: "node2", string$(.startAt[.curStop])
                if .inNode1
                    .totDistance[.i] = Get value: .inNode1, "edge"
                else
                    .totDistance[.i] = Get value: .inNode2, "edge"
                endif
            for .j to .numVisited - 1
                .inNode1 = Search column: "node1", string$(.returnTo#[.j])
                .inNode2 = Search column: "node2", string$(.returnTo#[.j])
                if .inNode1
                    .totDistance[.i] += Get value: .inNode1, "edge"
                else
                    .totDistance[.i] += Get value: .inNode2, "edge"
                endif
            endfor
            removeObject: .vTempTable
        endfor

        # choose longest journey
        .longest = 0
        .stopAt[.curStop] = 0
        for .i to .numUnvisited
            if .totDistance[.i] > .longest
                .longest = .totDistance[.i]
                .stopAt[.curStop] = .tryVisiting#[.i]
            endif
        endfor

    endfor

    # output friendly array name
    for .i to .numNodes
        seqColrByDist.clr[.i] = .startAt[.i]
    endfor
endproc

# Colour functions
# mst of these functions depend on a *.palette file with two rows:
#    row 1. JS String of RGB colour scheme
#    row 2. CSV list of colours to match first row

procedure setupColours: .dir$, .colrPalFileVar$, .colourPalVar$,
        ... .table, .altColrMatch

    if ! variableExists("changeAddColSch")
        changeAddColSch = 0
    endif

    if ! variableExists("makeNewColSeq")
        makeNewColSeq = 0
    endif

    if ! variableExists("maxColDiff")
        maxColDiff = 0
    endif

    if ! variableExists("colrAdj#")
        colrAdj# = {0.299,0.587,0.114}
    endif

    if ! variableExists("sortByBrightness")
        sortByBrightness = 0
    endif


    @readInColPal: .dir$, .colrPalFileVar$, .colourPalVar$

    # call extra colour menus
    if changeAddColSch
        @changeAddColSch: .dir$, .colrPalFileVar$
        @readInColPal: .dir$,  .colrPalFileVar$, .colourPalVar$
    endif

    if makeNewColSeq
        @makeNewColSeq: "'.colourPalVar$'Name$",
            ... "'.colourPalVar$'Vector$",
            ... '.colourPalVar$'Size,
            ... .dir$,
            ... '.colrPalFileVar$'
        @readInColPal: .dir$, .colrPalFileVar$, .colourPalVar$
    endif

    if maxColDiff
        @seqColrByDist: "../data/palettes/",
            ... .colrPalFileVar$,
            ... colrAdj#,
            ... "curPalette"
    endif

    if sortByBrightness
        @sortByBrightness: curPaletteSize,
                       ... "curPaletteVector$",
                       ... "curPaletteName$"
    endif

    @matchCol2Level: .table,
        ... .altColrMatch,
        ... .colourPalVar$,
        ... "outer"
endproc

procedure sortByBrightness: .size, .vectorV$, .nameV$
    # sorts a given colour palette from darkest to brightest colour
    .tempTable = Create Table with column names:
            ... "temp", .size, "index vector name brightness"
    Formula: "index", "row"
    for .i to  .size
        Set string value: .i, "name", '.nameV$'[.i]
        Set string value: .i, "vector", '.vectorV$'[.i]
        .curVector$ = '.vectorV$'[.i]
        .curVector# = '.curVector$'
        Set numeric value: .i, "brightness",
                       ... mean(.curVector# * colrAdj#)
    endfor
    Sort rows: "brightness"
    for .i to  .size
        '.nameV$'[.i] = Get value: .i, "name"
         '.vectorV$'[.i] = Get value: .i, "vector"
         .index[.i] = Get value: .i, "index"
    endfor
    Remove
endproc

procedure unsortByBrightness: .size, .vectorV$, .nameV$
    # unsorts a palette which had previously been sorted by brightness.
    for .i to .size
        .oldName$[.i] = '.nameV$'[.i]
        .oldVector$[.i] = '.vectorV$'[.i]
    endfor
    for .i to .size
        '.nameV$'[.i] = .oldName$[sortByBrightness.index[.i]]
        '.vectorV$'[.i] = .oldVector$[sortByBrightness.index[.i]]
    endfor
endproc

procedure changeAddColSch: .dir$, .fileVar$
    # A menu colour palettes or add a new one. It uses JS RGB decimal strings,
    # which can be copied directly from colorbrewer.org

    # Get data on current colour palette
    .jsString = Read Strings from raw text file: .dir$ + '.fileVar$'
    .curColrStr$ =  Get string: 1
    .curColrNameArray$ =  Get string: 2
    .curColrPalName$ = replace$('.fileVar$', ".palette", "", 0)
     Remove

    # Get array of colour schemes in root folder.
    .listOfPalettes =  Create Strings as file list: "Plts", .dir$ + "*.palette"
    .numPalettes = Get number of strings
    .colScheme = .numPalettes + 1

    for .i to .numPalettes
        .palette$[.i] = Get string: .i
        .palette$[.i] = replace$(.palette$[.i], ".palette", "", 0)
        appendInfoLine: .palette$[.i], tab$, .curColrPalName$
        if .palette$[.i] = .curColrPalName$
            .colScheme = .i
        endif
    endfor

    removeObject: .listOfPalettes

    # vv--This is a hack to duplicate Info Window and Dialogue Form contents.--v
    .intro$[1] = "writeInfoLine: ""CHANGE OR ADD DEFAULT COLOUR SCHEME"" + " +
             ... "newline$ + ""==================================="""
    .intro$[2] = "beginPause: ""Add or Change colour scheme"""
    .abbr$[1] = "appendInfoLine:"
    .abbr$[2] = "comment:"

    for .i to 2
        .start$ = .intro$[.i]
        .l$ = .abbr$[.i]
    '.start$'
    '.l$' "Choose an available scheme from the ""Colour scheme"" menu."
    '.l$' "Alternatively, select ""New colour scheme"" and follow these steps:"
    '.l$' tab$ +  "1. Visit colorbrewer2.org."
    '.l$' tab$ + "2. Choose a colour scheme."
    '.l$' tab$ + "3. Select ""Export""."
    '.l$' tab$ + "4. Change ""HEX"" option to ""RGB""."
    '.l$' tab$ + "5. Copy all the text from the ""JavaScript"" box."
    '.l$' tab$ + "6. Paste it in the ""JS array"" dialogue box below."
    '.l$'  tab$ + "7. List each colour name in order in the ""Colour names"" "
    '.l$'  tab$ + "   dialogue box. Separate each name with a comma."
    '.l$'  tab$ + "8. Give the scheme a single-word name in the ""Name"" box."
    endfor
    # ^^-----------------------------------------------------------------------^
    comment: ""
    optionMenu: "Colour scheme", .colScheme
        for .i to .numPalettes
            option: .palette$[.i]
        endfor
        option: "New colour scheme"

        comment: "New colour scheme parameters"
        word: "JS array", .curColrStr$
        sentence: "Colour names", .curColrNameArray$
        word: "Name", .curColrPalName$
    myChoice = endPause: "Exit", "Continue", 2, 1
    .colScheme = colour_scheme
    writeInfo: ""

    if myChoice = 1
        if variableExists("table")
            removeObject: table
        endif
        exit
    endif
    if  jS_array$ = "" or colour_names$ = "" or .colScheme <= .numPalettes
        .colScheme = (.colScheme - 1) * (.colScheme <= .numPalettes) + 1
        '.fileVar$' = .palette$[.colScheme] + ".palette"
    else
        '.fileVar$' = name$  + ".palette"
        writeFileLine: .dir$ + '.fileVar$', jS_array$
        appendFileLine: .dir$ + '.fileVar$', colour_names$
    endif
endproc

procedure makeNewColSeq: .colourNames$, .colourVector$, .arraySize,
        ... .dir$, .fileName$
    # A menu to change the default order in which colours appear.
    # (Given the limitations of Praats UI options. this is a bit awkward.)

    # fix potential variable errors
    if right$(.colourNames$) != "$"
        .colourNames$ += "$"
    endif
    if right$(.colourNames$) != "$"
        .colourNames$ += "$"
    endif

    for .i to .arraySize
        .colourOrder[.i] = .i
        .origColOrder[.i] = .i
    endfor

    .check# = zero#(.arraySize)

    .correct = 0
    .myComment$ = ""

    while ! .correct

        beginPause: "Reorder Default Colour Sequence"
                comment: "Choose sequence in which colours will appear."
                comment: .myComment$

                for .i to .arraySize
                    optionMenu: "colour " + string$(.i), .colourOrder[.i]
                        for .j to .arraySize
                            option: '.colourNames$'[.j]
                        endfor
                endfor

        .myChoice = endPause: "Exit", "Revert to Original", "Continue", 2, 1

        if .myChoice = 1
            exit
        elsif .myChoice = 2
            .myComment$ = "Reverted to original sequence"
            for .i to .arraySize
                .colourOrder[.i] = .origColOrder[.i]
                .check#[.colourOrder[.i]] = 0
            endfor
        else
            .myComment$ = "MAKE SURE EACH COLOUR IS CHOSEN ONLY ONCE."
            for .i to .arraySize
                .colourOrder[.i] = colour_'.i'
                .check#[.colourOrder[.i]] = 1
            endfor
        endif
        .correct = sum(.check#) = .arraySize

    endwhile

    for .i to .arraySize
        .origColourNames$[.i] = '.colourNames$'[.i]
        .origColourVector$[.i] = '.colourVector$'[.i]
    endfor
    .colourString$ = ""
    for .i to .arraySize
        '.colourNames$'[.i] = .origColourNames$[.colourOrder[.i]]
        '.colourVector$'[.i] = .origColourVector$[.colourOrder[.i]]
        .colourString$ += '.colourNames$'[.i]
        if .i < .arraySize
            .colourString$ += ","
        endif
    endfor

    @encodeCB_JS_RGB: "'.colourVector$'", .arraySize, "makeNewColSeq.vectorString$"
    writeFileLine:  .dir$ + .fileName$, .vectorString$
    appendFileLine: .dir$ + .fileName$, .colourString$
endproc

procedure readInColPal: .dir$, .colourPalette$, .root$
    # correct variable names
    .root$ = replace$(.root$, "$", "", 0)
    # Get JS RGB colour array string code
    jsString = Read Strings from raw text file:
        ... .dir$ + '.colourPalette$'
    jsArray$ = Get string: 1
    jsColourNames$ = Get string: 2
    Remove
    @decodeCB_JS_RGB: jsArray$, "'.root$'Size", "'.root$'Vector$"
    @csvLine2Array: jsColourNames$, "numColourNames", "'.root$'Name$"

    if '.root$'Size != numColourNames
        deleteFile: .dir$ + '.colourPalette$' + ".palette"
        if variableExists("table")
            removeObject: table
        endif
        exitScript: "Current Colour Palette is corrupted." + newline$ +
            ... "Purging it from memory." + newline$
    endif
endproc

procedure matchCol2Level: .table, .altColrMatch, .paletteRt$, .factorRt$
    # Matches colours with values (levels) in an output parameter.
    .stdColour = 0

    if .altColrMatch

        beginPause: "Colours choices for each " + '.factorRt$'Factor$ + "."
        comment: "Choose colour for each " +  '.factorRt$'Factor$ + "."
        for .i to '.factorRt$'Levels
            .stdColour += 1

            if .stdColour > '.paletteRt$'Size
                .stdColour = 1
            endif
            .curFactorLevel$ = replace_regex$('.factorRt$'Level$[.i],
                ... "[^A-Za-z0-9]", "_", 0)
            optionMenu: "colour for " + .curFactorLevel$, .stdColour
            for .j to '.paletteRt$'Size
                option: '.paletteRt$'Name$[.j]
            endfor
        endfor
        comment: "NOTE: Avoid using the same colour for different levels."
        .myChoice = endPause: "Exit", "Continue", 2, 1

        if .myChoice = 1
            removeObject: .table
            exit
        endif

    else

        for .i to '.factorRt$'Levels
            .stdColour += 1
            if .stdColour > '.paletteRt$'Size
                .stdColour = 1
            endif
            .curFactorLevel$ = replace_regex$('.factorRt$'Level$[.i],
                                        ... "[^A-Za-z0-9]", "_", 0)
            colour_for_'.curFactorLevel$' = .stdColour
        endfor

    endif

    # rationalise array of colour codes re parameter index
    for .i to '.factorRt$'Levels
        .curFactorLevel$ =
            ...  replace_regex$('.factorRt$'Level$[.i],  "[^A-Za-z0-9]", "_", 0)
        '.factorRt$'Colour[.i] = colour_for_'.curFactorLevel$'
    endfor
endproc

procedure decodeCB_JS_RGB: .jsArray$, .count$, .array$

    # correct variable name Strings
    .count$ = replace$(.count$, "$", "", 0)
    if right$(.array$, 1) != "$"
        .array$ += "$"
    endif

    # reformat JS RGB array
    .jsArray$ = replace$(.jsArray$, "[", "", 0)
    .jsArray$ = replace$(.jsArray$, "]", "", 0)
    .jsArray$ = replace$(.jsArray$, "'rgb(", "}{", 0)
    .jsArray$ = replace$(.jsArray$, ")',", "", 0)
    .jsArray$ = replace$(.jsArray$, ",", ",", 0)
    .jsArray$ = replace$(.jsArray$, ")'", "}", 0)
    .jsArray$ = replace$(.jsArray$, ";", "{", 1)
    .jsArray$ = replace$(.jsArray$, "}", "", 1)


    '.count$' = 0
    while length(.jsArray$) > 0
        '.count$' += 1
        .nextVectorEnds = index(.jsArray$, "}")
        .curVector$ = left$(.jsArray$, .nextVectorEnds)
        .vector# = '.curVector$' / 255
        '.array$'['.count$'] =  "{" +
            ... fixed$(.vector#[1], 3) + "," +
            ... fixed$(.vector#[2], 3) + "," +
            ... fixed$(.vector#[3], 3) +
            ... "}"
        .jsArray$ = replace$(.jsArray$, .curVector$, "", 1)
    endwhile
endproc

procedure encodeCB_JS_RGB: .vectorVar$, .arraySize, .outputString$

        # fix potential variable errors
        if right$(.vectorVar$) != "$"
            .vectorVar$ += "$"
        endif
        if right$(.outputString$) != "$"
            .outputString$ += "$"
        endif

       .newString$ = "["
        for .i to .arraySize
            .curVectorString$ = '.vectorVar$'[.i]
            .curVector# = '.curVectorString$' * 255
            .newString$ +=  "'rgb(" +
                ... fixed$(.curVector#[1], 0) + "," +
                ... fixed$(.curVector#[2], 0) + "," +
                ... fixed$(.curVector#[3], 0) +
                ... ")'"
            if .i < .arraySize
                .newString$ += ","
            endif
        endfor

        .newString$ += "]"
        '.outputString$' = .newString$
endproc

procedure modifyColVectr: .curCol$, .newCol$, .change$
    .newCol# = '.curCol$' '.change$'
    for .i to 3
        if .newCol#[.i] > 1
            .newCol#[.i] = 1
        elsif .newCol#[.i] < 0
            .newCol#[.i] = 0
        endif
    endfor

    '.newCol$' = "{" + string$(.newCol#[1])
        ... + ", " + string$(.newCol#[2])
        ... + ", " + string$(.newCol#[3]) + "}"
endproc

procedure bgColr: .fgColr$, .lghtr$, .drkr$, .colrWgt#, .boundary
    if mean('.fgColr$' * .colrWgt#) < .boundary
        Colour: .lghtr$
    else
        Colour: .drkr$
    endif
endproc

procedure seqColrByDist: .dir$, .paletteFileVar$, .weighting#, .outputRoot$
    # takes a colour.palette file as input and, using specified weights,
    # generates a set of output variables ('outputRoot$' + 'Name$'[],
    # + 'Vector$'[], + 'Size') which sequence the input palette in such a way
    # that each colour in the sequence is maximally perceptually different from
    # the all the preceding colours.
    @readInColPal: .dir$, .paletteFileVar$, "newSeq$"
    @colArr2Tbl: newSeqSize, "newSeqVector$"
    @calcEdges: colArr2Tbl.table, .weighting#, "R,G,B"
    @calcLongWalk: calcEdges.table

    '.outputRoot$'Size = newSeqSize
    for .i to newSeqSize
        '.outputRoot$'Vector$[.i] = newSeqVector$[.clr[.i]]
        '.outputRoot$'Name$[.i] = newSeqName$[.clr[.i]]
    endfor

    removeObject: colArr2Tbl.table
    removeObject: calcEdges.table
endproc

procedure colArr2Tbl: .size, .vectorVar$
    # Converts an string array of colour vectors ('.vectorVar$'[]) of .size
    # and converts them into a table.
    .table = Create Table with column names:
            ... "colourTable", .size, "vector brightness"
    Append column: "R"
    Append column: "G"
    Append column: "B"
    for .clm to .size
        Set string value: .clm, "vector", '.vectorVar$'[.clm]
        .curVector$ = '.vectorVar$'[.clm]
        .curVector# = '.curVector$'
        Set numeric value: .clm, "brightness", mean(.curVector#)
        Set numeric value: .clm, "R",.curVector#[1]
        Set numeric value: .clm, "G",.curVector#[2]
        Set numeric value: .clm, "B",.curVector#[3]
    endfor
endproc


# Draw functions
procedure resetDrawSpace: .fontSize
    Erase all
    Font size: .fontSize
    Line width: 1
    Colour: "Black"
    Solid line
    Helvetica
endproc

procedure getOutputScales: .table, .cols$, .fMin, .fMax, .fInc, .outUnit,
                       ... .varRoot$
    # .outUnit = 1 --> [no change]
    # .outUnit = 2 --> [Hz -> Bark]
    # .outUnit = 3 --> [linear -> log]
    # Fn designed originally for frequency warping, 1 and 3 will work with
    # any unit of measurement.
    @csvLine2Array: .cols$,
        ... "getOutputScales.numCols",
        ... "getOutputScales.colArray$"

    for .curCol to .numCols
        .curCol$ = .colArray$[.curCol]
        selectObject: .table
        # assume input and output are the same
        .colExists = Get column index: "'.curCol$'DrawValue"
        if ! .colExists
            Append column: "'.curCol$'DrawValue"
        endif
        Formula: "'.curCol$'DrawValue", "self[.curCol$]"
        '.varRoot$'Min = .fMin
        '.varRoot$'Max = .fMax
        '.varRoot$'Inc = .fInc

        if .outUnit = 2
            # get bark scale output for hertz input
            @hz2Bark: "getOutputScales.table", "'.curCol$'DrawValue"
            @hz2Bark: .varRoot$ + "Max", ""
            @hz2Bark: .varRoot$ + "Min", ""
            @hz2Bark: .varRoot$ + "Inc", ""

        elsif .outUnit = 3
            # get LogHz output for hertz input

            # avoid undefined value ln(0)
            if !ln(.fMin)
                ln(.fMin) = 1
            endif
            if !ln(.fMax)
                ln(.fMax) = 1
            endif

            selectObject: .table
            Formula: "'.curCol$'DrawValue", "ln(self[.curCol$])"
            Formula: "'.curCol$'DrawValue", "ln(self[.curCol$])"
            '.varRoot$'Min = ln(.fMin)
            '.varRoot$'Max = ln(.fMax)
            '.varRoot$'Inc = ln(.fInc)

            # If aim was to calculate  increments for input = output = log(Hz),
            # the increment would be as follows:
            # (ln(.fMax) - ln(.fMin) - 1) / floor((.fMax - .fMin) / .fInc + 1)
        endif

        # Assume reference draw is original input...
        .lowestDraw = ceiling(.fMin /.fInc) * .fInc
        .highestDraw = floor(.fMax /.fInc) * .fInc
        .fCur = .lowestDraw

        '.varRoot$'Lines = 0

        while .fCur <= .fMax
            '.varRoot$'Lines += 1
            '.varRoot$'AxisVal['.varRoot$'Lines] = .fCur
            # if output scaling is different from input values

            if .outUnit = 2
                # Herz --> Bark

                @hz2Bark: string$(.fCur), ""
                '.varRoot$'DrawVal['.varRoot$'Lines] = hz2Bark.ans
            elsif .outUnit = 3
                # Herz --> Hertz (Log)
                '.varRoot$'DrawVal['.varRoot$'Lines] = ln(.fCur)
            else
                # assume output = input
                '.varRoot$'DrawVal['.varRoot$'Lines] = .fCur
            endif
            .fCur += .fInc
        endwhile
    endfor
endproc

procedure drawSquare: .x, .y, .colour$, .bulletSize
    .x10thmm = Horizontal mm to world coordinates: 0.1
    .y10thmm = Vertical mm to world coordinates: 0.1
    .width = pi^0.5 * .x10thmm * .bulletSize / 2
    .height = pi^0.5 * .y10thmm * .bulletSize / 2
    Paint rectangle: "{0.9,0.9,0.9}",
        ... .x - .width * 1.05,
        ... .x + .width * 1.05,
        ... .y - .height * 1.05,
        ... .y + .height * 1.05
    Paint rectangle: "Black",
        ... .x - .width,
        ... .x + .width,
        ... .y - .height,
        ... .y + .height
    Paint rectangle: .colour$,
        ... .x -.width / 1.4,
        ... .x + .width / 1.4,
        ... .y - .height / 1.4,
        ... .y + .height / 1.4
endproc

procedure drawOblong: .x, .y, .width, .height,
    ... .colour$, .lines, .scarcity, .lineWidth
    # draws an oblong with optional cross hatching
    .x10thmm = Horizontal mm to world coordinates: 0.1
    .y10thmm = Vertical mm to world coordinates: 0.1
    .width =  .width * .x10thmm
    .height = .height * .y10thmm

    Paint rectangle: "{0.9,0.9,0.9}",
        ... .x - (.width + .x10thmm * 2),
        ... .x + (.width + .x10thmm * 2),
        ... .y - (.height + .y10thmm * 2),
        ... .y + (.height + .y10thmm * 2)
    Paint rectangle: "Black",
        ... .x - .width,
        ... .x + .width,
        ... .y - .height,
        ... .y + .height
    Paint rectangle: .colour$,
    ... .x - (.width - .x10thmm * 5),
    ... .x + (.width - .x10thmm * 5),
    ... .y - (.height - .y10thmm * 5),
    ... .y + (.height - .y10thmm * 5)

    # draw inner lines
    .yLength = (.height - .y10thmm * 5)
    .xLength = Vertical world coordinates to mm: .yLength
    .xLength = Horizontal mm to world coordinates: .xLength
    .xLength = abs(.xLength * 2)
    .yLength = abs(.yLength * 2)

    .xMin = .x - (.width - .x10thmm * 5)
    .xMax = .x + (.width - .x10thmm * 5)
    .yMin = .y - (.height - .y10thmm * 5)
    .yMax = .y + (.height - .y10thmm * 5)

    Line width: .lineWidth
    Colour: '.colour$' * 0.0

    # DOWN-LEFTWARD DIAGONAL LINES
    if .lines = 1 or .lines = 3 or .lines = 7 or .lines = 8
        .xStart = .xMin
        .yStart = .yMax
        .xEnd = .xStart - .xLength

        while .yStart > .yMin and .xEnd < .xMax
            .yStart = .yMax
            .yEnd = .yMin
            if .xEnd <= .xMin
                .xEnd = .xMin
                .yStart = .yMax
                .yEnd = .yMax + .yLength * (.xEnd - .xStart) / .xLength
            endif
            if .xStart >= .xMax
                .xStart = .xMax
                .yStart = .yMin - .yLength * (.xEnd - .xStart) / .xLength
                .yEnd = .yMin
            endif

            Draw line:
            ... .xStart, .yStart,
            ... .xEnd, .yEnd

            if .xStart < .xMax
                .xStart += .x10thmm * .scarcity * 2^0.5
                .xEnd = .xStart - .xLength
            else
                .xEnd += .x10thmm * .scarcity * 2^0.5
                .xStart = .xStart + .xLength
            endif
        endwhile
    endif
    # DOWN-RIGHTWARD DIAGONAL LINES
    if .lines = 3 or .lines = 4 or .lines = 7 or .lines = 8
        .xStart = .xMax
        .yStart = .yMax
        .xEnd = .xStart + .xLength

        while .yStart > .yMin and .xEnd > .xMin
            .yStart = .yMax
            .yEnd = .yMin
            if .xEnd >= .xMax
                .xEnd = .xMax
                .yStart = .yMax
                .yEnd = .yMax - .yLength * (.xEnd - .xStart) / .xLength
            endif
            if .xStart <= .xMin
                .xStart = .xMin
                .yStart = .yMin + .yLength * (.xEnd - .xStart) / .xLength
                .yEnd = .yMin
            endif

            Draw line:
            ... .xStart, .yStart,
            ... .xEnd, .yEnd

            if .xStart > .xMin
                .xStart -= .x10thmm * .scarcity * 2^0.5
                .xEnd = .xStart + .xLength
            else
                .xEnd -= .x10thmm * .scarcity * 2^0.5
                .xStart = .xEnd - .xLength
            endif
        endwhile
    endif
    # VERTICAL LINES
    if .lines = 2 or .lines = 5 or .lines = 7 or .lines = 8
        .curX = .xMin
        while .curX < .xMax
            Draw line: .curX, .yMax, .curX, .yMin
            .curX += .x10thmm * .scarcity
        endwhile
    endif
    # HORIZONTAL LINES
    if .lines = 5 or .lines = 6 or .lines = 8
        .curY = .yMin
        while .curY <= .yMax
            Draw line: .xMin, .curY, .xMax, .curY
            .curY += .y10thmm * .scarcity
        endwhile
    endif
endproc

procedure drawCircle: .x, .y, .colour$, .bulletSize
    .x10thmm = Horizontal mm to world coordinates: 0.1
    .radius = abs(.x10thmm * .bulletSize)
    Paint circle: "{0.9,0.9,0.9}", .x, .y, .radius * 1.05
    Paint circle: "Black", .x, .y, .radius
    Paint circle: .colour$, .x, .y, .radius / 1.4
endproc

# Legend functions
procedure legend: .addStyle$, .addColour$, .addText$, .addSize
    # This is v.2.0 and is MUCH more flexible than the original.

    if variableExists ("legend.items")
        .items += 1
    else
        .items = 1
    endif

    .style$[.items] =  .addStyle$
    .colour$[.items] = .addColour$
    .text$[.items] = .addText$
    .size[.items] = .addSize
endproc

procedure drawLegendLayer: .xLeft, .xRight, .yBottom, .yTop,
                       ... .fontSize, .viewPort$,
                       ... .xyTable, .xCol$, .yCol$,
                       ... .threshold, .bufferZone, .compromise
                       ... .innerChange, .frameChange

    @csvLine2Array: .yCol$, "drawLegendLayer.yCols", "drawLegendLayer.yCols$"
    @csvLine2Array: .xCol$, "drawLegendLayer.xCols", "drawLegendLayer.xCols$"

    # @drawLegendLayer v.3.0 - copes with CSV string of x and ycols, is much
    # better optimised for chosing an appropriate draw space, and has several
    # new legend shape options.
    Line width: 1
    Font size: .fontSize
    Solid line
    Colour: "Black"
    Select inner viewport: '.viewPort$'

    if .xLeft < .xRight
        .horDir$ = "rising"
    else
        .horDir$ = "falling"
    endif

    if .yBottom < .yTop
        .vertDir$ = "rising"
    else
        .vertDir$ = "falling"
    endif

    # calculate legend width
    .legendWidth = 0
    .legendWidth$ = ""
    for .i to legend.items
        .len = length(legend.text$[.i])
        if .len > .legendWidth
            .legendWidth = .len
            .legendWidth$ =  legend.text$[.i]
        endif
    endfor

    # calculate box dimensions
    Axes: .xLeft, .xRight, .yBottom, .yTop
    .text_width = Text width (world coordinates): .legendWidth$
    .x_unit = Horizontal mm to world coordinates: 4
    .x_start = .xLeft + .x_unit * 0.25
    .x_width = 3.5 * .x_unit + .text_width
    .x_end = .xLeft + .x_width
    .x_buffer = Horizontal mm to world coordinates: .bufferZone
    .y_unit  = Vertical mm to world coordinates: 4
    .y_start = .yBottom + .y_unit * 0.25
    .y_height = .y_unit * (legend.items + 0.6)
    .y_end = .yBottom + .y_height
    .y_buffer  = Vertical mm to world coordinates: .bufferZone
    # calculate  .hor, .vert, (hor = 0 = left; vert = 0 = bottom)
    # Get stats for coordinates
    .horS[1] = .x_start
    .horE[1] = .x_end
    .horS[2] = .xRight - .x_width
    .horE[2] = .xRight - .x_unit * 0.25

    .vertS[1] = .y_start
    .vertE[1] = .y_end
    .vertS[2] = .yTop - .y_height
    .vertE[2] = .yTop - .y_unit * 0.25

    .inZone## = {{0, 0}, {0, 0}}
    selectObject: .xyTable
    .numRows = Get number of rows
    .total = .numRows * .xCols * .yCols

    for .curXCol to .xCols
        .curXCol$ = .xCols$[.curXCol]
        for .curYCol to .yCols
            .curYCol$ = .yCols$[.curYCol]
            for .lr to 2
                for .bt to 2
                    for .i to .numRows
                        .curX = Get value: .i, .curXCol$
                        .curY = Get value: .i, .curYCol$

                        if .horDir$  ="rising"
                            .insideHor = .curX >= .horS[.lr] - .x_buffer and
                                ... .curX <= .horE[.lr] + .x_buffer
                        else
                            .insideHor = .curX <= .horS[.lr] - .x_buffer and
                                ... .curX >= .horE[.lr] + .x_buffer
                        endif

                        if .vertDir$  ="rising"
                            .insideVert = .curY >= .vertS[.bt] - .y_buffer and
                            ... .curY <= .vertE[.bt] + .y_buffer
                        else
                            .insideVert = .curY <= .vertS[.bt] - .y_buffer and
                            ... .curY >= .vertE[.bt] + .y_buffer
                        endif

                        if .insideVert and .insideHor
                            .inZone##[.bt, .lr] = .inZone##[.bt, .lr] + 1
                        endif
                    endfor

                endfor
            endfor
        endfor
    endfor
    .least# = {0,0}
    .least = 10^10
    for .lr to 2
        for .bt to 2
            if .inZone##[.bt, .lr] < .least
                .least = .inZone##[.bt, .lr]
                .least# = {.lr, .bt}
            endif
        endfor
    endfor

    # adjust coordinates to match horizontal and vertical alignment
    .x_end = .horE[.least#[1]]
    .x_start = .horS[.least#[1]]
    .y_start = .vertS[.least#[2]]
    .y_end = .vertE[.least#[2]]

     if .least / .total > .threshold
        .outerX = Horizontal mm to world coordinates: (19)
        .outerY = Vertical mm to world coordinates: (11)
        # shift legend outside the Window (left or right)
        # if part of legend will still be in window, lower legend

        if .xRight > .xLeft

            if .least#[1] = 1
                .x_start = .xLeft - (.outerX - (.x_unit / 2))
                .x_end = .x_start + .x_width
            else
                .x_end = .xRight + (.outerX - (.x_unit / 2))
                .x_start = .x_end - .x_width
            endif

        elsif .least#[1] = 2

            .x_start = .xLeft - (.outerX - (.x_unit / 2))
            .x_end = .x_start + .x_width
        else

            .x_start = .xRight - (.outerX - (.x_unit / 2))
            .x_end = .x_start - .x_width

        endif

        .y_start = .yBottom - .outerY * (.least#[2] = 2)
        .y_end = .y_start + .y_height
     endif

    # Draw main legend only if percentage of data points hidden < threshold
    if .least / .total <= .threshold or .compromise

        ### Draw box and frame
        Paint rectangle: 0.9, .x_start, .x_end,
                     ... .y_start,  .y_end
        Colour: "Black"
        Draw rectangle: .x_start, .x_end,
                     ... .y_start,  .y_end

        # Draw Text Lines and icons
        for .order to legend.items
            .i = legend.items - .order + 1
            .i = .order
            Font size: .fontSize
            # use colour text if no box
            Colour: "Black"
            Text: .x_start + 2.5 * .x_unit , "Left", .y_end  - .y_unit * (.i - 0.3),
                ... "Half", "##" + legend.text$[.i]
            Helvetica

            if left$(legend.style$[.i], 1) =
                    ... "L" or left$(legend.style$[.i], 1) = "l"
                Line width: legend.size[.i] + 2
                Colour: "White"
                Draw line: .x_start + 0.5 * .x_unit, .y_end  - .y_unit * (.i - 0.3),
                    ... .x_start + 2 * .x_unit, .y_end  - .y_unit * (.i - 0.3)
                Line width: legend.size[.i]
                Colour: legend.colour$[.i]
                Draw line: .x_start + 0.5 * .x_unit, .y_end  - .y_unit * (.i - 0.3),
                    ... .x_start + 2 * .x_unit, .y_end  - .y_unit * (.i - 0.3)
            elsif left$(legend.style$[.i], 1) =
                    ... "R" or left$(legend.style$[.i], 1) = "r"
                Line width: legend.size[.i]
                @modifyColVectr: legend.colour$[.i],
                    ... "drawLegendLayer.innerColour$",
                    ... "+ drawLegendLayer.innerChange"
                @modifyColVectr: legend.colour$[.i],
                    ... "drawLegendLayer.frameColour$",
                    ... "+ drawLegendLayer.frameChange"
                Colour: .innerColour$
                Paint rectangle: .innerColour$,
                    ... .x_start + 0.5 * .x_unit,
                    ... .x_start + 2 * .x_unit,
                    ... .y_end  - .y_unit * (.i - 0.3) + .y_unit / 3,
                    ... .y_end  - .y_unit * (.i - 0.3) - .y_unit / 3
                Line width: legend.size[.i]
                Colour: .frameColour$
                Draw rectangle:
                ... .x_start + 0.5 * .x_unit,
                ... .x_start + 2 * .x_unit,
                ... .y_end  - .y_unit * (.i - 0.3) + .y_unit / 3,
                ... .y_end  - .y_unit * (.i - 0.3) - .y_unit / 3
            elsif number(legend.style$[.i]) != undefined
                Line width: legend.size[.i]
                .lineType = number(left$(legend.style$[.i], 1))
                .scarcity = number(mid$(legend.style$[.i], 2, 1))
                .lineWidth = number(right$(legend.style$[.i], 1))
                if variableExists("bulletSize")
                    .obWidth = pi^0.5 * bulletSize / 1.1
                    .obHeight = pi^0.5 * bulletSize / 4
                else
                    .obWidth = legend.size[.i] * 2
                    .obHeight = legend.size[.i]
                endif

                @drawOblong:
                ... .x_start + 1.25 * .x_unit, .y_end  - .y_unit * (.i - 0.3),
                ... .obWidth, .obHeight,
                ... legend.colour$[.i], .lineType, .scarcity, .lineWidth
            else
                .temp = Create Table with column names: "table", 1,
                                                    ... "X Y Mrk Xs Ys"
                .xS = Horizontal mm to world coordinates: 0.2
                .yS = Vertical mm to world coordinates: 0.2
                Set numeric value: 1, "X" , .x_start + 1.25 * .x_unit
                Set numeric value: 1, "Y" , .y_end  - .y_unit * (.i - 0.3)
                Set numeric value: 1, "Xs" , .x_start + 1.25 * .x_unit + .xS
                Set numeric value: 1, "Ys" , .y_end  - .y_unit * (.i - 0.3) - .yS
                Set string value: 1, "Mrk", legend.style$[.i]
                Line width: 4
                Colour: legend.colour$[.i]
                Scatter plot (mark): "X", .xLeft, .xRight, "Y",
                    ... .yBottom, .yTop, 2, "no", "left$(legend.style$[.i], 1)"
                Remove
            endif
        endfor
    endif
    # purge legend.items
    legend.items = 0
endproc
