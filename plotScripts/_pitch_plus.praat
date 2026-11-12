
# PitchPlus
# =============
# Written for Praat 6.0.60 or later
#
# This version is included as a feature of the AERoplot plugin.
#
# script by Antoin Eoin Rodgers
#
# | email   | antoin.rodgers@tcd.ie
# | github  | github.com/AERodgers

### PitchPlus
    # This script draws a selected contour with a spectrogram and single textgrid reference tier
    # (if grid and tier are specified). PitchPlus uses a secondary parameter to determine the
    # size and intensity of pitch points. Cut-off points are built into the functions, below or
    # above which the F0 contour is shown with a red dot. (NB: For H1-H2, lower values are indicated
    # by larger circles and more intense colour.)
    #
    # It is written as a set of procedures so can be implemented in other scripts, while other
    # functions (e.g. @pitch and @h1h2) can be replaced with alternative estimation algorithms.
    #
    # The script is inspired by the excellent periogram demonstrated at ICPHS by Albert, Cangemi,
    # and Grice (2019).
    #
    # Script and procedures are published under the GNU GENERAL PUBLIC LICENSE.
    #
    # REFERENCE
    # Albert, A., Cangemi, F., & Grice, M. (2019). Can you draw me a question?
    #     International Congress of Phonetic Sciences. doi.org/10.13140
    #     /RG.2.2.15700.14729
    #
    # UPDATES
    # 1.1.0    - 20.10.19 - Textgrid no longer required (leave grid or tier
    #                       field as 0)
    # 1.1.1    - 21.10.19 - Added table2array procedure and indicated procedure
    #                       dependencies at
    #                       start of each procedure to make it easier to
    #                       incpororate them into other scripts.
    # 1.2.-    - 28.10.20 - added ability to display intensity curve
    #                     - added window width function.
    # 1.2.1    - 21.06.22 - C3PoGram can now draw normal f0 contour.
    #                     - smoothing parameter added for normal f0 contour.
    #                       [NB 999 = no smoothing, 19 = mild smoothing]
    #                     - If a sound, textgrid, and pitch object is selected,
    #                       C3PoGram will assume that the pitch object is a
    #                       smoothed or modified version of the original pitch
    #                       contour and will draw the original contour in light
    #                       grey beneath the contour in the pitch object.
    #                     - if no title is provided, title will default to
    #                       name of sound object
    # 1.3.0               - Changed C3PoGram input from pause menu to form to
    #                     - allow access to it while other plugin pause menus
    #                       are running.
    # 1.4.0               - Improved UI appearance and added more comments to code.
    #                     - Added font selection to UI.
    #                     - Added option to include sound waveform in output.
    # 1.5.0               - Added conditional TextGrid tier menus and interval
    #                       cropping; replaced the form with a pause window.

    # MAIN SCRIPT

    @checkPraatVersion

    # Identify selected objects before building the UI so the TextGrid controls
    # can be shown only when both a Sound and TextGrid are selected.
    original_state# = selected#()
    sound = 0
    grid = 0
    pitch_obj = 0
    if numberOfSelected("Sound") > 0
        sound = selected("Sound")
    else
        exitScript: "Select a Sound object before running " + plot_interface$ + "."
    endif
    if numberOfSelected("TextGrid") > 0
        grid = selected("TextGrid")
    endif
    if numberOfSelected("Pitch") > 0
        pitch_obj = selected("Pitch")
    endif

    number_of_tiers = 0
    crop_tier = 1
    display_tier = 1
    if sound and grid
        selectObject: grid
        number_of_tiers = Get number of tiers
        crop_option_index = 1
        for tier to number_of_tiers
            tier_name$[tier] = Get tier name: tier
            tier_is_interval[tier] = Is interval tier: tier
            if tier_is_interval[tier]
                crop_option_index += 1
                if crop_tier = 1
                    crop_tier = crop_option_index
                endif
            endif
        endfor
        if number_of_tiers > 0
            display_tier = 2
        endif
    endif
    selectObject: original_state#

    image_title$ = ""
    smoothing = 999
    paint_spectrogram = 1
    draw_sound_waveform = 0
    window_width = 8
    minimum_f0 = 60
    maximum_f0 = 400
    minimum_dB = 30
    maximum_dB = 90
    plot_type = 1
    f0_scale = 2
    secondary_parameter = 1
    font = 2
    textGrid_font = 1
    show_TextGrid_boundaries = 0

    pitch_plus_plugin_dir$ = preferencesDirectory$ + "/plugin_AERoPlot"
    if !folderExists(pitch_plus_plugin_dir$)
        createFolder: pitch_plus_plugin_dir$
    endif
    pitch_plus_data_dir$ = pitch_plus_plugin_dir$ + "/data"
    if !folderExists(pitch_plus_data_dir$)
        createFolder: pitch_plus_data_dir$
    endif
    pitch_plus_vars_dir$ = pitch_plus_data_dir$ + "/vars"
    if !folderExists(pitch_plus_vars_dir$)
        createFolder: pitch_plus_vars_dir$
    endif
    pitch_plus_vars$ = pitch_plus_vars_dir$ + "/pitch_plus.var"
    if !fileReadable(pitch_plus_vars$)
        legacy_vars$ = pitch_plus_vars_dir$ + "/pitch_plot_plus.var"
        if !fileReadable(legacy_vars$)
            legacy_vars$ = pitch_plus_vars_dir$ + "/c3pogram.var"
        endif
        if fileReadable(legacy_vars$)
            writeFile: pitch_plus_vars$, readFile$(legacy_vars$)
        endif
    endif
    if !fileReadable(pitch_plus_vars$)
        writeFileLine: pitch_plus_vars$, "variable", tab$, "value"
        appendFileLine: pitch_plus_vars$, "image_title$", tab$, image_title$
        appendFileLine: pitch_plus_vars$, "smoothing", tab$, smoothing
        appendFileLine: pitch_plus_vars$, "paint_spectrogram", tab$, paint_spectrogram
        appendFileLine: pitch_plus_vars$, "draw_sound_waveform", tab$, draw_sound_waveform
        appendFileLine: pitch_plus_vars$, "window_width", tab$, window_width
        appendFileLine: pitch_plus_vars$, "minimum_f0", tab$, minimum_f0
        appendFileLine: pitch_plus_vars$, "maximum_f0", tab$, maximum_f0
        appendFileLine: pitch_plus_vars$, "minimum_dB", tab$, minimum_dB
        appendFileLine: pitch_plus_vars$, "maximum_dB", tab$, maximum_dB
        appendFileLine: pitch_plus_vars$, "plot_type", tab$, plot_type
        appendFileLine: pitch_plus_vars$, "f0_scale", tab$, f0_scale
        appendFileLine: pitch_plus_vars$, "secondary_parameter", tab$, secondary_parameter
        appendFileLine: pitch_plus_vars$, "font", tab$, font
        appendFileLine: pitch_plus_vars$, "show_TextGrid_boundaries", tab$, show_TextGrid_boundaries
    endif
    @readVars: pitch_plus_vars_dir$ + "/", "pitch_plus.var"
    hasBoundarySetting = 0
    for settingIndex to pitch_plusNumVars
        if pitch_plusVar$[settingIndex] = "show_TextGrid_boundaries"
            hasBoundarySetting = 1
        endif
    endfor
    if not hasBoundarySetting
        appendFileLine: pitch_plus_vars$, "show_TextGrid_boundaries", tab$, show_TextGrid_boundaries
        @readVars: pitch_plus_vars_dir$ + "/", "pitch_plus.var"
    endif
    selectObject: original_state#

    longRecordingConfirmed = 0
    windowsPlotUI = 0
    formPlotUI = 0
    asyncPlotCallback = 0
    asyncPlotLaunch = 0
    if variableExists("aeroFormPlotUI")
        formPlotUI = 1
    elsif variableExists("aeroAsyncPlotCallback")
        windowsPlotUI = 1
        asyncPlotCallback = 1
        longRecordingConfirmed = 1
    elsif variableExists("aeroWindowsPlotUI")
        windowsPlotUI = aeroWindowsPlotUI
    else
        # Use the saved interface preference; fall back silently to Praat.
        @getUIMode
        windowsPlotUI = getUIMode.mode$ = "windows"
        asyncPlotLaunch = windowsPlotUI
    endif
    if windowsPlotUI
        @windowsPlotInitialize
    endif
    if asyncPlotLaunch
        # The dialog runs on its own; Praat stays usable and is asked to draw when needed.
        @windowsPlotLaunch
        selectObject: original_state#
        exit
    endif
    repeat
    minimum_F0 = minimum_f0
    maximum_F0 = maximum_f0
    if formPlotUI
        @formPlotDialog
    elsif asyncPlotCallback
        @asyncPlotDialog
    elsif windowsPlotUI
        @windowsPlotDialog
    else
        @praatPlotDialog
    endif
    if clicked = 1
        selectObject: original_state#
        exit
    endif
    minimum_f0 = minimum_F0
    maximum_f0 = maximum_F0
    if not formPlotUI
        @writeVars: pitch_plus_vars_dir$ + "/", "pitch_plus.var"
    endif
    selectObject: original_state#

    draw_plot_type = plot_type
    draw_paint_spectrogram = paint_spectrogram
    if spectrogram_only
        draw_plot_type = 4
        draw_paint_spectrogram = 1
    endif

    # The drawing procedures use the global layout_ variables defined here.
    # If reusing these procedures elsewhere, define the required layout_
    # variables in the calling script as well.
