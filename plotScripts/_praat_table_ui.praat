procedure ui
    .done = 0
    .comment$ = ""

    while !.done
        textgrid_address_or_object_number$ = .gridID$
        sound_file_address_or_object_number$ = .soundID$

        beginPause: "Convert nested textgrid tiers to data table"
            # present object selection options only if the user has not already
            # selected appropriate objects from the objects window.
            if !overwriteVars.all
                comment: "TEXTGRID INFORMATION"
                sentence: "Textgrid address or object number", .gridID$
                sentence: "Sound file address or object number", .soundID$
            else
                # Set variables if user is using example files
                @check4ExampleObjs: .gridID$, .soundID$

            endif

            sentence: "New table name", .output$
            comment: "Enter tier names or numbers."
            sentence: "Base tier", .lowestTier$
            sentence: "Other tiers to process (separated by commas)",
            ... .otherTiers$
            boolean: "Base tier times only", .baseTierTimeOnly

            comment: "OPTIONAL DURATION"
            comment: "Adds a [tierName]_dur column (seconds) with the length of the"
            comment: "interval of this tier that contains each row. Leave blank for none."
            sentence: "Duration tier", .vowelDur$

            comment: "OPTIONAL FORMANT PROCESSING"
            optionMenu: "Formants to tabulate", .formants2tabulate
                option: "None"
                option: "F1"
                option: "F1 and F2"
                option: "F1 - F3"
                option: "F1 - F4"
                #option: "F1 - F5"
            optionMenu: "frequency scale", .scale
                option: "Hertz"
                option: "Bark"

            comment: "Formants are measured at each base tier point, or averaged"
            comment: "across each base tier interval."
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
            @selectTableID
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
    .baseTierTimeOnly = base_tier_times_only
    .output$ = replace_regex$(new_table_name$, "^.*", "\l&", 1)
    .output$ = replace_regex$(.output$, "^[0-9].*", "num_&", 1)
    .output$ = replace_regex$(.output$, "[^a-zA-Z0-9]", "_", 0)
    .soundID$ = sound_file_address_or_object_number$
    .formants2tabulate = formants_to_tabulate

    .formantTier$ = ""
    .vowelDur$ = duration_tier$

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
    '.a$' "  4. Enter the base tier name or number in the ""Base tier"" box."
    '.a$' "  5. List the other tiers in ""Other tiers to process"". Separate"
    '.a$' "     each tier name or number with a comma."
    '.a$' "Numeric tier names can be confused with tier numbers; use"
    '.a$' "descriptive names. Ambiguous entries must be resolved by renaming."
    '.a$' ""
    '.a$' "FORMANT ESTIMATION"
    '.a$' "------------------"
    '.a$' "Formants are estimated at times referenced by the base tier."
    '.a$' "If the base tier is an interval tier, estimates will represent"
    '.a$' "the mean of the defined formant estimates during that interval"
    '.a$' "(in the chosen frequency scale). If it is a point tier,"
    '.a$' "estimates will be taken at each marked point."
    '.a$' "For one row per point inside a longer segment, use the finest"
    '.a$' "point tier as the base tier."
    '.a$' ""
    '.a$' "DURATION"
    '.a$' "--------"
    '.a$' "To include a duration, enter an interval tier in ""Duration tier""."
    '.a$' "The table gets a column [tierName]_dur (in seconds) holding the"
    '.a$' "length of the interval of that tier containing each row."
    '.a$' ""
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
