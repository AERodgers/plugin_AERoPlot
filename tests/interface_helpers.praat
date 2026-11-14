form Interface helper tests
    sentence Prefs_directory
endform

# Off values
offCases$# = {"", "  ", "none", "None", "NONE", " null ", "NULL", "Null"}
for i to size(offCases$#)
    @isOffValue: offCases$#[i]
    assert isOffValue.off = 1
endfor
onCases$# = {"0", "Element", "nonexistent", "nullable", "F1"}
for i to size(onCases$#)
    @isOffValue: onCases$#[i]
    assert isOffValue.off = 0
endfor

# Column resolver: names, numbers, optional blanks, unknown entries
table = Create formant table (Peterson & Barney 1952)
selectObject: table
numColumns = Get number of columns
assert numColumns >= 5
firstLabel$ = Get column label: 1
secondLabel$ = Get column label: 2

oFactor$ = "2"
iFactor$ = ""
f1Col$ = " F1 "
f2Col$ = "Nonexistent"
@resolveColumnVariables: table, "oFactor$,iFactor$,f1Col$,f2Col$"
assert resolveColumnVariables.error$ = ""
assert oFactor$ = secondLabel$
assert iFactor$ = ""
assert f1Col$ = "F1"
assert f2Col$ = "Nonexistent"
assert resolveColumnVariables.list$ = secondLabel$ + ",F1,Nonexistent"

# A number outside the table is left for the caller's missing-column report
oFactor$ = "99"
@resolveColumnVariables: table, "oFactor$"
assert resolveColumnVariables.error$ = ""
assert oFactor$ = "99"

# A numeric header that differs from its column number is ambiguous
Set column label (index): 3, "1"
oFactor$ = "1"
@resolveColumnVariables: table, "oFactor$"
assert resolveColumnVariables.error$ != ""

# ...but a numeric header that is also its own number is accepted
Set column label (index): 3, "3"
oFactor$ = "3"
@resolveColumnVariables: table, "oFactor$"
assert resolveColumnVariables.error$ = ""
assert oFactor$ = "3"
removeObject: table

# Interface preference
prefs$ = prefs_directory$
assert prefs$ != ""
assert preferencesDirectory$ = prefs$

# Readiness decision covers unsupported Praat versions and missing helpers.
@windowsUIRequirements: 1, "6.4.59", 6, 4, 59, "C:/test/AERoPlotWindowsUI.exe", 1
assert windowsUIRequirements.ok = 0
assert index(windowsUIRequirements.reason$, "6.4.60") > 0
@windowsUIRequirements: 1, "6.4.60", 6, 4, 60, "C:/test/AERoPlotWindowsUI.exe", 0
assert windowsUIRequirements.ok = 0
assert windowsUIRequirements.helperMissing = 1
assert index(windowsUIRequirements.reason$, "AERoPlotWindowsUI.exe") > 0
@windowsUIRequirements: 0, "6.4.60", 6, 4, 60, "C:/test/AERoPlotWindowsUI.exe", 1
assert windowsUIRequirements.ok = 0
assert windowsUIRequirements.reason$ = "The Windows interface is available only on Windows."

aeroNonInteractive = 1
prefFile$ = preferencesDirectory$ + "/plugin_AERoPlot/data/vars/ui_mode.txt"
assert not fileReadable(prefFile$)
@getUIMode
# Windows is the default choice; if the helper is unavailable, Praat reports
# why it is using the standard interface instead and remembers the fallback.
if windowsUIAvailable.ok
    assert getUIMode.preference$ = "windows"
    assert getUIMode.mode$ = "windows"
else
    assert getUIMode.mode$ = "praat"
    assert getUIMode.reason$ != ""
    if environment$("OS") = "Windows_NT" and windowsUIAvailable.helperMissing
        assert getUIMode.preference$ = "praat"
        assert readFile$(prefFile$) = "praat"
    else
        assert getUIMode.preference$ = "windows"
    endif
endif

@setUIMode: "windows"
assert fileReadable(prefFile$)
@getUIMode
if windowsUIAvailable.ok
    assert getUIMode.preference$ = "windows"
    assert getUIMode.mode$ = "windows"
else
    assert getUIMode.mode$ = "praat"
    assert getUIMode.reason$ != ""
    if environment$("OS") = "Windows_NT"
        assert getUIMode.preference$ = "praat"
        assert readFile$(prefFile$) = "praat"
    else
        assert getUIMode.preference$ = "windows"
    endif
endif

@setUIMode: "praat"
@getUIMode
assert getUIMode.preference$ = "praat"

# The menu scripts write the same preference.
writeFile: prefFile$, "  PRAAT " + newline$
@getUIMode
assert getUIMode.preference$ = "praat"
writeFile: prefFile$, "something else"
@getUIMode
if windowsUIAvailable.ok
    assert getUIMode.preference$ = "windows"
else
    assert getUIMode.mode$ = "praat"
    if environment$("OS") = "Windows_NT"
        assert getUIMode.preference$ = "praat"
        assert readFile$(prefFile$) = "praat"
    else
        assert getUIMode.preference$ = "windows"
    endif
endif
deleteFile: prefFile$

writeInfoLine: "Interface helper tests passed."

include ../plotScripts/_genFnBank.praat
include ../plotScripts/_ui_common.praat
