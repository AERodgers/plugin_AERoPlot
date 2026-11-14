# AERoPlot interface-independent helpers
# ======================================
# Used by every interface (Praat pause windows, command-line forms, Windows UI).
# These procedures collect no input and draw no windows; they only interpret
# and check what an interface hands back.

# "Off" values for optional text fields: blank, none or null (any capitals).
procedure isOffValue: .text$
    .text$ = replace_regex$(.text$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0)
    .lower$ = replace_regex$(.text$, ".*", "\L&", 1)
    .off = (.lower$ = "" or .lower$ = "none" or .lower$ = "null")
endproc

# Saved interface preference ("praat" or "windows") and what is really usable.
# The Windows interface is only used when it is chosen AND available here.
procedure getUIMode
    .file$ = preferencesDirectory$ + "/plugin_AERoPlot/data/vars/ui_mode.txt"
    .preference$ = "windows"
    .reason$ = ""
    .hasSavedPreference = fileReadable(.file$)
    if fileReadable(.file$)
        .saved$ = readFile$(.file$)
        .saved$ = lowerCase$(replace_regex$(.saved$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0))
        if .saved$ = "praat"
            .preference$ = "praat"
        endif
    endif
    .mode$ = "praat"
    if .preference$ = "windows"
        @windowsUIAvailable
        .reason$ = windowsUIAvailable.reason$
        if windowsUIAvailable.ok
            .mode$ = "windows"
        elsif environment$("OS") = "Windows_NT" and
        ... (.hasSavedPreference or windowsUIAvailable.helperMissing)
            .reason$ = windowsUIAvailable.reason$
            @showUIModeMessage: "The Windows interface is unavailable. " +
            ... .reason$ + " AERoPlot will continue with the standard Praat interface. " +
            ... "This fallback will be remembered. After fixing the issue, choose Praat > AERoPlot > Use Windows interface to re-enable it."
            @setUIMode: "praat"
            .preference$ = "praat"
        endif
    endif
endproc

procedure windowsUIAvailable
    .isWindows = environment$("OS") = "Windows_NT"
    .major = 0
    .minor = 0
    .patch = 0
    .exe$ = preferencesDirectory$ +
    ... "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe"
    .helperPresent = 0
    if .isWindows
        @checkPraatVersion
        .major = checkPraatVersion.major
        .minor = checkPraatVersion.minor
        .patch = checkPraatVersion.patch
        .helperPresent = fileReadable(.exe$)
    endif
    @windowsUIRequirements: .isWindows, praatVersion$, .major, .minor, .patch,
    ... .exe$, .helperPresent
    .ok = windowsUIRequirements.ok
    .helperMissing = windowsUIRequirements.helperMissing
    .reason$ = windowsUIRequirements.reason$
endproc

procedure windowsUIRequirements: .isWindows, .version$, .major, .minor, .patch, .exe$, .helperPresent
    .ok = 0
    .helperMissing = 0
    .reason$ = ""
    if not .isWindows
        .reason$ = "The Windows interface is available only on Windows."
    else
        .recent = .major > 6 or
        ... (.major = 6 and (.minor > 4 or
        ... (.minor = 4 and .patch >= 60)))
        if not .recent
            .reason$ = "The Windows interface requires Praat 6.4.60 or newer; this installation is running Praat " +
            ... .version$ + ". Update Praat, or choose Use Praat interface."
        elsif not .helperPresent
            .helperMissing = 1
            .reason$ = "The Windows helper is missing from " + .exe$ +
            ... ". Reinstall the complete plug-in folder, including windows-ui/bin/AERoPlotWindowsUI.exe."
        else
            .ok = 1
        endif
    endif
endproc

procedure setUIMode: .mode$
    createFolder: preferencesDirectory$ + "/plugin_AERoPlot"
    createFolder: preferencesDirectory$ + "/plugin_AERoPlot/data"
    createFolder: preferencesDirectory$ + "/plugin_AERoPlot/data/vars"
    writeFile: preferencesDirectory$ + "/plugin_AERoPlot/data/vars/ui_mode.txt", .mode$
endproc

procedure showUIModeMessage: .text$
    if variableExists("aeroNonInteractive")
        appendInfoLine: .text$
    else
        beginPause: "AERoPlot interface"
            comment: .text$
        endPause: "OK", 1
    endif
endproc