#
# Layout dimensions in inches. Vertical coordinates increase downward.
# Allow for the larger title, 12-point axes and TextGrid labels, and their margins.
layout_plot_height = 3.6
layout_font_size = 12
# Praat's TextGrid Draw reserves one fifth of its inner height for one tier.
layout_inner_margin = 2.8 * layout_font_size / 72
layout_tier_height = (layout_plot_height - 2 * layout_inner_margin) / 4
layout_waveform_height = 0.75
layout_waveform_margin = layout_inner_margin
layout_title_height = 0.55

# Validate before modifying the selected Sound or creating analysis objects.
if (draw_plot_type = 1 or draw_plot_type = 2 or draw_plot_type = 3) and minimum_f0 <= 0
    exitScript: "Minimum F0 must be greater than zero."
endif
if (draw_plot_type = 1 or draw_plot_type = 2) and maximum_f0 <= minimum_f0
    exitScript: "Maximum F0 must be greater than minimum F0."
endif
if draw_plot_type = 3 and maximum_dB <= minimum_dB
    exitScript: "Maximum intensity must be greater than minimum intensity."
endif
if window_width <= 0
    exitScript: "Window width must be greater than zero."
endif
crop_tier_id = 0
display_tier_id = 0
if sound and grid
    if crop_tier > 1
        crop_option_index = 1
        for tier to number_of_tiers
            if tier_is_interval[tier]
                crop_option_index += 1
                if crop_option_index = crop_tier
                    crop_tier_id = tier
                endif
            endif
        endfor
    endif
    if display_tier > 1
        display_tier_id = display_tier - 1
    endif
