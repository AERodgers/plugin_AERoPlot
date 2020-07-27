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
#
# v.1.3.0.1

# Table functions
procedure validateTable:  .tableID$, .headers$
    # Get target table
    if number(tableID$) == round(number(tableID$)) and number(tableID$) >= 0
        if !number(tableID$)
            table = Create formant table (Peterson & Barney 1952)
            Formula (column range):
            ... "Type", "Sex",
            ... "if self$ = ""f"" or self$ = ""w"" " +
            ... "then ""female"" " +
            ... "else self$ " +
            ... "endif"
            Formula (column range):
            ... "Type", "Sex",
            ... "if self$ = ""m"" " +
            ... "then ""male"" " +
            ... "else self$ " +
            ... "endif"
            Formula:
            ... "Type",
            ... "if self$ = ""c"" " +
            ... "then ""child"" " +
            ... "else self$ " +
            ... "endif"

            title$ = "Peterson and Barney (1952)"

            if !pbInfo
                il$ = "appendInfoLine:"
                nl$ = "newline$"

                writeInfo: ""
                'il$' "Note on table of vowels of General American English "
                'il$' "--------------------------------------------------- "
                'il$' 'nl$', "These data are available natively in Praat. ",
                 ... "However, levels of the "
                'il$' "factors ""Type"" and ""Sex"" have been make more ",
                ... "explicit filtering:"
                'il$' "'tab$'1. ""Type"" <- ""child"", ""female"", ""male""."
                'il$' "'tab$'2. ""Sex""  <- ""female"" and ""male"".", 'nl$'
                'il$' "Reference", 'nl$', "---------"
                'il$' "Peterson, G. E., & Barney, H. L. (1952)." +
                ... """Control Methods Used in a "
                'il$' tab$, "Study of the Vowels."" Journal of the Acoustical ",
                ... "Society of "
                'il$' tab$, "America, 24(2), 175–184. ",
                ... "https://doi.org/10.1121/1.1906875"

                pbInfo = 1
            endif
        else
            selectObject: number(tableID$)
            table = Copy: "temporaryTable"
        endif

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
procedure saveImage: .dir$, .savName$, .quality, .view$, .fontSize, .ref$

    if !(right$(.dir$) = "/" or right$(.dir$) = "\")
            ... and .dir$ != ""
        .dir$ = .dir$ +  "/"
    endif


    if ! rindex(.savName$, ".")
        .savName$ += ".png"
    elsif right$(.savName$, rindex(.savName$ , ".")) != "png"
       .savName$ = left$(.savName$, index(.savName$, ".")) + "png"
    endif

    beginPause: "Save?"
        comment: "What do you want to do?"
    myChoice =
    ... endPause:
    ... "Exit",
    ... "Save & Exit",
    ... "Continue",
    ... "Save & cont.",
    ... 4, 1
    if myChoice = 1
        exit
    endif

    if myChoice / 2 = round(myChoice / 2)
        # ensure save name is unique
        .newName$ = .savName$
        .nameExists = fileReadable(.dir$ + .savName$)
        .sfx = 1
        while .nameExists
            .newName$ =
                ... replace$(.savName$, ".png", "_", 1) + string$(.sfx) + ".png"
            .nameExists = fileReadable(.dir$ + .newName$)
            .sfx += 1
        endwhile

        Select inner viewport: '.view$'
        Font size: 2
        Colour: { 0.96, 0.96, 0.96 }
        @date
        @dec2hex: date.index, "saveImage.hexDate$"
        nowarn Viewport text: "Left", "Bottom", 0,
        ... "image ref. #'.ref$''.hexDate$' " +
        ... "Created using AeroPlot (github.com/AERodgers/AERoplot)"
        Font size: .fontSize
        Black

        if ! fileReadable(.dir$)
            createDirectory(.dir$)
        endif

        if .quality
            Save as 300-dpi PNG file: .dir$ + .newName$
        else
            Save as 600-dpi PNG file: .dir$ + .newName$
        endif
    endif
    if myChoice = 2
        exit
    endif
endproc

procedure getGenAxisVars
    outputUnits$[1] = "Hertz"
    outputUnits$[2] = "Hertz (bark)"
    outputUnits$[3] = "Hertz (logarithmic)"
    outputUnits$[4] = "kHz"
    outputUnits$[5] = "kHz (bark)"
    outputUnits$[6] = "kHz (logarithmic)"
    outputUnits$[7] = "Bark scale"
    axisLine[1] = 2
    axisLine[2] = 2
endproc

# file and folder functions
procedure checkDirectoryStructure

    createDirectory: "../data/"
    createDirectory: "../data/archive"
    createDirectory: "../data/last"
    createDirectory: "../data/vars"
    createDirectory: "../data/temp"


    if !fileReadable("../data/palettes/current.palette")
        createDirectory: "../data/palettes"
        .palName$[1] = "Adjusted_CB_Qualitative_Set1"
        .js$[1] =
        ... "['rgb(55,126,184)','rgb(255,127,0)','rgb(228,26,28)'," +
        ... "'rgb(152,78,163)','rgb(77,175,74)','rgb(153,153,153)'," +
        ... "'rgb(114,13,14)','rgb(50,50,50)',"+
        ... "'rgb(247,129,191)','rgb(166,86,40)']"

        .colrName$[1] =
        ... "Blue,Orange,Red,Purple,Green,Grey,Maroon,Dark Grey,Pink,Brown"

        .palName$[2] = "Colour_Blind_Friendly_CB_Qualitative_Dark2_3_colours"
        .js$[2] = "['rgb(27,158,119)','rgb(217,95,2)','rgb(117,112,179)']"
        .colrName$[2] = "Mint,Orange,Lavender"

        .palName$[3] = "Greyscale_4_shades"
        .js$[3] =
        ...  "['rgb(16,16,16)','rgb(79,79,79)'," +
        ... "'rgb(142,142,142)','rgb(206,206,206)']"
        .colrName$[3] = "dark grey,medium grey,light grey,very light grey"


        .palName$[4] = "ZXSpectrum_14_colours"
        .js$[4] =
        ... "['rgb(0,0,0)','rgb(0,0,215)','rgb(215,0,0)'," +
        ... "'rgb(215,0,215)','rgb(0,215,0)','rgb(0,215,215)'," +
        ... "'rgb(215,215,0)','rgb(215,215,215)','rgb(0,0,255)'," +
        ... "'rgb(255,0,0)','rgb(255,0,255)','rgb(0,255,0)'," +
        ... "'rgb(0,255,255)','rgb(255,255,0)']"
        .colrName$[4] =
        ... "Black0,Blue0,Red0,Magenta0,Green0,Cyan0,Yellow0,White0," +
        ... "Blue1,Red1,Magenta1,Green1,Cyan1,Yellow1"


        .palName$[5] = "Praat_Native_Colours"
        .js$[5] = "[" +
        ... "'rgb(220.575,8.67,6.63)','rgb(0,127.5,17.595)'," +
        ... "'rgb(0,0,211.14)','rgb(2.295,170.595,234.09)'," +
        ... "'rgb(241.995,8.415,132.345)','rgb(250.92,242.505,5.1)'," +
        ... "'rgb(127.5,0,0)','rgb(0,255,0)'," +
        ... "'rgb(0,0,127.5)','rgb(0,127.5,127.5)'," +
        ... "'rgb(127.5,0,127.5)','rgb(127.5,127.5,0)'," +
        ... "'rgb(255,191.25,191.25)','rgb(191.25,191.25,191.25)'," +
        ... "'rgb(127.5,127.5,127.5)','rgb(0,0,0)'" +
        ... "]"
        .colrName$[5]=
        ... "Red,Green,Blue,Cyan,Magenta,Yellow,Maroon,Lime," +
        ... "Navy,Teal,Purple,Olive,Pink,Silver,Grey, Black,"

        .palName$[6] = "current"
        .js$[6] = .js$[1]
        .colrName$[6] = .colrName$[1]

        for .i to 6
            .address$ = "../data/palettes/" + .palName$[.i] + ".palette"
            writeFileLine: .address$, .js$[.i] + newline$ + .colrName$[.i]
        endfor
    endif
endproc


# UI and variable Functions
procedure addShared_UI_0
    comment: "TABLE / FILE INFORMATION"
    sentence: "Table address or object number", tableID$
    optionMenu: "Table format", tableFormat
        option: "tab-delimited file"
        option: "CSV file"
    choice:  "Each plot will use:", 1
        option: "A different table."
        option: "The same table."
        #option: "The same table and sequencing factor"
endproc

procedure processShared_UI_0
    tableID$ =  table_address_or_object_number$
    tableFormat = table_format
    plotUses = each_plot_will_use
endproc

procedure addShared_UI_1
    if !pbInfo
        comment: "To use sample data set, " +
        ... " set ""object number"" to 0, and use factors ""IPA"", ""Sex""" +
        ... ", and ""Type""."

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

