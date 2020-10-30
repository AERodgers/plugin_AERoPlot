
# C3POGRAM   V.1.2.0
# ==================
# Written for Praat 6.0.40 or later
#
# This version is included as a feature of the AERoplot plugin.
#
# script by Antoin Eoin Rodgers
#
# | email   | rodgeran@tcd.ie
# | twitter | @phonetic_antoin
# | github  | github.com/AERodgers
#
# Phonetics and speech Laboratory, Trinity College Dublin
# October 19, 2019

### C3POGRAM
    # This script draws a pitch contour with a spectrogram and single textgrid reference tier (if
    # grid and tier are specified). A secondary parameter determines the size and and intensity of
    # the pitch contour points. Cut-off  points are built into the functions, below or above which
    # the F0 contour is shown with a red dot. (NB: For H1-H2, lower values are indicated by larger
    # circles and more intense colour.)
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


#Get sound and textgrid data
sound = selected("Sound")
grid = 0
tier = 0
if size(selected#()) = 2
    grid = selected("TextGrid")
endif

beginPause: "c3pogram"
    sentence: "Image title", ""

    comment: "Enter number of textgrid tier for display " +
    ... "(also sets min and max time of output display)"
    if grid
        natural: "tier", "1"
    endif
    boolean: "Paint_spectrogram", 1
    natural: "Window_width", 8
    comment: "Enter parameter settings"
    natural: "minF0", 60
    natural: "maxF0", 400
    real: "mindB", 30
    real: "maxdB", 90
    choice: "Scale", 2
        option: "Hertz"
        option: "Semitones re 1 Hz"
        option: "Intensity"
    choice: "Parameter_two", 1
        option: "Cepstral Peak Prominence"
        option: "Residual of intensity (linear regression)"
        option: "H1-H2 of differentiated glottal pulse (LPC-IF)"
        option: "Harmonicity (Praat function)"
    comment: "CPP appears to reflect more intuitive expectations of contour."
    comment: "Residual of linear regression of intensity used to " +
         ... "compensate for global declination."
    comment: "H1-H2 estimation is very basic. It also emphasises very " +
          ..."tense / creaky stretches"
    comment: "Harmonicity seems to reflects spectral balance " +
         ... "(higher values for approximants, nasals)"
 myChoice = endPause: "Exit", "Apply", 2, 1
 # respond to myChoice
 if myChoice = 1
     exit
 endif

title$ = image_title$

@c3pogram: parameter_two, scale, paint_spectrogram, title$, grid, sound, tier,
    ... minF0, maxF0, mindB, maxdB, window_width

# C3POGRAM FUNCTIONS
procedure c3pogram: .param2, .hz_ST, .paintSpect, .title$, .grid, .sound,
    ...  .tier, .minF0, .maxF0, .mindB, .maxdB, .vpWidth

    # adjust sound intensity
    selectObject: .sound
    Scale intensity: 70

    if .grid * .tier > 0
        selectObject: .grid
        .refTier = Extract one tier: .tier
        .gridTable = Down to Table: "no", 3, "no", "no"
        .num_rows = Get number of rows
        .minT = Get value: 1, "tmin"
        .maxT = Get value: .num_rows, "tmax"
        Remove
    else
        selectObject: .sound
        .minT = Get start time
        .maxT = Get end time
    endif

    # reset draw space
    Erase all
    Black
    10
    Solid line
    Courier
    Select outer viewport: 0, .vpWidth, 0, 3.35

    # draw spectrogram
    if .paintSpect
        selectObject: .sound
        specky = To Spectrogram: 0.005, 5000, 0.002, 20, "Gaussian"
        Paint: .minT, .maxT, 0, 0, 100, "yes", 50, .vpWidth, 0, "no"
        Marks right every: 1, 200, "no", "yes", "no"
        Line width: 2
        Marks right every: 1000, 1, "yes", "yes", "no"
        Text right: "yes", "Spectral Frequency (kHz)"
        Remove
    endif
    Line width: 1
    Draw inner box

    if .grid * .tier > 0
        # draw text grid text and lines
        Select outer viewport: 0, .vpWidth, 0, 4
        selectObject: .refTier
        Draw: .minT, .maxT, "no", "yes", "no"
        Line width: 1
        Draw inner box
    endif

    # Adjust time to start from 0
    Axes: 0, .maxT-.minT, 1, 0

    # Draw time axis
    Marks bottom every: 1, 0.2, "yes", "yes", "no"
    Line width: 1
    Marks bottom every: 1, 0.1, "no", "yes", "no"
    Text bottom: "yes", "Time (secs)"

    # get pitch table
    @pitch: .sound, .minF0, .maxF0
    @pitch2Table: pitch.obj, 0
    selectObject: pitch2Table.table
    Rename: "pitch"

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
        Formula: "value", "-self"
    else
        @harmonicity: .sound, .minF0
    endif
    .vqTable = '.name$'.table


    # draw cp3ogram
    #intensity hack
    if .hz_ST != 3
        @drawC3Pogram: pitch2Table.table, .vqTable, .minT, .maxT, .minF0,
        ... .maxF0, .param2, .hz_ST, .vpWidth
    else
        @drawIntensity: .sound, .minT, .maxT, .minF0, .mindB, .maxdB, .vpWidth
    endif

    # add pitch axis information
    Select outer viewport: 0, .vpWidth, 0, 3.35
    if .hz_ST = 2
        .leftMajor = 5
        .leftText$ = "F0 (ST re 1 Hz)"
    else
        .leftMajor = 50
        .leftText$ = "F0 (Hz)"
    endif
    if .hz_ST < 3
        Line width: 2
        Marks left every: 1, .leftMajor, "yes", "yes", "no"
        Line width: 1
        Marks left every: 1, .leftMajor / 5, "no", "yes", "no"
        Text left: "yes", .leftText$
    else
        Line width: 2
        Marks left every: 1, 10, "yes", "yes", "no"
        Line width: 1
        Marks left every: 1, 2, "no", "yes", "no"
        Text left: "yes", "Intensity (dB)"
    endif

    # add title
    if .grid * .tier > 0
        Select outer viewport: 0, .vpWidth, 0, 4
    else
        Select outer viewport: 0, .vpWidth, 0, 3.35
    endif

    Font size: 14
    nowarn Text top: "yes", "##" + .title$
    Font size: 10

    selectObject: .vqTable
    plusObject: pitch2Table.table
    plusObject: pitch.obj
    if .grid * .tier > 0
        plusObject: .refTier
    endif
    Remove
endproc

procedure drawC3Pogram: .pitchTable, .secondParam, .minT, .maxT, .minF0,
    ... .maxF0, .type, .hz_ST, .vpWidth
    selectObject: .pitchTable
    # adjust F0 if pitch scale set to semitones
    if .hz_ST = 2
        Formula: "F0", "log2(self)*12"
        .minF0 = log2(.minF0) * 12
        .maxF0 = log2(.maxF0) * 12
    endif

    # Convert second parameter to shading values
    selectObject: .secondParam
    .minPar2  = Get minimum: "value"
    .maxPar2 = Get maximum: "value"
    Append column: "shade"
    Formula: "shade", "1 - (self[""value""] - .minPar2) / (.maxPar2 - .minPar2)"

    # set picture window
    Select outer viewport: 0, .vpWidth, 0, 3.35
    Axes: .minT, .maxT, .minF0, .maxF0
    .di = Horizontal mm to world coordinates: 0.9
    Font size: 10
    Courier
    Solid line

    # Draw C3POGRAM points
    selectObject: .pitchTable
    .numPitchPts = Get number of rows
    Colour: "Black"
    for .i to .numPitchPts
        selectObject: .pitchTable
        .curT = Get value: .i, "Time"
        .curF0 = Get value: .i, "F0"
        @nearestVal: .curT, .secondParam, "time"
        .sh = Get value: nearestVal.index, "shade"
        .shT = Get value: nearestVal.index, "time"
        if not(abs(.shT - .curT)*1000 > 5.5555)
            Paint circle: "{'.sh','.sh',1-0.8*'.sh'}", .curT, .curF0,
            ... .di * 0.1 + .di * (1 - .sh)
            Colour: "blue"
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


procedure drawIntensity: .sound, .minT, .maxT, .minF0, .mindB, .maxdB, .vpWidth
    selectObject: .sound
    .intensity = To Intensity: .minF0, 0, "yes"

    # set picture window
    Select outer viewport: 0, .vpWidth, 0, 3.35
    Axes: .minT, .maxT, .mindB, .maxdB

    Font size: 10
    Courier
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
    # Procedure dependencies @getHn

    # PROCESS SOUND WAVEFORM
    # Get sampling data from sound object
    selectObject: .sound
    .sampHz = Get sampling frequency
    .coeffs = round (.sampHz/1000) + 2
    # create spectrogram of original sound (delete later)
    .soundSpectro = To Spectrogram: 0.03, 5000, 0.002, 20, "Gaussian"
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
        @getHn: .ifSpectro, 1, .time[.i], .f0[.i]
        .h1 = getHn.db
        @getHn: .ifSpectro, 2, .time[.i], .f0[.i]
        .h1h2$ = fixed$(.h1 - getHn.db, 3)
        selectObject: .table
        Set string value: .i, "value", .h1h2$
    endfor

    .mean = Get mean: "value"
    .stDev = Get standard deviation: "value"

    # remove statistical outliers
    @delRowsIf: .table, "self[""value""] < h1h2.mean - h1h2.stDev * 3"
    @delRowsIf: .table, "self[""value""] > h1h2.mean + h1h2.stDev * 3"

    ### Remove surplus objects:
    selectObject: .soundSpectro
    plusObject: .lpc
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

    # create harmonicity object
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
    @delRowsIf: .table, "self[""value""] < harmonicity.mean - harmonicity.stDev * 1"
    selectObject: .harmonicity
    Remove
endproc

procedure intensity: .sound, .minF0, .minT, .maxT
    # Procedure dependencies: @delRowsIf, @tableStats (@keepCols, @table2array)

    # create harmonicity object
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


    # get linear regression of intensity for utterance portion of waveform
    .tempTable = Copy: "intensityTemp"
    @delRowsIf: .tempTable, "self[""time""] <= intensity.minT"
    @delRowsIf: .tempTable, "self[""time""] >= intensity.maxT"
    @tableStats: .tempTable, "time", "value"

    selectObject: .tempTable
    @delRowsIf: .table, "self [""value""] < tableStats.yMean - tableStats.stDevY"
    .mean = Get mean: "value"
    .stDev = Get standard deviation: "value"
    selectObject: .tempTable
    Remove

    selectObject: .table
    Formula: "value", "self[""value""] - (self[""time""] * tableStats.slope + tableStats.intercept)"
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
        .cpp[.i] = Get peak prominence: .minF0, .maxF0, "Parabolic", 0.001, 0, "Straight", "Robust"
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
    .frameTimeFirst = Get time from frame number: 1
    .timeStep = Get time step

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
    .rowTimeFirst = Get value: 1, "Time"

    # estimate frame of first row
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
        .slope = extractNumber (.linear_regression$, "Coefficient of factor '.colX$': ")
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
