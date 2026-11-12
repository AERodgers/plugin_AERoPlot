# Command-line (form) interface for PitchPlus and Spectrogram.
# This file contains NO drawing or analysis. It only turns the values collected
# by cli_pitch_plus.praat / cli_spectrogram.praat into the settings that
# _pitch_plus.praat expects, and saves the finished image.

procedure formCheckPlotInput
    if not fileReadable(cli_soundFile$)
        exitScript: "Sound file not found: " + cli_soundFile$
    endif
    if cli_outputFile$ = ""
        exitScript: "Output PNG file: enter a file path."
    endif
    .folder$ = replace_regex$(cli_outputFile$, "[/\\][^/\\]*$", "", 0)
    if .folder$ != cli_outputFile$ and not folderExists(.folder$)
        exitScript: "The output folder does not exist: " + .folder$
    endif
    if fileReadable(cli_outputFile$) and not cli_overwrite
        exitScript: "The output file already exists. Set ""Overwrite existing file"" to replace it: " + cli_outputFile$
    endif
    @isOffValue: cli_gridFile$
    cli_hasGrid = not isOffValue.off
    if cli_hasGrid and not fileReadable(cli_gridFile$)
        exitScript: "TextGrid file not found: " + cli_gridFile$
    endif
endproc

# Read the files and select them, as if the user had selected them in Praat.
procedure formLoadPlotObjects
    @formCheckPlotInput
    cli_soundObj = Read from file: cli_soundFile$
    if numberOfSelected("Sound") != 1
        exitScript: "The Sound file could not be read as a Sound: " + cli_soundFile$
    endif
    cli_gridObj = 0
    if cli_hasGrid
        cli_gridObj = Read from file: cli_gridFile$
        if numberOfSelected("TextGrid") != 1
            removeObject: cli_soundObj, cli_gridObj
            exitScript: "The TextGrid file could not be read as a TextGrid: " + cli_gridFile$
        endif
        selectObject: cli_soundObj, cli_gridObj
    endif
endproc

# Replaces the settings window: no looping, no pop-ups.
procedure formPlotDialog
    @isOffValue: cli_title$
    image_title$ = cli_title$
    if isOffValue.off
        image_title$ = ""
    endif
    smoothing = cli_smoothing
    paint_spectrogram = cli_paint
    draw_sound_waveform = cli_waveform
    window_width = cli_width
    minimum_f0 = cli_minF0
    maximum_f0 = cli_maxF0
    minimum_F0 = cli_minF0
    maximum_F0 = cli_maxF0
    minimum_dB = cli_mindB
    maximum_dB = cli_maxdB
    plot_type = cli_plotType
    f0_scale = cli_f0Scale
    secondary_parameter = cli_secondary
    font = cli_font
    textGrid_font = cli_tgFont
    show_TextGrid_boundaries = cli_boundaries

    crop_tier = 1
    display_tier = 1
    if sound and grid
        @isOffValue: cli_cropTier$
        if not isOffValue.off
            @resolveTierNumber: grid, cli_cropTier$, "Crop tier", "interval"
            .cropTier = resolveTierNumber.tier
            for .tier to .cropTier
                if tier_is_interval[.tier]
                    crop_tier += 1
                endif
            endfor
        endif
        @isOffValue: cli_displayTier$
        if not isOffValue.off
            @resolveTierNumber: grid, cli_displayTier$, "Display tier", "any"
            display_tier = resolveTierNumber.tier + 1
        endif
    else
        @isOffValue: cli_cropTier$
        if not isOffValue.off
            exitScript: "Crop tier: a TextGrid file is required to crop by a tier."
        endif
        @isOffValue: cli_displayTier$
        if not isOffValue.off
            exitScript: "Display tier: a TextGrid file is required to display a tier."
        endif
    endif
    selectObject: original_state#
    clicked = 3
endproc

procedure formPlotFinish
    if cli_dpi = 2
        Save as 600-dpi PNG file: cli_outputFile$
    else
        Save as 300-dpi PNG file: cli_outputFile$
    endif
    removeObject: cli_soundObj
    if cli_gridObj
        removeObject: cli_gridObj
    endif
    appendInfoLine: "Saved: " + cli_outputFile$
endproc