procedure addShared_UI_3
    comment: "IMAGE SAVING"
    #boolean: "Very high quality", quality
    sentence: "Save directory", saveDir$
    sentence: "Save name", saveName$

    comment: "COLOUR MANAGEMENT"
    boolean: "Add or change colour scheme", changeAddColSch

    optionMenu: "Modify colour scheme", sorting
        option: "No change"
        option: "Re-sort by brightness"
        option: "Re-sort by maximal perceptual difference"
        option: "Re-sort manually"
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
    sorting = modify_colour_scheme
    sortByBrightness = sorting = 2
    maxColDiff = sorting = 3
    makeNewColSeq = sorting = 4
    altColrMatch = sorting = 5
    sorting = (sorting <= 2) * sorting + (sorting > 2)
    saveDir$ = save_directory$
    saveName$ = save_name$
    #quality = very_high_quality
    changeAddColSch = add_or_change_colour_scheme
endproc

procedure appendSharedVars: .address$
    saveDir$ = homeDirectory$ + "/Desktop/AERoPlot_Images"
    fontM = 14
    appendFileLine: .address$, "fontS", tab$, fontM - 2
    appendFileLine: .address$, "fontM", tab$, fontM
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
    appendFileLine: .address$, "saveDir$", tab$, saveDir$
    appendFileLine: .address$, "changeAddColSch", tab$, 0
    appendFileLine: .address$, "sorting", tab$, 1
    appendFileLine: .address$, "lightLine$", tab$, "{0.8, 0.8, 0.8}"
    appendFileLine: .address$, "darkLine$", tab$, "{0.2, 0.2, 0.2}"
    appendFileLine: .address$, "pbInfo", tab$, 0
endproc
