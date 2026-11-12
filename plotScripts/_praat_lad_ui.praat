procedure doInputUI
    for n to 4
        f'n'Col$ = replace$(f'n'Col$, "?", "", 0)
    endfor
    done = 0
    comment$ = ""
    while ! done
        beginPause: "Ladefoged-style Formant Plot: input settings"
            comment:  comment$

            @addShared_UI_0: "Element", "Context"

            comment: "GROUPING FACTORS (COLUMN HEADERS)"
            comment: "Leave ""Comparison factor"" blank if you don't need to " +
            ... "compare the same sound under different conditions."
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
            @selectTableID
            exit
        endif

        # error handling
        done =
        ... !(
        ... (comparison_factor$ == sequencing_factor$) or
        ...     (
        ...     object_number_or_file_path$ = "" or
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

procedure doOutputUI
    @hideObjs: "table",
    ... preferencesDirectory$ + "/plugin_AERoPlot/data/temp/",
    ... "hiddenTx"

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
        if oLevels > 1
            boolean: "Distribute ALL factors along the X axis", staggerO
        else
            distribute_ALL_factors_along_the_X_axis = 0
        endif
        boolean: "Show boxplots", showIQR
        boolean: "Show arrows", drawArrows
        boolean: "show formants in legend", legendHasFormants

        @addShared_UI_3
    myChoice = endPause: "Exit", "Continue", 2, 1
    if myChoice = 1
        @selectTableID
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
    if showAves = 1
        ave$ = "mean"
    elsif showAves = 2
        ave$ = "med"
    endif
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