endif
if not longRecordingConfirmed
    @warnLongRecording: sound
    if not warnLongRecording.proceed
        selectObject: original_state#
        exit
    endif
    longRecordingConfirmed = 1
endif

# Calculate viewport boundaries for the selected tier and waveform.
layout_left = 0
layout_right = window_width
layout_plot_top = 0
if draw_sound_waveform
    layout_waveform_inner_top = layout_title_height
    layout_waveform_inner_bottom = layout_waveform_inner_top + layout_waveform_height
    layout_waveform_outer_top = layout_waveform_inner_top - layout_waveform_margin
    layout_waveform_outer_bottom = layout_waveform_inner_bottom + layout_waveform_margin
    # Align the plot with the waveform's nominal inner bottom, allowing for the outer margin.
    layout_plot_top = layout_waveform_inner_bottom - layout_waveform_margin
endif

layout_plot_bottom = layout_plot_top + layout_plot_height
layout_image_bottom = layout_plot_bottom
if display_tier_id > 0
    layout_image_bottom = layout_image_bottom + layout_tier_height
endif
layout_title_bottom = layout_image_bottom
if draw_sound_waveform
    layout_title_bottom = layout_title_height
endif

title$ = image_title$
if title$ = ""
    selectObject: sound
    title$ = selected$("Sound")
    title$ = replace_regex$ (title$, "[%#\^_]", "\\& ", 0)
endif

@pitchPlus: draw_plot_type, secondary_parameter, f0_scale, draw_paint_spectrogram,
    ... draw_sound_waveform, font, title$,
    ... grid, sound, pitch_obj, crop_tier_id, display_tier_id,
    ... textGrid_font, show_TextGrid_boundaries, minimum_f0, maximum_f0,
    ... minimum_dB, maximum_dB, window_width, smoothing

selectObject: original_state#
until clicked = 3

if formPlotUI
    @formPlotFinish
endif
if asyncPlotCallback
    @asyncPlotFinish
endif


