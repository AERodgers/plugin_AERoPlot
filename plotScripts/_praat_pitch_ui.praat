procedure praatPlotDialog
    beginPause: plot_interface$ + " settings"
    sentence: "Image title", image_title$
    if not spectrogram_only
        comment: "Display settings: F0-only smoothing; width in inches"
        natural: "Smoothing", smoothing
        boolean: "Paint spectrogram", paint_spectrogram
    else
        comment: "Display settings: width in inches"
    endif
    boolean: "Draw sound waveform", draw_sound_waveform
    positive: "Window width", window_width
    if not spectrogram_only
        comment: "F0 limits (Hz) and intensity limits (dB)"
        natural: "Minimum F0", minimum_F0
        natural: "Maximum F0", maximum_F0
        real: "Minimum dB", minimum_dB
        real: "Maximum dB", maximum_dB
        comment: "Select the contour and, for F0 + secondary parameter, its measure."
        optionMenu: "Plot type", plot_type
            option: "F0 + secondary parameter"
            option: "F0 only"
            option: "Intensity only"
            option: "Background only"
        optionMenu: "F0 scale", f0_scale
            option: "Hertz"
            option: "Semitones re 1 Hz"
        optionMenu: "Secondary parameter", secondary_parameter
            option: "Cepstral Peak Prominence"
            option: "Residual of intensity (linear regression)"
            option: "H1-H2 of differentiated glottal pulse (LPC-IF)"
            option: "Harmonicity (Praat function)"
    endif
    optionMenu: "Font", font
        option: "Times"
        option: "Helvetica"
        option: "Palatino"
        option: "Courier"
    if sound and grid
        comment: "TextGrid options"
        optionMenu: "Crop tier", crop_tier
            option: "Do not crop"
            for tier to number_of_tiers
                if tier_is_interval[tier]
                    option: string$(tier) + ": " + tier_name$[tier]
                endif
            endfor
        optionMenu: "Display tier", display_tier
            option: "No TextGrid"
            for tier to number_of_tiers
                option: string$(tier) + ": " + tier_name$[tier]
            endfor
        optionMenu: "TextGrid font", textGrid_font
            option: "Times"
            option: "Helvetica"
            option: "Palatino"
            option: "Courier"
        boolean: "Show TextGrid boundaries", show_TextGrid_boundaries
    endif
    clicked = endPause: "Cancel", "Draw", "Draw & Exit", 3, 1
endproc
