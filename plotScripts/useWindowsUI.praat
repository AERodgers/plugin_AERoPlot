@windowsUIAvailable
if windowsUIAvailable.ok
    @setUIMode: "windows"
    @showUIModeMessage: "AERoPlot will use Windows dialogs for Create Table, PitchPlus and Spectrogram on Sounds, and F1-F2 and Ladefoged on one selected Table. " +
    ... "Other features keep the standard Praat windows."
else
    @setUIMode: "praat"
    @showUIModeMessage: "The Windows interface cannot be enabled. " +
    ... windowsUIAvailable.reason$ + " AERoPlot will keep using the standard Praat interface."
endif

include _genFnBank.praat
include _ui_common.praat