# PitchPlus functions
procedure pitchPlus: .plotType, .param2, .hz_ST, .paintSpect, .drawWaveform,
    ... .font, .title$,
    ... .grid, .sound, .pitch_two, .cropTier, .displayTier, .textGridFont,
    ... .showBoundaries, .minF0, .maxF0, .mindB, .maxdB, .vpWidth, .smoothing

    if not .paintSpect and .plotType = 4 and not .drawWaveform and
    ... .displayTier <= 0
        exitScript: "Nothing is selected to draw. Enable the spectrogram or waveform, " +
        ... "select a contour, or choose a TextGrid tier."
    endif

    # Normalize the selected Sound itself, not just its display.
    selectObject: .sound
    Scale intensity: 70
    .minT = Get start time
    .maxT = Get end time

    if .cropTier > 0
        selectObject: .grid
        .numIntervals = Get number of intervals: .cropTier
        .firstNonempty = 0
        .lastNonempty = 0
        for .i to .numIntervals
            .label$ = Get label of interval: .cropTier, .i
            if .label$ <> ""
                if .firstNonempty = 0
                    .firstNonempty = .i
                endif
                .lastNonempty = .i
            endif
        endfor
        if .firstNonempty = 0
            selectObject: original_state#
            exitScript: "The selected TextGrid crop tier has no non-empty intervals."
        endif
        .cropStart = Get start time of interval: .cropTier, .firstNonempty
        .cropEnd = Get end time of interval: .cropTier, .lastNonempty
        .minT = max(.minT, .cropStart)
        .maxT = min(.maxT, .cropEnd)
        if .maxT <= .minT
            selectObject: original_state#
            exitScript: "The selected TextGrid intervals do not overlap the Sound."
        endif
    endif

    if .displayTier > 0
        selectObject: .grid
        .refTier = Extract one tier: .displayTier
    endif

    # reset draw space
    Erase all
    Black
    10
    Line width: 1
    Solid line
    .font$[1] = "Times"
    .font$[2] = "Helvetica"
    .font$[3] = "Palatino"
    .font$[4] = "Courier"
    .fontCommand$ = .font$[.font]
    '.fontCommand$'
    Font size: 12
    .textGridFont$[1] = "Times"
    .textGridFont$[2] = "Helvetica"
    .textGridFont$[3] = "Palatino"
    .textGridFont$[4] = "Courier"

    if .drawWaveform
        Select outer viewport: layout_left, layout_right,
        ... layout_waveform_outer_top,
        ... layout_waveform_outer_bottom
        Black
        selectObject: .sound
        .waveMin = Get minimum: .minT, .maxT, "None"
        .waveMax = Get maximum: .minT, .maxT, "None"
        .waveRange = .waveMax - .waveMin
        if .waveRange > 0
            .waveMin = .waveMin - .waveRange * 0.05
            .waveMax = .waveMax + .waveRange * 0.05
        else
            .waveMin = -1
            .waveMax = 1
        endif
        Draw: .minT, .maxT, .waveMin, .waveMax, "no", "Curve"
        Line width: 1
        Draw inner box
    endif

    Select outer viewport: layout_left, layout_right, layout_plot_top, layout_plot_bottom

    # draw spectrogram
    if .paintSpect
        selectObject: .sound
        specky = To Spectrogram: 0.005, 5000, 0.002, 20, "Gaussian"
        Paint: .minT, .maxT, 0, 0, 100, "yes", 50, 8, 0, "no"
        if .plotType = 4
            Marks left every: 1, 200, "no", "yes", "no"
            Line width: 2
            Marks left every: 1000, 1, "yes", "yes", "no"
            Text left: "yes", "Frequency (Hz)"
        else
            Marks right every: 1, 200, "no", "yes", "no"
            Line width: 2
            Marks right every: 1000, 1, "yes", "yes", "no"
            Text right: "yes", "Spectral Frequency (kHz)"
        endif
        Remove
    endif
    Line width: 1
    Draw inner box

    if .displayTier > 0
        # draw text grid text and lines
        Select outer viewport: layout_left, layout_right,
        ... layout_plot_top, layout_image_bottom
        selectObject: .refTier
        .textGridFontCommand$ = .textGridFont$[.textGridFont]
        '.textGridFontCommand$'
        Font size: 12
        Draw: .minT, .maxT, .showBoundaries, "yes", "no"
        '.fontCommand$'
        Font size: 12
        Line width: 1
        Draw inner box
    endif

    # Label elapsed time from zero; the plotted data retains its original time coordinates.
    Axes: 0, .maxT-.minT, 1, 0

    # Draw time axis
    @niceTimeInterval: .maxT - .minT
    Marks bottom every: 1, niceTimeInterval.major, "yes", "yes", "no"
    Line width: 1
    Marks bottom every: 1, niceTimeInterval.minor, "no", "yes", "no"
    Text bottom: "yes", "Time (secs)"

    if .plotType = 1 or .plotType = 2
        @pitch: .sound, .minF0, .maxF0
    endif
    if .plotType = 1
        # The secondary-parameter plot needs a table; the F0 line uses the Pitch object.
        @pitch2Table: pitch.obj, 0
        selectObject: pitch2Table.table
        Rename: "pitch"
    endif

    if .plotType = 1
        # get second VQ table
        .secondParam$[1] = "cpp"
        .secondParam$[2] = "intensity"
        .secondParam$[3] = "h1h2"
        .secondParam$[4] = "harmonicity"
        .name$ = .secondParam$[.param2]
        if .param2 = 1
            @cpp: .sound, .minF0, .maxF0, pitch2Table.table
        elsif .param2 = 2
            @intensity: .sound, .minF0, .minT, .maxT
        elsif .param2 = 3
            @h1h2: .sound, pitch2Table.table
            selectObject: h1h2.table
            # Reverse H1-H2 so lower values produce larger, more intensely coloured points.
            Formula: "value", "-self"
        elsif .param2 = 4
            @harmonicity: .sound, .minF0
        endif
        .vqTable = '.name$'.table
    else
        .vqTable = 0
    endif

    # draw selected contour
    if .plotType = 1
        @drawPitchPlus: pitch2Table.table, .vqTable, .minT, .maxT, .minF0,
        ... .maxF0, .param2, .hz_ST
    elsif .plotType = 2
        if .pitch_two
            @draw_f0_line: .hz_ST, .minT, .maxT, .minF0, .maxF0,
            ... pitch.obj, .smoothing, "Silver"
            @uninterpolate: .sound, .pitch_two, .minF0, .maxF0
            @draw_f0_line: .hz_ST, .minT, .maxT, .minF0, .maxF0,
            ... uninterpolate.obj, .smoothing, "Blue"
            removeObject: uninterpolate.obj
        else
            @draw_f0_line: .hz_ST, .minT, .maxT, .minF0, .maxF0,
            ... pitch.obj, .smoothing, "Blue"
        endif
    elsif .plotType = 3
        @drawIntensity: .sound, .minT, .maxT, .minF0, .mindB, .maxdB
    endif

    # Drawing procedures set their own font size; restore the axis size.
    Font size: 12

    # add contour axis information
    if .plotType = 1 or .plotType = 2
        Select outer viewport: layout_left, layout_right, layout_plot_top, layout_plot_bottom
        if .hz_ST = 2
            .leftMajor = 5
            .leftText$ = "F0 (ST re 1 Hz)"
            Axes: .minT, .maxT, log2(.minF0) * 12, log2(.maxF0) * 12
        else
            .leftMajor = 50
            .leftText$ = "F0 (Hz)"
        endif
        Line width: 2
        Marks left every: 1, .leftMajor, "yes", "yes", "no"
        Line width: 1
        Marks left every: 1, .leftMajor / 5, "no", "yes", "no"
        Text left: "yes", .leftText$
    elsif .plotType = 3
        Select outer viewport: layout_left, layout_right, layout_plot_top, layout_plot_bottom
        Line width: 2
        Marks left every: 1, 10, "yes", "yes", "no"
        Line width: 1
        Marks left every: 1, 2, "no", "yes", "no"
        Text left: "yes", "Intensity (dB)"
    endif

    # add title
    Select outer viewport: layout_left, layout_right, 0, layout_title_bottom

    Font size: 16
    nowarn Text top: "yes", "##" + .title$
    Font size: 12
    Select outer viewport: layout_left, layout_right, 0, layout_image_bottom

    if .plotType = 1 or .plotType = 2
        selectObject: pitch.obj
        if .plotType = 1
            plusObject: pitch2Table.table
        endif
        if .vqTable
            plusObject: .vqTable
        endif
        if .displayTier > 0
            plusObject: .refTier
        endif
        Remove
    elsif .displayTier > 0
        selectObject: .refTier
        Remove
    endif
