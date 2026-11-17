procedure praatLineSpectrumDialog
    beginPause: "Line spectrum settings"
        optionMenu: "Spectrum", line_mode
            option: "FFT"
            option: "LPC"
            option: "FFT and LPC"
        if line_grid
            optionMenu: "Point tier", line_tierChoice
            for line_i to line_tierCount
                option: string$(line_tierNumber[line_i]) + ": " + line_tierName$[line_i]
            endfor
            comment: "Only labelled points are processed."
        else
            optionMenu: "Sound analysis", line_soundAnalysis
                option: "Whole sound"
                option: "Specific time"
            real: "Time in seconds", line_time
        endif
        comment: "Analysis window is in seconds; 0 LPC coefficients selects the automatic value."
        positive: "Analysis window", line_window
        integer: "LPC coefficients", line_coefficients
        positive: "Maximum frequency", line_maximum
        boolean: "Manual dB ranges", line_manualAxes
        real: "FFT minimum dB", line_fftMin
        real: "FFT maximum dB", line_fftMax
        real: "LPC minimum dB", line_lpcMin
        real: "LPC maximum dB", line_lpcMax
        boolean: "Show vertical lines", line_vertical
        sentence: "Image title", line_title$
        positive: "Window width", line_width
        optionMenu: "Font", line_font
            option: "Times"
            option: "Helvetica"
            option: "Palatino"
            option: "Courier"
        sentence: "Save folder", line_saveDir$
        optionMenu: "PNG resolution", line_resolution
            option: "300 dpi"
            option: "600 dpi"
    line_clicked = endPause: "Cancel", "Draw", "Draw & Exit", 3, 1
    if line_clicked != 1
        line_mode = spectrum
        if line_grid
            line_tierChoice = point_tier
        else
            line_soundAnalysis = sound_analysis
            line_time = time_in_seconds
        endif
        line_window = analysis_window
        line_coefficients = lPC_coefficients
        line_maximum = maximum_frequency
        line_manualAxes = manual_dB_ranges
        line_fftMin = fFT_minimum_dB
        line_fftMax = fFT_maximum_dB
        line_lpcMin = lPC_minimum_dB
        line_lpcMax = lPC_maximum_dB
        line_vertical = show_vertical_lines
        line_title$ = image_title$
        line_width = window_width
        line_font = font
        line_saveDir$ = save_folder$
        line_resolution = pNG_resolution
    endif
endproc
