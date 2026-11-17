# Analysis and drawing for the Line spectrum Praat interface.

procedure validateLineSpectrum: .sound, .mode, .whole, .window, .coefficients, .maximum,
... .manualAxes, .fftMin, .fftMax, .lpcMin, .lpcMax, .width
    .selection# = selected#()
    selectObject: .sound
    .start = Get starting time
    .end = Get end time
    .sampling = Get sampling frequency
    .duration = .end - .start
    selectObject: .selection#
    if .mode < 1 or .mode > 3
        exitScript: "Choose FFT, LPC, or both."
    endif
    if .maximum <= 0 or .maximum > .sampling / 2
        exitScript: "Maximum frequency must be positive and no greater than the Sound's Nyquist frequency (" +
        ... string$(.sampling / 2) + " Hz)."
    endif
    if .width <= 0
        exitScript: "Window width must be greater than zero."
    endif
    if not .whole and (.window <= 0 or 2 * .window > .duration)
        exitScript: "The Sound must be at least twice as long as the positive analysis window."
    endif
    if .manualAxes
        if .mode != 2 and .fftMax <= .fftMin
            exitScript: "The FFT maximum dB must be greater than its minimum."
        endif
        if .mode != 1 and .lpcMax <= .lpcMin
            exitScript: "The LPC maximum dB must be greater than its minimum."
        endif
    endif
    .order = .coefficients
    if .mode != 1
        if .order < 0 or .order != floor(.order)
            exitScript: "LPC coefficients must be a non-negative integer; 0 selects the automatic value."
        endif
        if .order = 0
            .order = round(.sampling / 1000) + 2
        endif
        .analysisDuration = 2 * .window
        if .whole
            .analysisDuration = .duration
        endif
        if .order >= floor(.analysisDuration * .sampling)
            exitScript: "The LPC coefficient count is too large for the analysis window."
        endif
    endif
endproc

procedure validateLineSpectrumTime: .time, .start, .end, .window, .description$
    if .time < .start + .window or .time > .end - .window
        exitScript: .description$ + " (" + fixed$(.time, 6) +
        ... " s) is too close to a Sound boundary or outside the Sound. " +
        ... "A full Gaussian window is needed on both sides."
    endif
endproc

# Collect only labelled points; retain their original labels for the plot.
procedure collectLineSpectrumPoints: .grid, .tier, .start, .end, .window
    .count = 0
    .selection# = selected#()
    selectObject: .grid
    .interval = Is interval tier: .tier
    if .interval
        selectObject: .selection#
        exitScript: "Choose a point tier for Line spectrum."
    endif
    .points = Get number of points: .tier
    for .i to .points
        .label$ = Get label of point: .tier, .i
        .trimmed$ = replace_regex$(.label$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0)
        if .trimmed$ != ""
            .time = Get time of point: .tier, .i
            .count += 1
            .time[.count] = .time
            .label$[.count] = .label$
            .index[.count] = .i
        endif
    endfor
    selectObject: .selection#
    if .count = 0
        exitScript: "The selected point tier has no labelled points."
    endif
    for .i to .count
        @validateLineSpectrumTime: .time[.i], .start, .end, .window, "Point " + string$(.index[.i])
    endfor
endproc

procedure lineSpectrumFilename: .soundName$, .label$, .whole, .time
    .base$ = replace_regex$(.soundName$, "[\\/:*?""<>|\r\n\t]", "_", 0)
    .base$ = replace_regex$(.base$, "[ \t\r\n.]+$", "", 0)
    if .base$ = ""
        .base$ = "Sound"
    endif
    if .whole
        .suffix$ = "whole"
    elsif .label$ = ""
        .suffix$ = fixed$(.time, 6) + "s"
    else
        .suffix$ = replace_regex$(.label$, "[\\/:*?""<>|\r\n\t]", "_", 0)
        .suffix$ = replace_regex$(.suffix$, "^[ \t\r\n.]+|[ \t\r\n.]+$", "", 0)
        if .suffix$ = ""
            .suffix$ = fixed$(.time, 6) + "s"
        endif
    endif
    .name$ = .base$ + "_" + .suffix$ + ".png"
endproc