endproc

procedure drawPitchPlus: .pitchTable, .secondParam, .minT, .maxT, .minF0,
    ... .maxF0, .type, .hz_ST
    selectObject: .pitchTable
    # adjust F0 if pitch scale set to semitones
    if .hz_ST = 2
        Formula: "F0", "log2(self)*12"
        .minF0 = log2(.minF0) * 12
        .maxF0 = log2(.maxF0) * 12
    endif

    # Higher parameter values yield lower shade values and larger, more saturated circles.
    selectObject: .secondParam
    .numSecondPts = Get number of rows
    if .numSecondPts = 0
        exitScript: "The selected secondary parameter has no usable values."
    endif
    .definedValues = 0
    for .i to .numSecondPts
        .value = Get value: .i, "value"
        if .value <> undefined
            if .definedValues = 0
                .minPar2 = .value
                .maxPar2 = .value
            else
                .minPar2 = min(.minPar2, .value)
                .maxPar2 = max(.maxPar2, .value)
            endif
            .definedValues += 1
        endif
    endfor
    if .definedValues = 0
        exitScript: "The selected secondary parameter has no defined values."
    endif
    Append column: "shade"
    if .maxPar2 = .minPar2
        Formula: "shade", "if self[""value""] = undefined then undefined else 0.5 fi"
    else
        Formula: "shade", "1 - (self[""value""] - .minPar2) / (.maxPar2 - .minPar2)"
    endif

    # Binary search is safe for strictly increasing times; retain the general search otherwise.
    .orderedTimes = 1
    for .i to .numSecondPts
        .secondTime[.i] = Get value: .i, "time"
        if .secondTime[.i] = undefined
            .orderedTimes = 0
        elsif .i > 1
            if .secondTime[.i] <= .secondTime[.i - 1]
                .orderedTimes = 0
            endif
        endif
    endfor

    # set picture window
    Select outer viewport: layout_left, layout_right, layout_plot_top, layout_plot_bottom
    Axes: .minT, .maxT, .minF0, .maxF0
    .di = Horizontal mm to world coordinates: 3
    Font size: 12
    Solid line

    # Draw PitchPlus points
    selectObject: .pitchTable
    .numPitchPts = Get number of rows
    Colour: "Black"
    for .i to .numPitchPts
        selectObject: .pitchTable
        .curT = Get value: .i, "Time"
        .curF0 = Get value: .i, "F0"
        if .orderedTimes and .numSecondPts > 0 and .curT <> undefined
            .low = 1
            .high = .numSecondPts + 1
            while .low < .high
                .mid = floor((.low + .high) / 2)
                if .secondTime[.mid] < .curT
                    .low = .mid + 1
                else
                    .high = .mid
                endif
            endwhile
            .nearest = min(.low, .numSecondPts)
            if .nearest > 1
                if abs(.curT - .secondTime[.nearest - 1]) <= abs(.curT - .secondTime[.nearest])
                    .nearest = .nearest - 1
                endif
            endif
            selectObject: .secondParam
        else
            @nearestVal: .curT, .secondParam, "time"
            .nearest = nearestVal.index
        endif
        .sh = Get value: .nearest, "shade"
        .shT = Get value: .nearest, "time"
        # A match more than 5.5555 ms away is shown as a small red point.
        if .sh <> undefined and .shT <> undefined and
        ... abs(.shT - .curT)*1000 <= 5.5555
            Paint circle: "{'.sh','.sh',1-0.8*'.sh'}", .curT, .curF0,
            ... .di * 0.1 + .di * (1 - .sh)
            Colour: "cyan"
            Line width: 0.5
            Draw circle: .curT, .curF0, .di * 0.1 + .di * (1 - .sh)
        else
            Paint circle: "{1,0,0}", .curT, .curF0, .di * 0.1
            Line width: 0.5
        endif
        Line width: 1
        Colour: "Black"
    endfor
endproc

procedure drawIntensity: .sound, .minT, .maxT, .minF0, .mindB, .maxdB
    selectObject: .sound
    .intensity = To Intensity: .minF0, 0, "yes"

    # set picture window
    Select outer viewport: layout_left, layout_right, layout_plot_top, layout_plot_bottom
    Axes: .minT, .maxT, .mindB, .maxdB

    Font size: 12
    Solid line
    Line width: 7
    Black
    Draw: .minT, .maxT, .mindB, .maxdB, "no"
    Line width: 4
    Green
    Draw: .minT, .maxT, .mindB, .maxdB, "no"
    Line width: 1

    removeObject: .intensity
endproc

