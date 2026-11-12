procedure doInputUI
    done = 0
    comment$ = ""
    for n to 4
        f'n'Col$ = replace$(f'n'Col$, "?", "", 0)
    endfor

    while ! done
        repFactor$ = replace$(repFactor$, "?", "", 0)
        beginPause: "Formants over time plot: input settings"
            comment: "NB: The interactive workflow is still being validated."
            comment:  comment$

            @addShared_UI_0: "Context", "Element"
            if isExample
                repFactor$ = "Rep"
                timeCol$ = "Element_t"
                f1Col$ = "F1"
                f2Col$ = "F2"
                f3Col$ = "F3"
                f4Col$ = ""
                inputUnits = 1
            endif

            comment: "GROUPING FACTORS (COLUMN HEADERS OR NUMBERS)"
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
            @selectTableID
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

procedure doOutputUI
    varRoot$ = "i"
    @hideObjs: "table",
           ... preferencesDirectory$ + "/plugin_AERoPlot/data/temp/", "hiddenTx"
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
        @selectTableID
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
