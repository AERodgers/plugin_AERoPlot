# AERoPlot shared functions
# =========================
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
# These procedures are used by all AERoPlot features.
# They are specifically written to work only as part of the the aeroplot plugin
# and will likely cause problems you try to use them in other contexts.

# Table functions
procedure validateTable:  .tableID$, .headers$
    # Get target table
    if number(tableID$) == round(number(tableID$)) and number(tableID$) >= 0
        if !number(tableID$)
            table = Create formant table (Peterson & Barney 1952)
            title$ = "Peterson and Barney (1952)"
        else
            selectObject: number(tableID$)
            table = Copy: "temporaryTable"
        endif

    # NB: Script will crash if object does not exist. This is normal.

    elsif fileReadable (tableID$)
        if tableFormat = 1
            table = Read Table from tab-separated file: tableID$
        else
            table = Read Table from comma-separated file: tableID$
        endif
        Rename: "New"
    else
        exitScript: "Cannot find valid table."
    endif

    # Check column headers
    @csvLine2Array: .headers$, "validateTable.size", "validateTable.array$"
    .parityCheck = 1
    for .i to .size
        .flag[.i] = Get column index: .array$[.i]
        .parityCheck = .parityCheck * .flag[.i]
    endfor
    # Reject table without headers listed in input UI
    if ! .parityCheck
        removeObject: table
        .warning$ = newline$
        for .i to .size
            .flag$[1] = " DOESN'T EXIST."
            .flag$[2] = " exists."
            .warning$ =  .warning$ + newline$ + tab$ +
            ... "- """ + .array$[.i] + """ "  + .flag$[(.flag[.i] > 0) + 1]
        endfor
        exitScript: "Please check the grouping factors in the first menu " +
        ... "or the column headers in your table. Also, make sure you have " +
        ... " selected the correct ""Table format"" (CSV or tab-delimited)." +
        ... .warning$ + newline$
    endif
endproc

# Image Functions
procedure saveImage: .saveDir$, .savName$, .quality, .view$, .fontSize, .ref$

    if !(right$(.saveDir$, 1) = "/" or right$(.saveDir$, 1) = "\")
            ... and .saveDir$ != ""
        .saveDir$ += "/"
    endif

    if ! fileReadable(.saveDir$)
        createDirectory(.saveDir$)
    endif

    if ! rindex(.savName$, ".")
        .savName$ += ".png"
    elsif right$(.savName$, rindex(.savName$ , ".")) != "png"
       .savName$ = left$(.savName$, index(.savName$, ".")) + "png"
    endif

    beginPause: "Save?"
        comment: "Do you want to save this image?"
    myChoice = endPause: "No", "Yes", 2, 1

    if myChoice = 2
        # ensure save name is unique
        .newName$ = .savName$
        .nameExists = fileReadable(.saveDir$ + .savName$)
        .sfx = 1
        while .nameExists
            .newName$ =
                ... replace$(.savName$, ".png", "_", 1) + string$(.sfx) + ".png"
            .nameExists = fileReadable(.saveDir$ + .newName$)
            .sfx += 1
        endwhile


        Select inner viewport: '.view$'
        Font size: 2
        Colour: { 0.96, 0.96, 0.96 }
        @date
        @dec2hex: date.index, "saveImage.hexDate$"
        Viewport text: "Left", "Bottom", 0, "image ref. '.ref$'" +
        ... .hexDate$ +
        ... " Created using AeroPlot (github.com/AERodgers/AERoplot)"
        Font size: .fontSize
        Black
        if .quality
            Save as 300-dpi PNG file: .saveDir$ + .newName$
        else
            Save as 600-dpi PNG file: .saveDir$ + .newName$
        endif
    endif
endproc

# file and folder functions
procedure checkDirectoryStructure

    createDirectory: "../data/"
    createDirectory: "../data/archive"
    createDirectory: "../data/last"
    createDirectory: "../data/vars"

    if !fileReadable("../data/palettes/current.palette")
        createDirectory: "../data/palettes"
        .palName$[1] = "CBQualativeSet1"
        .js$[1] =
        ... "['rgb(228,26,28)','rgb(55,126,184)','rgb(77,175,74)'," +
        ... "'rgb(152,78,163)','rgb(255,127,0)','rgb(255,255,51)'," +
        ... "'rgb(166,86,40)','rgb(247,129,191)','rgb(153,153,153)']"
        .colrName$[1] = "Red,Blue,Green,Purple,Orange,Yellow,Brown,Pink,Grey"

        .palName$[2] = "CBQualDark2N3"
        .js$[2] = "['rgb(27,158,119)','rgb(217,95,2)','rgb(117,112,179)']"
        .colrName$[2] = "Mint,Orange,Lavender"

        .palName$[3] = "4ToneGreyscale"
        .js$[3] =
        ... "['rgb(50,50,50)','rgb(80,80,80)'," +
        ... "'rgb(110,110,110)','rgb(150,150,150)']"
        .colrName$[3] = "dark grey, medium grey, light grey, very light grey"


        .palName$[4] = "ZXSpectrum14"
        .js$[4] =
        ... "['rgb(0,0,0)','rgb(0,0,215)','rgb(215,0,0)'," +
        ... "'rgb(215,0,215)','rgb(0,215,0)','rgb(0,215,215)'," +
        ... "'rgb(215,215,0)','rgb(215,215,215)','rgb(0,0,255)'," +
        ... "'rgb(255,0,0)','rgb(255,0,255)','rgb(0,255,0)'," +
        ... "'rgb(0,255,255)','rgb(255,255,0)']"
        .colrName$[4] =
        ... "Black0,Blue0,Red0,Magenta0,Green0,Cyan0,Yellow0,White0," +
        ... "Blue1,Red1,Magenta1,Green1,Cyan1,Yellow1"

        .palName$[5] = "current"
        .js$[5] = .js$[1]
        .colrName$[5] = .colrName$[1]

        for .i to 5
            .address$ = "../data/palettes/" + .palName$[.i] + ".palette"
            writeFileLine: .address$, .js$[.i] + newline$ + .colrName$[.i]
        endfor
    endif
endproc

# UI and variable Functions
procedure addShared_UI_1
    if inputUnits = 1
        optionMenu: "Output units", outputUnits
            option: "Hertz"
            option: "Hertz (displayed re bark scale)"
            option: "Hertz (displayed logarithmically)"
            option: "kHz"
            option: "kHz (displayed re bark scale)"
            option: "kHz (displayed logarithmically)"
    else
        output_units = 7
    endif
endproc

procedure addShared_UI_2
    boolean: "Show legend", showLegend
    optionMenu: "Base font size", (fontM - 8) / 2
        option: "8"
        option: "10"
        option: "12"
        option: "14"
        option: "16"
        option: "18"

    comment: "Image saving"
    boolean: "Very high quality", quality
    sentence: "Save directory", saveDirectory$
    sentence: "Save name", saveName$

    comment: "Extra colour management options"
    boolean: "Add or change colour scheme", changeAddColSch

    optionMenu: "Update order of current colour scheme", sorting
        option: "No change"
        option: "Re-sort by brightness"
        option: "Re-sort by maximal perceptual difference"
        option: "Manually re-sort"
        option: "Match levels to colour in next plot only"
endproc

procedure processShared_UIs
    # process Shared_UI_1
    outputUnits = output_units
    # Logical operators are used here in place of if-else statements.
    useKHz = inputUnits == 1 and  outputUnits > 3
    doHz2Bark = abs((outputUnits * 2 - 7) / 3) == 1
    doHz2Log = abs((outputUnits * 2 - 7) / 3) == 1
    outScaleUnit =
        ... (round((outputUnits - 1) / 3) == (outputUnits - 1) / 3) +
        ... (round((outputUnits + 1) / 3) == (outputUnits + 1) / 3) * 2 +
        ... (round(outputUnits / 3) == (outputUnits / 3)) * 3
    # outScaleUnit is the 6th argument to the procedure @getOutputScales,
    # where 1 -> output is linear, 2-> output is (k)Hz plotted in Bark scale,
    # 3 -> output is (k)Hz plotted logarithmically.
    # process Shared_UI_2
    showLegend = show_legend
    fontS = 6 + base_font_size * 2
    fontM = 8 + base_font_size * 2
    fontL = 12 + base_font_size * 2
    sorting = update_order_of_current_colour_scheme
    sortByBrightness = sorting = 2
    maxColDiff = sorting = 3
    makeNewColSeq = sorting = 4
    altColrMatch = sorting = 5
    sorting = (sorting <= 2) * sorting + (sorting > 2)
    saveDirectory$ = save_directory$
    saveName$ = save_name$
    quality = very_high_quality
    changeAddColSch = add_or_change_colour_scheme
endproc

procedure appendSharedVars: .address$
    saveDirectory$ = homeDirectory$ + "/Desktop/AERoPlot_Images"
    fontM = 14
    appendFileLine: .address$, "fontM", tab$, fontM
    appendFileLine: .address$, "fontS", tab$, fontM - 2
    appendFileLine: .address$, "fontL", tab$, fontM + 4
    appendFileLine: .address$, "bulletSize", tab$, 22
    appendFileLine: .address$, "shading", tab$, 0.15
    appendFileLine: .address$, "colrAdj#", tab$, "{0.299,0.587,0.114}"
    appendFileLine: .address$, "tableFormat", tab$, 1
    appendFileLine: .address$, "colrPalFile$", tab$,
    ... "current.palette"
    appendFileLine: .address$, "legBlockTolerance", tab$, 0
    appendFileLine: .address$, "bufferZone", tab$, 2
    appendFileLine: .address$, "showLegend", tab$, 1
    appendFileLine: .address$, "quality", tab$, 0
    appendFileLine: .address$, "saveDirectory$", tab$, saveDirectory$
    appendFileLine: .address$, "changeAddColSch", tab$, 0
    appendFileLine: .address$, "sorting", tab$, 1
    appendFileLine: .address$, "lightLine$", tab$, "{0.8, 0.8, 0.8}"
    appendFileLine: .address$, "darkLine$", tab$, "{0.2, 0.2, 0.2}"
endproc

procedure getFreqAxisNames
    outputUnits$[1] = "Hertz"
    outputUnits$[2] = "Hertz (bark)"
    outputUnits$[3] = "Hertz (logarithmic)"
    outputUnits$[4] = "kHz"
    outputUnits$[5] = "kHz (bark)"
    outputUnits$[6] = "kHz (logarithmic)"
    outputUnits$[7] = "Bark scale"
endproc