# PARAMETER EXTRACTION FUNCTIONS
procedure pitch: .sound, .minF0, .maxF0
    selectObject: .sound
    .obj = To Pitch (ac):
    ... 0, .minF0, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, .maxF0
endproc

procedure h1h2: .sound, .pitchTable
    # PROCESS SOUND WAVEFORM
    # Get sampling data from sound object
    selectObject: .sound
    .sampHz = Get sampling frequency
    .coeffs = round (.sampHz/1000) + 2
    # get LPC, IF sound waveform, and IF waveform narrowband spectrogram
    selectObject: .sound
    .lpc = To LPC (autocorrelation): .coeffs, 0.025, 0.005, 50
    plusObject: .sound
    .if = Filter (inverse)
    .ifSpectro = To Spectrogram: 0.03, 5000, 0.002, 20, "Gaussian"

    # PROCESS PITCH TABLE
    # convert pitch to pitch table if necessary
    selectObject: .pitchTable
    .isPitchObj = index(selected$(), "Pitch")
    if .isPitchObj
        .pitchTier = Down to PitchTier
        .pitchToR = Down to TableOfReal: "Hertz"
        .pitchTable = To Table: "rowLabel"
        selectObject: .pitchTier
        plusObject: .pitchToR
        Remove
        selectObject: .pitchTable
        Remove column: "rowLabel"
    endif
    Remove column: "Frame"
    .table = Copy: "H1H2"
    .numRows = Get number of rows
    Set column label (index): 1, "time"
    Append column: "value"
    # get array of F0 and time points
    for .i to .numRows
        .f0[.i] = Get value: .i, "F0"
        .time[.i] = Get value: .i, "time"
    endfor
    Remove column: "F0"

    # PROCESS H1-H2
    # get h1-h2 array
    for .i to .numRows
        selectObject: .ifSpectro
        .slice = To Spectrum (slice): .time[.i]
        .h1 = Get sound pressure level of nearest maximum: .f0[.i]
        .h2 = Get sound pressure level of nearest maximum: .f0[.i] * 2
        Remove
        .h1h2$ = fixed$(.h1 - .h2, 3)
        selectObject: .table
        Set string value: .i, "value", .h1h2$
    endfor

    .mean = Get mean: "value"
    .stDev = Get standard deviation: "value"

    # remove statistical outliers
    @delRowsIf: .table, "self[""value""] < h1h2.mean - h1h2.stDev * 3"
    @delRowsIf: .table, "self[""value""] > h1h2.mean + h1h2.stDev * 3"

    ### Remove surplus objects:
    selectObject: .lpc
    plusObject: .if
    plusObject: .ifSpectro
    if .isPitchObj
        plusObject: .pitchTable
    endif
    Remove
endproc

procedure getHn: .ifSpectro, .hn, .time, .f0
    selectObject: .ifSpectro
    .slice = To Spectrum (slice): .time
    .db = Get sound pressure level of nearest maximum: .f0 * .hn
    Remove
endproc

procedure harmonicity: .sound, .minF0
    # Procedure dependencies: @array2table (@list2array), @delRowsIf

    # Create the harmonicity object.
    selectObject: .sound
    .harmonicity = To Harmonicity (ac): 0.01, .minF0, 0.1, 4.5
    #get main stats for harmonicity table
    .mean =Get mean: 0, 0
    .stDev = Get standard deviation: 0, 0
    .frames = Get number of frames

    # create array of harmonicity values
    for .i to .frames
       time[.i] = Get time from frame number: .i
       value[.i] = Get value in frame: .i
    endfor
    #  create harmonicity table
    @array2table: "harmonicity", "time value", .frames
    .table = array2table.table
    .minimum = Get minimum: "value"
    @delRowsIf: .table, "self[""value""] = harmonicity.minimum"
    @delRowsIf: .table,
    ... "self[""value""] < harmonicity.mean - harmonicity.stDev * 1"
    selectObject: .harmonicity
    Remove
endproc

procedure intensity: .sound, .minF0, .minT, .maxT
    # Procedure dependencies: @delRowsIf, @tableStats (@keepCols, @table2array)

    # Convert intensity frames into a time/value table.
    selectObject: .sound
    .tempI1 = To Intensity: 75, 0, "yes"
    .tempI2 = Down to IntensityTier
    .tempI3 = Down to TableOfReal
    .tempI4 = To Table: "delete"
    Remove column: "delete"
    Set column label (index): 1, "time"
    Set column label (index): 2, "value"
    selectObject: .tempI1
    plusObject: .tempI2
    plusObject: .tempI3
    Remove

    .table = .tempI4
    selectObject: .table
    .mean = Get mean: "value"
    .stDev = Get standard deviation: "value"
    @delRowsIf: .table, "self[""value""] < intensity.mean - intensity.stDev"


    # Fit the intensity trend within the selected time range after filtering low values.
    .tempTable = Copy: "intensityTemp"
    @delRowsIf: .tempTable, "self[""time""] <= intensity.minT"
    @delRowsIf: .tempTable, "self[""time""] >= intensity.maxT"
    @tableStats: .tempTable, "time", "value"

    selectObject: .tempTable
    @delRowsIf: .table,
    ... "self [""value""] < tableStats.yMean - tableStats.stDevY"
    selectObject: .tempTable
    Remove

    # Subtract the fitted trend to obtain intensity residuals.
    selectObject: .table
    Formula: "value",
    ... "self[""value""] - (self[""time""] * " +
    ... "tableStats.slope + tableStats.intercept)"
