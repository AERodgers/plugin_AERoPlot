# Praat interface for FFT and LPC line spectra.
@checkPraatVersion
line_original# = selected#()
if numberOfSelected("Sound") != 1 or numberOfSelected("TextGrid") > 1
    exitScript: "Select one Sound, optionally with one TextGrid."
endif
line_sound = selected("Sound")
line_grid = 0
if numberOfSelected("TextGrid") = 1
    line_grid = selected("TextGrid")
endif
selectObject: line_sound
line_soundName$ = selected$("Sound")
line_sampling = Get sampling frequency
line_start = Get starting time
line_end = Get end time

line_tierCount = 0
line_tierChoice = 1
if line_grid
    selectObject: line_grid
    line_numberOfTiers = Get number of tiers
    for line_i to line_numberOfTiers
        line_isInterval = Is interval tier: line_i
        if not line_isInterval
            line_tierCount += 1
            line_tierNumber[line_tierCount] = line_i
            line_tierName$[line_tierCount] = Get tier name: line_i
        endif
    endfor
    if line_tierCount = 0
        selectObject: line_original#
        exitScript: "The selected TextGrid has no point tier."
    endif
endif
selectObject: line_original#

line_mode = 3
line_soundAnalysis = 1
line_time = (line_start + line_end) / 2
line_window = 0.025
line_coefficients = 0
line_maximum = min(5000, line_sampling / 2)
line_manualAxes = 0
line_fftMin = 0
line_fftMax = 100
line_lpcMin = 0
line_lpcMax = 100
line_vertical = 0
line_title$ = ""
line_width = 8
line_font = 2
line_resolution = 1
@readSharedSaveFolder
line_saveDir$ = saveDir$

line_dataDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data"
line_varsDir$ = line_dataDir$ + "/vars"
createFolder: preferencesDirectory$ + "/plugin_AERoPlot"
createFolder: line_dataDir$
createFolder: line_varsDir$
line_varsFile$ = line_varsDir$ + "/line_spectrum.var"
if not fileReadable(line_varsFile$)
    writeFileLine: line_varsFile$, "variable", tab$, "value"
    appendFileLine: line_varsFile$, "line_mode", tab$, line_mode
    appendFileLine: line_varsFile$, "line_soundAnalysis", tab$, line_soundAnalysis
    appendFileLine: line_varsFile$, "line_window", tab$, line_window
    appendFileLine: line_varsFile$, "line_coefficients", tab$, line_coefficients
    appendFileLine: line_varsFile$, "line_maximum", tab$, line_maximum
    appendFileLine: line_varsFile$, "line_manualAxes", tab$, line_manualAxes
    appendFileLine: line_varsFile$, "line_fftMin", tab$, line_fftMin
    appendFileLine: line_varsFile$, "line_fftMax", tab$, line_fftMax
    appendFileLine: line_varsFile$, "line_lpcMin", tab$, line_lpcMin
    appendFileLine: line_varsFile$, "line_lpcMax", tab$, line_lpcMax
    appendFileLine: line_varsFile$, "line_vertical", tab$, line_vertical
    appendFileLine: line_varsFile$, "line_title$", tab$, line_title$
    appendFileLine: line_varsFile$, "line_width", tab$, line_width
    appendFileLine: line_varsFile$, "line_font", tab$, line_font
    appendFileLine: line_varsFile$, "line_resolution", tab$, line_resolution
endif
@readVars: line_varsDir$ + "/", "line_spectrum.var"
@readSharedSaveFolder
line_saveDir$ = saveDir$
selectObject: line_original#
line_warned = 0
repeat
    @praatLineSpectrumDialog
    if line_clicked = 1
        selectObject: line_original#
        exit
    endif
    line_whole = 0
    if not line_grid and line_soundAnalysis = 1
        line_whole = 1
    endif
    @validateLineSpectrum: line_sound, line_mode, line_whole, line_window,
    ... line_coefficients, line_maximum, line_manualAxes, line_fftMin, line_fftMax,
    ... line_lpcMin, line_lpcMax, line_width
    line_order = validateLineSpectrum.order
    if line_grid
        line_tier = line_tierNumber[line_tierChoice]
        @collectLineSpectrumPoints: line_grid, line_tier, line_start, line_end, line_window
        line_count = collectLineSpectrumPoints.count
    else
        line_count = 1
        if not line_whole
            @validateLineSpectrumTime: line_time, line_start, line_end, line_window, "Time"
        endif
    endif
    saveDir$ = line_saveDir$
    @setSharedSaveFolder
    line_saveDir$ = saveDir$
    @writeVars: line_varsDir$ + "/", "line_spectrum.var"
    selectObject: line_original#
    if not line_warned
        @warnLongRecording: line_sound
        if not warnLongRecording.proceed
            selectObject: line_original#
            exit
        endif
        line_warned = 1
    endif
    @createLineSpectrumAnalysis: line_sound, line_mode, line_whole, line_window, line_order, line_maximum
    line_cancelled = 0
    for line_point to line_count
        line_label$ = ""
        if line_grid
            line_pointTime = collectLineSpectrumPoints.time[line_point]
            line_label$ = collectLineSpectrumPoints.label$[line_point]
        elsif line_whole
            line_pointTime = (line_start + line_end) / 2
        else
            line_pointTime = line_time
        endif
        @drawLineSpectrum: line_sound, line_mode, line_whole, line_pointTime, line_label$,
        ... line_title$, line_maximum, line_manualAxes, line_fftMin, line_fftMax,
        ... line_lpcMin, line_lpcMax, line_vertical, line_width, line_font
        @lineSpectrumFilename: line_soundName$, line_label$, line_whole, line_pointTime
        beginPause: "Save line spectrum"
            comment: "Image " + string$(line_point) + " of " + string$(line_count) + ": " + lineSpectrumFilename.name$
            comment: "Save folder: " + line_saveDir$
        line_saveChoice = endPause: "Cancel", "Skip", "Save", 3, 1
        if line_saveChoice = 1
            line_cancelled = 1
            break
        elsif line_saveChoice = 3
            @prepareImageSave: line_saveDir$, lineSpectrumFilename.name$
            Select outer viewport: 0, line_width, 0, 4
            if line_resolution = 1
                Save as 300-dpi PNG file: prepareImageSave.path$
            else
                Save as 600-dpi PNG file: prepareImageSave.path$
            endif
            appendInfoLine: "Saved: " + prepareImageSave.path$
        endif
    endfor
    @removeLineSpectrumAnalysis
    selectObject: line_original#
until line_clicked = 3 or line_cancelled

include _genFnBank.praat
include _aeroplotFns.praat
include _line_spectrum.praat
include _praat_line_spectrum_ui.praat
