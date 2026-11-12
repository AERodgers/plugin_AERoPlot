procedure doInputUI
    done = 0
    comment$ = ""
    while ! done
        beginPause: "F1-F2 plotter: input settings"
        comment: comment$

            @addShared_UI_0: "Context", "Element"

            comment: "GROUPING FACTORS (COLUMN HEADERS OR NUMBERS)"
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

    @hideObjs: "table", preferencesDirectory$ +
    ... "/plugin_AERoPlot/data/temp/", "hiddenTx"
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