endproc

procedure cpp: .sound, .minF0, .maxF0, .pitchTable
    # Procedure dependencies:  @delRowsIf
    selectObject: .sound
    .powerCepstrogram = To PowerCepstrogram: .minF0, 0.002, 5000, 50

    selectObject: .pitchTable
    .table = Copy: "CPP"
    .numRows = Get number of rows
    Set column label (index): 2, "time"

    for .i to .numRows
        .time[.i] = Get value: .i, "time"
        .f0[.i] = Get value: .i, "F0"
    endfor

    for .i to .numRows
        selectObject: .powerCepstrogram
        .powerCepstralSlice = To PowerCepstrum (slice): .time[.i]
        .cpp[.i] = Get peak prominence:
        ... .minF0, .maxF0, "Parabolic", 0.001, 0, "Straight", "Robust"
        Remove
    endfor

    selectObject: .table
    Append column: "value"
    for .i to .numRows
        Set numeric value: .i, "value", .cpp[.i]
    endfor
    .mean = Get mean: "value"
    .stDev = Get standard deviation: "value"
    @delRowsIf: .table, "self [""value""] < cpp.mean - cpp.stDev * 2"

    selectObject: .powerCepstrogram
    Remove
endproc

# OBJECT MANAGEMENT FUNCTIONS
procedure array2table: .table$, .arrays$, .rows
    # Procedure dependencies: @list2array

    # convert array list to indexed string list
    @list2array: .arrays$, "list2array.arrayList$"

    # simplify array/column names
    .cols = list2array.n
    for .j to .cols
        .cols$[.j] = list2array.arrayList$[.j]
        if right$(.cols$[.j], 1) = "$"
            .string[.j] = 1
        else
            .string[.j] = 0
        endif
    endfor

    # create empty table
    .table = Create Table with column names: .table$, .rows, .arrays$

    # populate table
    for .i to .rows
        for .j to .cols
            .curCol$ =  .cols$[.j]
            if .string[.j]
                Set string value: .i, .curCol$, '.curCol$'[.i]
            else
                Set numeric value: .i, .curCol$, '.curCol$'[.i]
            endif
        endfor
    endfor
endproc

procedure table2array: .table, .col$, .array$
    # Procedure dependencies: none

    .string = right$(.array$, 1) = "$"
    selectObject: .table
    .n = Get number of rows
    for .i to .n
        if .string
            .cur_val$ = Get value: .i, .col$
            '.array$'[.i] = .cur_val$
        else
            .cur_val = Get value: .i, .col$
            '.array$'[.i] = .cur_val
        endif
    endfor
endproc

procedure list2array: .list$, .array$
    # Procedure dependencies: none

    .list_len = length(.list$)
    .n = 1
    .prev_start = 1
    for .i to .list_len
        .char$ = mid$(.list$, .i, 1)
        if .char$ = " "
            '.array$'[.n] = mid$(.list$, .prev_start, .i - .prev_start)
            .origIndex[.n] = .prev_start
            .n += 1
            .prev_start = .i + 1
        endif
    endfor
    if .n = 1
        '.array$'[.n] = .list$
    else
        '.array$'[.n] = mid$(.list$, .prev_start, .list_len - .prev_start + 1)
    endif
    .origIndex[.n] = .prev_start
endproc

procedure pitch2Table: .pitchObject, .interpolate
    # Procedure dependencies: none
    selectObject: .pitchObject
    .originalObject = .pitchObject
    if .interpolate
        .pitchObject = Interpolate
    endif

    # Get key pitch data
    .timeStep = Get time step
    .frameTimeFirst = Get time from frame number: 1

    #create pitch Table (remove temp objects)
    .pitchTier = Down to PitchTier
    .tableofReal = Down to TableOfReal: "Hertz"
    .pitchTable = To Table: "rowLabel"
    selectObject: .pitchTier
    plusObject: .tableofReal
    Remove

    # Get key pitchTable data
    selectObject: .pitchTable
    .rows = Get number of rows
    # Map each voiced pitch point back to its original frame.
    Set column label (index): 1, "Frame"
    for .n to .rows
        .rowTimeN = Get value: .n, "Time"
        .tableFrameN = round((.rowTimeN - .frameTimeFirst) / .timeStep + 1)
        Set numeric value: .n, "Frame", .tableFrameN
    endfor

    #removeInterpolated pitch
    if  .originalObject != .pitchObject
        selectObject: .pitchObject
        Remove
    endif
    .table = .pitchTable
endproc

procedure nearestVal: .input_val, .input_table, .input_col$
    # Procedure dependencies: none

    .diff = 1e+100
    selectObject: .input_table
    .num_rows = Get number of rows
    for .i to .num_rows
        .val_cur = Get value: .i, .input_col$
        .diff_cur = abs(.input_val - .val_cur)
        if .diff_cur < .diff
            .diff = .diff_cur
            .val = .val_cur
            .index = .i
        endif
    endfor
endproc

procedure delRowsIf: .table, .cond$
    # Procedure dependencies: none

    selectObject: .table
    .num_rows = Get number of rows
    Append column: "del"
    Formula: "del", "if " +.cond$ + " then 1 else 0 endif"
    for .i to .num_rows
        .cur_row = .num_rows + 1 - .i
        .cur_value = Get value: .cur_row, "del"
        if .cur_value
            Remove row: .cur_row
        endif
    endfor
    Remove column: "del"
