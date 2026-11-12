form AERoPlot: Spectrogram (command line)
    comment All values are required positionally when run with Praat --run.
    comment Use "none" for the TextGrid file, title or tiers if they are not wanted.
    sentence Sound_file
    sentence Textgrid_file none
    sentence Output_png_file
    boolean Overwrite_existing_file 0
    optionmenu Png_resolution 1
        option 300 dpi
        option 600 dpi
    sentence Image_title none
    boolean Draw_sound_waveform 0
    positive Window_width 8
    optionmenu Font 2
        option Times
        option Helvetica
        option Palatino
        option Courier
    sentence Crop_tier none
    sentence Display_tier none
    optionmenu Textgrid_font 1
        option Times
        option Helvetica
        option Palatino
        option Courier
    boolean Show_textgrid_boundaries 0
endform

# Command-line entry point. It only collects settings; _pitch_plus.praat does
# the drawing, exactly as for the dialogs.
aeroFormPlotUI = 1
aeroNonInteractive = 1
spectrogram_only = 1
plot_interface$ = "Spectrogram"
cli_soundFile$ = sound_file$
cli_gridFile$ = textgrid_file$
cli_outputFile$ = output_png_file$
cli_overwrite = overwrite_existing_file
cli_dpi = png_resolution
cli_title$ = image_title$
cli_waveform = draw_sound_waveform
cli_width = window_width
cli_font = font
cli_cropTier$ = crop_tier$
cli_displayTier$ = display_tier$
cli_tgFont = textgrid_font
cli_boundaries = show_textgrid_boundaries
# Not used by the spectrogram, but the shared script expects them.
cli_smoothing = 999
cli_paint = 1
cli_minF0 = 60
cli_maxF0 = 400
cli_mindB = 30
cli_maxdB = 90
cli_plotType = 4
cli_f0Scale = 2
cli_secondary = 1

@formLoadPlotObjects

include _pitch_plus.praat