# The whole-sound LPC frame uses a Gaussian window spanning the complete Sound.
procedure createLineSpectrumAnalysis: .sound, .mode, .whole, .window, .order, .maximum
    .spectrogram = 0
    .lpc = 0
    .fft = 0
    selectObject: .sound
    if .whole and .mode != 2
        .fft = To Spectrum: "yes"
    elsif not .whole and .mode != 2
        .spectrogram = To Spectrogram: .window, .maximum, 0.002, 20, "Gaussian"
    endif
    if .mode != 1
        selectObject: .sound
        .lpcWindow = .window
        if .whole
            .duration = Get total duration
            .lpcWindow = .duration / 2
        endif
        .lpc = To LPC (autocorrelation): .order, .lpcWindow, 0.005, 50
    endif
endproc

procedure drawLineSpectrum: .sound, .mode, .whole, .time, .label$, .title$,
... .maximum, .manualAxes, .fftMin, .fftMax, .lpcMin, .lpcMax,
... .vertical, .width, .font
    .fft = 0
    .lpc = 0
    if .mode != 2
        if .whole
            .fft = createLineSpectrumAnalysis.fft
        else
            selectObject: createLineSpectrumAnalysis.spectrogram
            .fft = To Spectrum (slice): .time
        endif
    endif
    if .mode != 1
        selectObject: createLineSpectrumAnalysis.lpc
        .lpc = To Spectrum (slice): .time, 20, 0, 50
    endif
    .fftLow = 0
    .fftHigh = 0
    .lpcLow = 0
    .lpcHigh = 0
    if .manualAxes
        .fftLow = .fftMin
        .fftHigh = .fftMax
        .lpcLow = .lpcMin
        .lpcHigh = .lpcMax
    endif
    .font$[1] = "Times"
    .font$[2] = "Helvetica"
    .font$[3] = "Palatino"
    .font$[4] = "Courier"
    .fontCommand$ = .font$[.font]
    Erase all
    Select outer viewport: 0, .width, 0, 4
    '.fontCommand$'
    Font size: 12
    Solid line
    Black
    if .mode != 2
        selectObject: .fft
        Line width: 2
        Draw: 0, .maximum, .fftLow, .fftHigh, "no"
        Line width: 1
        Marks left every: 1, 10, "yes", "yes", "no"
        Text left: "yes", "FFT (dB)"
    endif
    if .mode != 1
        selectObject: .lpc
        if .mode = 3
            Blue
        else
            Black
        endif
        Line width: 2
        Draw: 0, .maximum, .lpcLow, .lpcHigh, "no"
        Line width: 1
        Black
        if .mode = 3
            Marks right every: 1, 10, "yes", "yes", "no"
            Text right: "yes", "LPC (dB)"
        else
            Marks left every: 1, 10, "yes", "yes", "no"
            Text left: "yes", "LPC (dB)"
        endif
    endif
    Draw inner box
    .grid$ = "no"
    if .vertical
        .grid$ = "yes"
    endif
    Marks bottom every: 1000, 0.5, "yes", "yes", .grid$
    Text bottom: "yes", "Frequency (kHz)"
    .displayTitle$ = .title$
    if .displayTitle$ = ""
        selectObject: .sound
        .displayTitle$ = selected$("Sound")
    endif
    if .whole
        .displayTitle$ += " (whole sound)"
    else
        if .label$ != ""
            .displayTitle$ += " - " + .label$
        endif
        .displayTitle$ += " (" + fixed$(.time * 1000, 1) + " ms)"
    endif
    .displayTitle$ = replace_regex$(.displayTitle$, "[%#\^_]", "\\& ", 0)
    Font size: 16
    Text top: "yes", .displayTitle$
    Font size: 12
    if .lpc
        removeObject: .lpc
    endif
    if .fft and not .whole
        removeObject: .fft
    endif
endproc

procedure removeLineSpectrumAnalysis
    if createLineSpectrumAnalysis.spectrogram
        removeObject: createLineSpectrumAnalysis.spectrogram
    endif
    if createLineSpectrumAnalysis.lpc
        removeObject: createLineSpectrumAnalysis.lpc
    endif
    if createLineSpectrumAnalysis.fft
        removeObject: createLineSpectrumAnalysis.fft
    endif
endproc
