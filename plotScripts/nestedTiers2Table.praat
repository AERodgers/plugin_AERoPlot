# Generate Data Table from Textgtrid with Nested Tiers
# ===================================================================
# A data extraction tool for general use and for the AERoplot plugin.
#
# Written for Praat 6.0.40 or later
#
# script by Antoin Eoin Rodgers
# Phonetics and speech Laboratory, Trinity College Dublin
# July 26th, 2020
#
# email:     rodgeran@tcd.ie
# twitter:   @phonetic_antoin
# github:    github.com/AERodgers

@checkPraatVersion
@objsSelected: "Sound,TextGrid", "ui.soundID$,ui.gridID$"
@purgeDirFiles: "../data/temp"
@main

procedure main
    .curVersion$ = "1.0.0.0"
    @defineVars

    @ui
    @getObject: ui.gridID$, "textGrid", "main"
    @getObject: ui.soundID$, "sound", "main"

    @tiers2Table:
    ... .textGrid,
    ... "'ui.lowestTier$','ui.otherTiers$'",
    ...  ui.output$

    # decide time columns for
    if ui.formants2tabulate
        if tiers2Table.isIntTier[1]
            .tColTiers$ = "'ui.lowestTier$'_tmin,'ui.lowestTier$'_tmax"
        else
            .tColTiers$ = "'ui.lowestTier$'_t"
        endif
        @formantsSought: .sound, 'ui.output$', .tColTiers$,
        ... ui.timeStep, ui.maxNumFormants, ui.maxFormantHz, ui.numFormants, ui.windowLen, ui.preEmph,
        ... .scale$[ui.scale]
    endif


    selectObject: .textGrid
    plusObject: .sound
    Remove

    @writeVars: "../data/vars/", "tier2Table.var"
endproc

## UI-RELATED PROCEDURES
procedure ui
    .done = 0
    .comment$ = ""

    while !.done
        beginPause: "Convert nested textgrid tiers to data table"

            comment: "TEXTGRID INFORMATION"

            sentence: "Textgrid address or object number", .gridID$
            sentence: "Sound file address or object number", .soundID$
            sentence: "New table name", .output$

            sentence: "Base tier", .lowestTier$
            sentence: "Other tiers to process (separated by commas)",
            ... .otherTiers$

            comment: "OPTIONAL FORMANT PROCESSING"
            optionMenu: "Formants to tabulate", .formants2tabulate
                option: "None"
                option: "F1"
                option: "F1 and F2"
                option: "F1 - F3"
                option: "F1 - F4"
                #option: "F1 - F5"

            comment: "Output scale"
            optionMenu: "frequency scale", .scale
            option: "Hertz"
            option: "Bark"

            comment: "Parameters for ""To Formant (Burg)..."""
            real: "Time step (s)", .timeStep
            natural: "Maximum formant (Hz)", .maxFormantHz
            positive: "Number of formants (for formant estimation)",
            ... .numFormants
            positive: "Window length (s)", .windowLen
            positive: "Pre emphasis from (Hz)", .preEmph


        comment:  .comment$
        .myChoice = endPause: "Exit", "Instructions", "Convert to Table", 3, 1
        # respond to .myChoice
        if .myChoice = 1
            exit
        endif

        .done =
        ... !(
        ...     textgrid_address_or_object_number$ == "" or
        ...     base_tier$ == "" or
        ...     new_table_name$ == ""
        ... ) and
        ... (
        ...     (sound_file_address_or_object_number$ != "") *
        ...     (formants_to_tabulate > 1) +
        ...     (formants_to_tabulate == 1)
        ... ) and
        ... .myChoice != 2

       if .myChoice == 2
           @instructions
       endif
       .comment$= "Ensure ALL necessary parts of the form are complete"

    endwhile

    # convert input variable to manageable form
    .gridID$ = textgrid_address_or_object_number$
    .lowestTier$ = base_tier$
    .otherTiers$ = other_tiers_to_process$
    .output$ = replace_regex$(new_table_name$, "^.*", "\l&", 1)
    .output$ = replace_regex$(.output$, "^[0-9].*", "num_&", 1)
    .soundID$ = sound_file_address_or_object_number$
    .formants2tabulate = formants_to_tabulate
    .maxNumFormants = .formants2tabulate - 1
    .scale = frequency_scale

    .timeStep = time_step
    .maxFormantHz = maximum_formant
    .numFormants = number_of_formants
    .windowLen = window_length
    .preEmph = pre_emphasis_from
endproc