# Find a TextGrid tier from a name or a number.
# A number is a tier position; anything else is a tier name. If a number is also
# the name of a different tier the entry is ambiguous and the user must rename.
# Returns .tier, .interval (1 for interval tiers) and .name$.
procedure resolveTierNumber: .textGrid, .reference$, .field$, .type$
    .error$ = ""
    .tier = 0
    .interval = 0
    .name$ = ""
    .reference$ = replace_regex$(.reference$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0)
    if .reference$ = ""
        .error$ = .field$ + ": enter a tier name or number."
    endif
    if .error$ = ""
        selectObject: .textGrid
        .count = Get number of tiers
        .nameMatch = 0
        .matches = 0
        for .i to .count
            .candidate$ = Get tier name: .i
            if .candidate$ = .reference$
                .nameMatch = .i
                .matches += 1
            endif
        endfor
        if .matches > 1
            .error$ = .field$ + ": multiple tiers are named """ + .reference$ + """. Give them unique names."
        endif
    endif
    if .error$ = ""
        .numberMatch = 0
        if index_regex(.reference$, "^[0-9]+$") != 0
            .number = number(.reference$)
            if .number >= 1 and .number <= .count
                .numberMatch = .number
            endif
        endif
        if .numberMatch and .nameMatch and .numberMatch != .nameMatch
            .error$ = .field$ + ": """ + .reference$ + """ refers to tier number " +
            ... string$(.numberMatch) + " and a different tier named """ + .reference$ +
            ... """. Please rename the numeric tier to avoid confusion."
        endif
    endif
    if .error$ = ""
        .tier = .numberMatch
        if not .tier
            .tier = .nameMatch
        endif
        if not .tier
            .error$ = .field$ + ": no tier matches """ + .reference$ + """. Enter an existing tier name or number."
        endif
    endif
    if .error$ = ""
        .interval = Is interval tier: .tier
        if .type$ = "interval" and not .interval
            .error$ = .field$ + ": """ + .reference$ + """ must identify an interval tier."
        elsif .type$ = "point" and .interval
            .error$ = .field$ + ": """ + .reference$ + """ must identify a point tier."
        endif
    endif
    if .error$ = ""
        .name$ = Get tier name: .tier
        if .name$ != ""
            .actualMatches = 0
            for .i to .count
                .candidate$ = Get tier name: .i
                if .candidate$ = .name$
                    .actualMatches += 1
                endif
            endfor
            if .actualMatches > 1
                .error$ = .field$ + ": multiple tiers are named """ + .name$ + """. Give them unique names."
            endif
        endif
    endif
    if .error$ = ""
        if index_regex(.name$, "^[0-9]+$") != 0
            appendInfoLine: "Warning: tier """ + .name$ + """ has a numeric name. Use a descriptive name to avoid confusion with tier numbers."
        endif
    else
        @settingError: .error$
    endif
endproc

# Report a problem with the user's settings. Normally the script stops with the
# message. When the caller has set aeroSoftErrors = 1 it is only recorded in
# the caller's .error$, so the caller can clean up and ask again.
procedure settingError: .message$
    .soft = 0
    if variableExists("aeroSoftErrors")
        .soft = aeroSoftErrors
    endif
    if not .soft
        exitScript: .message$
    endif
endproc

# As resolveTierNumber, for scripts that pass tier NAMES on (e.g. Create Table).
procedure resolveTierReference: .textGrid, .reference$, .field$, .type$
    @resolveTierNumber: .textGrid, .reference$, .field$, .type$
    .tier = resolveTierNumber.tier
    .interval = resolveTierNumber.interval
    .name$ = resolveTierNumber.name$
    .error$ = resolveTierNumber.error$
    if .error$ = "" and (.name$ = "" or index(.name$, ",") != 0)
        .error$ = .field$ + ": the selected tier needs a non-empty name without commas."
        @settingError: .error$
    endif
endproc

# Resolve Table column names or numbers held in the named variables.
# .vars$ is a comma-separated list of string variable names, e.g. "oFactor$,f1Col$".
# Each non-blank entry is replaced by the real column header. Entries that match
# nothing are left alone so the caller's existing "column missing" report applies.
# Returns .list$ (the resolved, non-blank headers) and .error$ (empty if fine).
procedure resolveColumnVariables: .table, .vars$
    .error$ = ""
    .list$ = ""
    selectObject: .table
    .count = Get number of columns
    for .i to .count
        .label$[.i] = Get column label: .i
    endfor
    @csvLine2Array: .vars$, "resolveColumnVariables.n", "resolveColumnVariables.var$"
    for .v to .n
        .name$ = .var$[.v]
        .value$ = '.name$'
        .value$ = replace_regex$(.value$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0)
        if .value$ != "" and .error$ = ""
            .nameMatch = 0
            for .i to .count
                if .nameMatch = 0 and .label$[.i] = .value$
                    .nameMatch = .i
                endif
            endfor
            .numberMatch = 0
            if index_regex(.value$, "^[0-9]+$") != 0
                .number = number(.value$)
                if .number >= 1 and .number <= .count
                    .numberMatch = .number
                endif
            endif
            if .numberMatch and .nameMatch and .numberMatch != .nameMatch
                .error$ = """" + .value$ + """ is both column number " +
                ... string$(.numberMatch) + " and the header of column " +
                ... string$(.nameMatch) + ". Please rename the numeric column to avoid confusion."
            else
                .column = .numberMatch
                if not .column
                    .column = .nameMatch
                endif
                if .column
                    .value$ = .label$[.column]
                    if .value$ = ""
                        .error$ = "Column " + string$(.column) + " has no header."
                    elsif index_regex(.value$, "^[0-9]+$") != 0
                        appendInfoLine: "Warning: column """ + .value$ + """ has a numeric header. Use a descriptive header to avoid confusion with column numbers."
                    endif
                endif
            endif
        endif
        '.name$' = .value$
        if .value$ != ""
            if .list$ != ""
                .list$ += ","
            endif
            .list$ += .value$
        endif
    endfor
endproc
