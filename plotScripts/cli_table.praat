form AERoPlot: Create Table from nested TextGrid tiers (command line)
    comment All values are required positionally when run with Praat --run.
    comment Use "none" for the Sound file if no formants are wanted.
    sentence Textgrid_file
    sentence Sound_file none
    sentence Output_table_file
    boolean Overwrite_existing_file 0
    sentence Base_tier
    sentence Other_tiers (separated by commas)
    boolean Base_tier_times_only 1
    optionmenu Formants_to_tabulate 1
        option None
        option F1
        option F1 and F2
        option F1 - F3
        option F1 - F4
    sentence Duration_tier none
    optionmenu Frequency_scale 1
        option Hertz
        option Bark
    real Time_step_(s) 0
    natural Maximum_formant_(Hz) 5000
    positive Number_of_formants 5
    positive Window_length_(s) 0.025
    positive Pre_emphasis_from_(Hz) 50
endform

# Command-line entry point. It only collects settings; the shared Table
# procedures in nestedTiers2Table.praat do the work, exactly as for the dialogs.
aeroPrototypeInclude = 1
aeroNonInteractive = 1
cli_gridFile$ = textgrid_file$
cli_soundFile$ = sound_file$
cli_outputFile$ = output_table_file$
cli_overwrite = overwrite_existing_file
cli_baseTier$ = base_tier$
cli_otherTiers$ = other_tiers$
cli_baseTierTimeOnly = base_tier_times_only
cli_formants = formants_to_tabulate
cli_vowelDurTier$ = duration_tier$
cli_scale = frequency_scale
cli_timeStep = time_step
cli_maxFormantHz = maximum_formant
cli_numFormants = number_of_formants
cli_windowLen = window_length
cli_preEmph = pre_emphasis_from

@runTableForm

procedure runTableForm
    @checkPraatVersion
    if not fileReadable(cli_gridFile$)
        exitScript: "TextGrid file not found: " + cli_gridFile$
    endif
    @isOffValue: cli_soundFile$
    if cli_formants > 1
        if isOffValue.off or not fileReadable(cli_soundFile$)
            exitScript: "A readable Sound file is required to tabulate formants."
        endif
    endif
    if cli_outputFile$ = ""
        exitScript: "Output table file: enter a file path."
    endif
    .folder$ = replace_regex$(cli_outputFile$, "[/\\][^/\\]*$", "", 0)
    if .folder$ != cli_outputFile$ and not folderExists(.folder$)
        exitScript: "The output folder does not exist: " + .folder$
    endif
    if fileReadable(cli_outputFile$) and not cli_overwrite
        exitScript: "The output file already exists. Set ""Overwrite existing file"" to replace it: " + cli_outputFile$
    endif

    @main
    selectObject: 'ui.output$'
    Save as tab-separated file: cli_outputFile$
    Remove
endproc

# Replaces the pause window: copies the form values into the settings the
# shared procedures expect.
procedure formTableSettings
    main.scale$[1] = "Hertz"
    main.scale$[2] = "Bark"
    ui.gridID$ = cli_gridFile$
    ui.soundID$ = cli_soundFile$
    @isOffValue: cli_soundFile$
    if isOffValue.off
        ui.soundID$ = ""
    endif
    ui.lowestTier$ = cli_baseTier$
    ui.otherTiers$ = cli_otherTiers$
    @isOffValue: cli_otherTiers$
    if isOffValue.off
        ui.otherTiers$ = ""
    endif
    ui.baseTierTimeOnly = cli_baseTierTimeOnly
    ui.formants2tabulate = cli_formants
    ui.formantTier$ = ""
    ui.vowelDur$ = cli_vowelDurTier$
    ui.maxNumFormants = ui.formants2tabulate - 1
    ui.scale = cli_scale
    ui.timeStep = cli_timeStep
    ui.maxFormantHz = cli_maxFormantHz
    ui.numFormants = cli_numFormants
    ui.windowLen = cli_windowLen
    ui.preEmph = cli_preEmph

    # The table is named after the output file, made safe for Praat.
    .name$ = replace_regex$(cli_outputFile$, "^.*[/\\]", "", 0)
    .name$ = replace_regex$(.name$, "\.[^.]*$", "", 0)
    .name$ = replace_regex$(.name$, "^.*", "\l&", 1)
    .name$ = replace_regex$(.name$, "^[0-9].*", "num_&", 1)
    .name$ = replace_regex$(.name$, "[^a-zA-Z0-9]", "_", 0)
    if .name$ = ""
        .name$ = "aeroplot_table"
    endif
    ui.output$ = .name$
endproc

include nestedTiers2Table.praat