endproc

procedure keepCols: .table, .keep_cols$, .new_table$
    # Procedure dependencies: @list2array
    @list2array: .keep_cols$, ".keep$"
    selectObject: .table
    '.new_table$' = Copy: .new_table$
    .num_cols = Get number of columns
    for .i to .num_cols
        .col_cur = .num_cols + 1 - .i
        .label_cur$ = Get column label: .col_cur
        .keep_me = 0
        for .j to list2array.n
            if .label_cur$ = list2array.keep$[.j]
                .keep_me = 1
            endif
        endfor
        if .keep_me = 0
            Remove column: .label_cur$
        endif
    endfor
endproc

procedure tableStats: .table, .colX$, .colY$
    # Procedure dependencies: @keepCols, @table2array

    @keepCols: .table, "'.colX$' '.colY$'", "tableStats.shortTable"

    .numRows = Get number of rows
    .factor$ = Get column label: 1
    if .colX$ != .factor$
        @table2array: .shortTable, .colY$, "tableStats.colTemp$"
        Remove column: .colY$
        Append column: .colY$
        for .i to table2array.n
            Set string value: .i, .colY$, .colTemp$[.i]
        endfor
    endif

    if .numRows > 1
        .stDevY = Get standard deviation: .colY$
        .stDevY = number(fixed$(.stDevY, 3))
        .stDevX = Get standard deviation: .colX$
        .linear_regression = To linear regression
        .linear_regression$ = Info
        .slope = extractNumber
        ...  (.linear_regression$, "Coefficient of factor '.colX$': ")
        .slope = number(fixed$(.slope, 3))
        .intercept = extractNumber (.linear_regression$, "Intercept: ")
        .intercept = number(fixed$(.intercept, 3))
        .r = number(fixed$(.slope * .stDevX / .stDevY, 3))
        selectObject: .linear_regression
        .info$ = Info
        Remove
    else
        .stDevY = undefined
        .stDevX = undefined
        .linear_regression = undefined
        .linear_regression$ = "N/A"
        .slope = undefined
        .intercept = Get value: 1, .colY$
        .r = undefined
        .info$ = "N/A"
    endif

    selectObject: .shortTable
    .xMean = Get mean: .colX$
    .xMed = Get quantile: .colX$, 0.5
    .yMean = Get mean: .colY$
    .yMed = Get quantile: .colY$, 0.5
    Remove
endproc

procedure draw_f0_line: .hz_ST, .minT, .maxT, .minF0, .maxF0,
    ... .pitch_two, .smoothing, .colour$
    Solid line
    if .hz_ST = 2
        .line_minF0 = log2(.minF0/100) * 12
        .line_maxF0 = log2(.maxF0/100) * 12
    else
        .line_minF0 = .minF0
        .line_maxF0 = .maxF0
    endif

    Select outer viewport: layout_left, layout_right, layout_plot_top, layout_plot_bottom
    Axes: .minT, .maxT, .line_minF0, .line_maxF0
    if .pitch_two
        .foreground_pitch = .pitch_two
    else
         .foreground_pitch = pitch.obj
    endif
    White
    Line width: 9
    selectObject: .foreground_pitch
    .smooth_pitch = Smooth: .smoothing
    if .hz_ST = 1
        Draw: .minT, .maxT, .line_minF0, .line_maxF0, "no"
        '.colour$'
        Line width: 7
        Draw: .minT, .maxT, .line_minF0, .line_maxF0, "no"
    else
        Draw semitones (re 100 Hz):
        ... .minT, .maxT, .line_minF0, .line_maxF0, "no"
        '.colour$'
        Line width: 7
        Draw: .minT, .maxT, .line_minF0, .line_maxF0, "no"
        Draw semitones (re 100 Hz):
        ... .minT, .maxT, .line_minF0, .line_maxF0, "no"
    endif
    Solid line
    Black
    Line width: 1
    # Remove smoothed pitch object
    Remove
endproc

procedure uninterpolate: .sound, .pitch_obj, .minF0, .maxF0
    # Identify voiceless intervals from the sound and remove them from the supplied pitch.
    selectObject: .sound
    .point_process = To PointProcess (periodic, cc): .minF0, .maxF0
    .vuv_grid = To TextGrid (vuv): 0.02, 0.01
    .vuv_table = Down to Table: "no", 6, "no", "no"
    .num_rows = Get number of rows

   selectObject: .pitch_obj
   .obj = Copy: "uninterpolated"
   Edit

   for .i to .num_rows
       selectObject: .vuv_table
       .cur_vuv$ = Get value: .i, "text"
       if (.cur_vuv$ == "U")
           .tmin = Get value: .i, "tmin"
           .tmax = Get value: .i, "tmax"
           selectObject: .obj
           editor: .obj
               Move cursor to: .tmin
               Move end of selection by: .tmax - .tmin
               Unvoice
           endeditor
       endif
   endfor
   removeObject: {.point_process, .vuv_grid, .vuv_table}
endproc

include _genFnBank.praat
include _ui_common.praat
include _praat_pitch_ui.praat
include _windows_pitch_ui.praat
include _form_pitch_ui.praat