procedure instructions
    .a$ = "appendInfoLine:"
    writeInfoLine: "Converting nested textgrid tiers to data table"
    '.a$' "=============================================="
    '.a$' "This script converts an annotated textgrid to a data table"
    '.a$' "appropriate for further processing and analysis. Only point and"
    '.a$' "interval tiers containing text will be used to create the table."
    '.a$' ""
    '.a$' "BASICS"
    '.a$' "------"
    '.a$' ""
    '.a$' "  1. Enter the object number of the textgrid or a full file address"
    '.a$' "     (including folder info and the file extension "".textGrid"")"
    '.a$' "     into the box ""Textgrid address or object number""."
    '.a$' "  2. ""Sound file address or object number"" is the same for the"
    '.a$' "     sound file. (NOTE: if you do not want to estimate formant"
    '.a$' "     values, you can leave this blank.)"
    '.a$' "  3. Enter the name the output table in ""New table name""."
    '.a$' ""
    '.a$' "HOW TO CHOOSE THE BASE TIER AND OTHER TIERS"
    '.a$' "-------------------------------------------"
    '.a$' "The script assumes that one tier indicates time points or"
    '.a$' "regions in the sound where acoustic measurements will be taken."
    '.a$' "This tier is called the ""Base tier""."
    '.a$' ""
    '.a$' "It also assumes that other tiers include data relevant to the"
    '.a$' "base tier (e.g., phoneme name, repetition number, or speaker"
    '.a$' "ID). Therefore, to add data from these tiers to the table correctly,"
    '.a$' "all points or intervals in the base tier must be aligned with or"
    '.a$' "inside those tiers. In other word, the base tier must be nested"
    '.a$' "inside all the other tiers."
    '.a$' ""
    '.a$' "Therefore, to enter the tier information correctly:"
    '.a$' ""
    '.a$' "  4. Enter the base tier name in the ""Base tier"" box."
    '.a$' "  5. List the other tiers in ""Other tiers to process"". Separate"
    '.a$' "     each tier with a comma."
    '.a$' ""
    '.a$' "FORMANT ESTIMATION"
    '.a$' "------------------"
    '.a$' "Formants are estimated at times referenced by the base tier."
    '.a$' "If the base tier is an interval tier, estimates will represent"
    '.a$' "mean formant estimates during that interval. If it is a point tier,"
    '.a$' "estimates will be taking at each marked point."

    '.a$' "To estimate formant values:"
    '.a$' "  6. Input the speech waveform and analysis parameter data."
    '.a$' ""
    '.a$' "The script uses Praat's ""To Formant (Burg)..."" function."
    '.a$' "For more information on this, please visit:"
    '.a$' ""
    '.a$' """www.fon.hum.uva.nl/praat/manual/Sound__To_Formant__burg____.html"""
    '.a$' ""
    '.a$' "NOTE"
    '.a$' "The UI here sets ""Maximum F5 (Hz)"" to 5000 Hz by default,"
    '.a$' "which is appropriate for the male voice in the sample data."
    '.a$' "However, by default in Praat, ""To Formant (Burg)..."" sets"
    '.a$' """Maximum formant (Hz)"" to 5500 Hz, and ""Number of"
    '.a$' "formants"" to 5. These are the default settings for a female voice."
    '.a$' ""
    '.a$' "This script always uses ""Maximum formant (Hz)"" to estimate"
    '.a$' "five formants. Therefore the ""Maximum formant (hz)"" always"
    '.a$' "refers to the maximum peak of F5, even if the script does not"
    '.a$' "extract data up to F5."
    '.a$' ""
    '.a$' "OUTPUT TABLE"
    '.a$' "------------"
    '.a$' "The output table has as many rows as there are entries in the base"
    '.a$' "tier."
    '.a$' "For each tier listed in ""Other tiers to process"", there is a"
    '.a$' "column called [tierName]. For each base tier row, the table records"
    '.a$' "the text in every other tier at that time point."
    '.a$' ""
    '.a$' "Where appropriate, the table also includes time data for each tier"
    '.a$' ""
    '.a$' "For each point tier, there will be a column named ""[tierName]_t"""
    '.a$' ""
    '.a$' "For each interval tier, there will be a column named"
    '.a$' """[tierName_]tmin"" and a column named ""[tierName]_tmin]""."
    '.a$' ""
    '.a$' "If (mean) formant peaks frequencies have been estimates, these will"
    '.a$' "be listed in columns named ""F1"", ""F1"", etc."
endproc

## OBJECT PROCESSING
procedure getObject: .objID$, .type$, .sourceProc$
    if fileReadable (.objID$)
        '.sourceProc$'.'.type$' = Read from file: .objID$
    elsif number(.objID$) == round(number(.objID$))
        selectObject: number(.objID$)
        '.sourceProc$'.'.type$' = Copy: "temporaryTable"
    else
        exitScript: "Cannot find valid '.type$':" + newline$ +
        ... .objID$ + newline$
    endif
endproc

## CONVERSION OF NESTED TEXTGRID TO TABLE
procedure tiers2Table:
    ... .textGrid,
    ... .hierarchySSL$,
    ... .output$
    .output$ = replace$(.output$, "$", "", 1)

    # Get array showing order in which to process tiers
    @csvLine2Array: .hierarchySSL$,
    ... "tiers2Table.hierArray_N",
    ... "tiers2Table.hierArray$"

    selectObject: .textGrid
    .numTiers = Get number of tiers

    for .curTier to .numTiers
        # get Tier info
        .tierName$[.curTier] = Get tier name: .curTier
        .curIsIntTier = Is interval tier: .curTier
        .tierCode[.tierName$[.curTier]] = .curTier
        for .i to .hierArray_N
            if .tierName$[.curTier] = .hierArray$[.i]
                .tier[.i] = .curTier
                .isIntTier[.i] = .curIsIntTier
            endif
        endfor
    endfor

    # Create database table with innermost factor in tier hierarchy
    selectObject: .textGrid

    .gridTable = Down to Table: "no", 3, "yes", "no"
    '.output$' = Extract rows where column (text):
        ... "tier",
        ... "is equal to",
        ... .hierArray$[1]
    Rename: .output$
    Remove column: "tier"

    if .isIntTier[1]
        Set column label (label): "tmin", "'.hierArray$[1]'_tmin"
        Set column label (label): "tmax", "'.hierArray$[1]'_tmax"
        .tempIndex = Get column index: "'.hierArray$[1]'_tmax"
        Insert column: .tempIndex, "temp"
        Formula: "temp", "self[""'.hierArray$[1]'_tmin""]"
        Remove column: "'.hierArray$[1]'_tmin"
        Set column label (label): "temp", "'.hierArray$[1]'_tmin"
        .main_tmin$ = "'.hierArray$[1]'_tmin"
        .main_tmax$ = "'.hierArray$[1]'_tmax"
        .newColSt = -1
    else
        Remove column: "tmin"
        Set column label (label): "tmax", "'.hierArray$[1]'_t"
        .main_tmin$ = "'.hierArray$[1]'_t"
        .main_tmax$ = "'.hierArray$[1]'_t"
        .newColSt = 0
    endif
    Set column label (label): "text", .hierArray$[1]

    # create subtable for each tier in hierarchy
    for .i from 2 to .hierArray_N
        .curFactor$ = .hierArray$[.i]

        selectObject: .gridTable
        .tempTable = Extract rows where column (text):
            ... "tier",
            ... "is equal to",
            ... .curFactor$
        Remove column: "tier"

        .curNumRows = Get number of rows
        selectObject: '.output$'
       .curNumCols = Get number of columns
        Insert column: .curNumCols + .newColSt - 1, .curFactor$
        Insert column: .curNumCols + .newColSt, "'.curFactor$'_tmin"
        Insert column: .curNumCols + .newColSt + 1, "'.curFactor$'_tmax"
        for .j to .curNumRows
            selectObject: .tempTable
            .curTmin = Get value: .j, "tmin"
            .curText$ = Get value: .j, "text"
            .curTmax = Get value: .j, "tmax"

            selectObject: '.output$'
            Formula:
            ... .curFactor$,
            ... "if " +
            ...     "self[.main_tmin$] >= .curTmin  and " +
            ...     "self[.main_tmax$] <= .curTmax " +
            ... "then " +
            ...     ".curText$ " +
            ... "else " +
            ...     "self$ " +
            ... "endif"


            Formula:
            ... "'.curFactor$'_tmax",
            ... "if " +
            ...     "self[.main_tmin$] >= .curTmin  and " +
            ...     "self[.main_tmax$] <= .curTmax " +
            ... "then " +
            ...     "self[.main_tmax$] " +
            ... "else " +
            ...     "self$ " +
            ... "endif"


            Formula:
            ... "'.curFactor$'_tmin",
            ... "if " +
            ...     "self[.main_tmin$] >= .curTmin  and " +
            ...     "self[.main_tmax$] <= .curTmax " +
            ... "then " +
            ...     "self[.main_tmin$] " +
            ... "else " +
            ...     "self$ " +
            ... "endif"
        endfor

        selectObject: '.output$'
        if .curNumRows = 1
            Remove column: "'.curFactor$'_tmin"
            Remove column: "'.curFactor$'_tmax"
        elsif .isIntTier[.i]
            Insert column: .curNumCols + .newColSt + 1, "temp"
            Formula: "temp", "self[""'.curFactor$'_tmin""]"
            Remove column: "'.curFactor$'_tmin"
            Set column label (label): "temp", "'.curFactor$'_tmin"
        else
            Remove column: "'.curFactor$'_tmin"
            Set column label (label): "'.curFactor$'_tmax", "'.curFactor$'_t"
        endif
        removeObject: .tempTable
    endfor

    removeObject: .gridTable
endproc

## FORMANT ESTIMATION
procedure formantsSought:
    ... .sound, .table, .timeCols$,
    ... .timeStep, .maxFormantsSought, .maxFormantHz, .numFormants, .windowLen, .preEmph,
    ... .scale$

    if .timeStep = 0
        .timeStep = .windowLen * 0.25
    endif

    @csvLine2Array: .timeCols$, "formantsSought.numCols", "formantsSought.colArray$"
    .firstT$ = .colArray$[1]
    if .numCols = 1
        .lastT$ = .firstT$
    else
        .lastT$ = .colArray$[2]
    endif

    selectObject: .sound
    noprogress To Formant (burg):
    ... .timeStep,
    ... .numFormants,
    ... .maxFormantHz,
    ... .windowLen,
    ... .preEmph
    .formantObj = selected()

    selectObject: .table
    for .f to .maxFormantsSought
        Append column: "F'.f'"
    endfor

    .numRows = Get number of rows
    for .curRow to .numRows
        selectObject: .table
        .startTP = Get value: .curRow, .firstT$
        .endTP = Get value: .curRow, .lastT$

        for .f to .maxFormantsSought
            selectObject: .formantObj

            # Formant extraction must work for both point and interval tiers.
            .curTotTPs = 0
            .curTotF = 0
            .curTP = .startTP
            .keepon = 100
            while .curTP <= .endTP and .keepon
                .curF = Get value at time: .f, .curTP, .scale$, "Linear"
                if .curF != undefined
                    .curTotF += .curF
                    .curTotTPs += 1
                endif
                .curTP += .timeStep
                .keepon -= 1
            endwhile
            if .curF != undefined
                .meanF = .curTotF / .curTotTPs
            else
                .meanF = undefined
            endif

            selectObject: .table
            if .scale$ = "Bark"
                .decPlaces  = 3
            else
                .decPlaces  = 0
            endif
            Set string value: .curRow, "F'.f'", fixed$(.meanF, .decPlaces)
        endfor
    endfor

    removeObject:  .formantObj
endproc

## VARIABLE / PROCEDURE INTITIALISATION
procedure defineVars
    createDirectory: "../data/"
    createDirectory: "../data/vars"

    main.scale$[1] = "Hertz"
    main.scale$[2] = "Bark"
    if !fileReadable("../data/vars/tier2Table.var")
        @initialiseVars: "../data/vars/tier2Table.var"
    endif
    @readVars: "../data/vars/", "tier2Table.var"
    if main.version$ != main.curVersion$
        @initialiseVars: "../data/vars/tier2Table.var"
    endif
    @readVars: "../data/vars/", "tier2Table.var"
    @overrideObjIDs
endproc

procedure initialiseVars: .address$
    writeFileLine: .address$, "variable", tab$, "value"
    appendFileLine: .address$, "main.version$", tab$, main.curVersion$
    appendFileLine: .address$, "ui.gridID$", tab$,
    ... "../example/AER_NI_I.textgrid"
    appendFileLine: .address$, "ui.lowestTier$", tab$, "Element"
    appendFileLine: .address$, "ui.otherTiers$", tab$,
    ... "Speaker,Sex,Type,Context,Rep,IPA,Segment"
    appendFileLine: .address$, "ui.output$", tab$, "ni_vowels"
    appendFileLine: .address$, "ui.soundID$", tab$, "../example/AER_NI_I.wav"
    appendFileLine: .address$, "ui.formants2tabulate", tab$, 4
    appendFileLine: .address$, "ui.numFormants", tab$, 5
    appendFileLine: .address$, "ui.scale", tab$, 1
    appendFileLine: .address$, "ui.timeStep", tab$, 0
    appendFileLine: .address$, "ui.maxFormantHz", tab$, 5000
    appendFileLine: .address$, "ui.windowLen", tab$, 0.025
    appendFileLine: .address$, "ui.preEmph", tab$, 50
endproc

include _genFnBank.praat
include _aeroplotFns.praat
