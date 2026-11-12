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
# The Windows interface is only used when it is chosen AND available here;
# otherwise the Praat interface is used silently.
procedure getUIMode
    .file$ = preferencesDirectory$ + "/plugin_AERoPlot/data/vars/ui_mode.txt"
    .preference$ = "praat"
    if fileReadable(.file$)
        .saved$ = readFile$(.file$)
        .saved$ = lowerCase$(replace_regex$(.saved$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0))
        if .saved$ = "windows"
            .preference$ = "windows"
        endif
    endif
    .mode$ = "praat"
    if .preference$ = "windows"
        @windowsUIAvailable
        if windowsUIAvailable.ok
            .mode$ = "windows"
        endif
    endif
endproc

procedure windowsUIAvailable
    .ok = 0
    if environment$("OS") = "Windows_NT"
        @checkPraatVersion
        .recent = checkPraatVersion.major > 6 or
        ... (checkPraatVersion.major = 6 and (checkPraatVersion.minor > 4 or
        ... (checkPraatVersion.minor = 4 and checkPraatVersion.patch >= 60)))
        if .recent and fileReadable(preferencesDirectory$ +
        ... "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe")
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
    .reference$ = replace_regex$(.reference$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0)
    if .reference$ = ""
        exitScript: .field$ + ": enter a tier name or number."
    endif
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
        exitScript: .field$ + ": multiple tiers are named """ + .reference$ + """. Give them unique names."
    endif
    .numberMatch = 0
    if index_regex(.reference$, "^[0-9]+$") != 0
        .number = number(.reference$)
        if .number >= 1 and .number <= .count
            .numberMatch = .number
        endif
    endif
    if .numberMatch and .nameMatch and .numberMatch != .nameMatch
        exitScript: .field$ + ": """ + .reference$ + """ refers to tier number " +
        ... string$(.numberMatch) + " and a different tier named """ + .reference$ +
        ... """. Please rename the numeric tier to avoid confusion."
    endif
    .tier = .numberMatch
    if not .tier
        .tier = .nameMatch
    endif
    if not .tier
        exitScript: .field$ + ": no tier matches """ + .reference$ + """. Enter an existing tier name or number."
    endif
    .interval = Is interval tier: .tier
    if .type$ = "interval" and not .interval
        exitScript: .field$ + ": """ + .reference$ + """ must identify an interval tier."
    elsif .type$ = "point" and .interval
        exitScript: .field$ + ": """ + .reference$ + """ must identify a point tier."
    endif
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
            exitScript: .field$ + ": multiple tiers are named """ + .name$ + """. Give them unique names."
        endif
    endif
    if index_regex(.name$, "^[0-9]+$") != 0
        appendInfoLine: "Warning: tier """ + .name$ + """ has a numeric name. Use a descriptive name to avoid confusion with tier numbers."
    endif
endproc

# As resolveTierNumber, for scripts that pass tier NAMES on (e.g. Create Table).
procedure resolveTierReference: .textGrid, .reference$, .field$, .type$
    @resolveTierNumber: .textGrid, .reference$, .field$, .type$
    .tier = resolveTierNumber.tier
    .interval = resolveTierNumber.interval
    .name$ = resolveTierNumber.name$
    if .name$ = "" or index(.name$, ",") != 0
        exitScript: .field$ + ": the selected tier needs a non-empty name without commas."
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
