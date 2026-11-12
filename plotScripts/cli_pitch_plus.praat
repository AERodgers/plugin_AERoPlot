form AERoPlot: PitchPlus (command line)
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
    natural Smoothing 999
    boolean Paint_spectrogram 1
    boolean Draw_sound_waveform 0
    positive Window_width 8
    natural Minimum_F0 60
    natural Maximum_F0 400
    real Minimum_dB 30
    real Maximum_dB 90
    optionmenu Plot_type 1
        option F0 + secondary parameter
        option F0 only
        option Intensity only
        option Background only
    optionmenu F0_scale 2
        option Hertz
        option Semitones re 1 Hz
    optionmenu Secondary_parameter 1
        option Cepstral Peak Prominence
        option Residual of intensity (linear regression)
        option H1-H2 of differentiated glottal pulse (LPC-IF)
        option Harmonicity (Praat function)
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
spectrogram_only = 0
plot_interface$ = "PitchPlus"
cli_soundFile$ = sound_file$
cli_gridFile$ = textgrid_file$
cli_outputFile$ = output_png_file$
cli_overwrite = overwrite_existing_file
cli_dpi = png_resolution
cli_title$ = image_title$
cli_smoothing = smoothing
cli_paint = paint_spectrogram
cli_waveform = draw_sound_waveform
cli_width = window_width
cli_minF0 = minimum_F0
cli_maxF0 = maximum_F0
cli_mindB = minimum_dB
cli_maxdB = maximum_dB
cli_plotType = plot_type
cli_f0Scale = f0_scale
cli_secondary = secondary_parameter
cli_font = font
cli_cropTier$ = crop_tier$
cli_displayTier$ = display_tier$
cli_tgFont = textgrid_font
cli_boundaries = show_textgrid_boundaries

@formLoadPlotObjects

include _pitch_plus.praat
