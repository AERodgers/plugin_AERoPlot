
# AERoplot plugin.
#
# Written for Praat 6.0.60 or later
# script by Antoin Eoin Rodgers
#
# email:     antoin.rodgers@tcd.ie
# github:    github.com/AERodgers
#
# v.1.5.0.0

# Menu Commands
Add menu command: "Objects", "Praat", "--", "", 0, ""
Add menu command: "Objects", "Praat", "AERoPlot", "", 0, ""
Add menu command: "Objects", "Praat", "Load example sound and text grid...", "AERoPlot", 1, "plotScripts/loadExamples.praat"
# The interface choice only matters on Windows, where there is a second interface.
if environment$("OS") = "Windows_NT"
    Add menu command: "Objects", "Praat", "--", "AERoPlot", 1, ""
    Add menu command: "Objects", "Praat", "Use Praat interface", "AERoPlot", 1, "plotScripts/usePraatUI.praat"
    Add menu command: "Objects", "Praat", "Use Windows interface", "AERoPlot", 1, "plotScripts/useWindowsUI.praat"
    # Wake the helper in the background so the first dialog opens quickly.
    if fileReadable(preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe")
        nocheck asynchronous runSubprocess: preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe", "WARMUP"
    endif
endif

# Action Commands

## AeroPlot Table
Add action command: "Table", 1, "", 0, "", 0, " ", "", 0, ""
Add action command: "Table", 1, "", 0, "", 0, "AERoPlot", "", 0, ""
Add action command: "Table", 1, "", 0, "", 0, "Formants-over-time Plot...", "AERoPlot", 0, "plotScripts/fotPlot.praat"
Add action command: "Table", 1, "", 0, "", 0, "Ladefoged Formant Plot...", "AERoPlot", 0, "plotScripts/ladPlot.praat"
Add action command: "Table", 1, "", 0, "", 0, "F1F2 Plot...", "AERoPlot", 0, "plotScripts/f1f2Plot.praat"

## AERoPlot Sound + TextGrid
Add action command: "Sound", 1, "TextGrid", 1, "", 0, " ", "", 0, ""
Add action command: "Sound", 1, "TextGrid", 1, "", 0, "AERoPlot", "", 0, ""
Add action command: "Sound", 1, "TextGrid", 1, "", 0, "Create Table from nested TextGrid tiers", "AERoPlot", 0, "plotScripts/nestedTiers2Table.praat"
Add action command: "Sound", 1, "TextGrid", 1, "", 0, "PitchPlus", "AERoPlot", 0, "plotScripts/pitch_plus.praat"
Add action command: "Sound", 1, "TextGrid", 1, "", 0, "Spectrogram", "AERoPlot", 0, "plotScripts/spectro_plus.praat"

## AERoPlot Sound
Add action command: "Sound", 1, "", 0, "", 0, " ", "", 0, ""
Add action command: "Sound", 1, "", 0, "", 0, "AERoPlot", "", 0, ""
Add action command: "Sound", 1, "", 0, "", 0, "PitchPlus", "AERoPlot", 0, "plotScripts/pitch_plus.praat"
Add action command: "Sound", 1, "", 0, "", 0, "Spectrogram", "AERoPlot", 0, "plotScripts/spectro_plus.praat"
