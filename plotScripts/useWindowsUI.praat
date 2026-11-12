@windowsUIAvailable
if windowsUIAvailable.ok
    @setUIMode: "windows"
    @showUIModeMessage: "AERoPlot will now use the Windows interface for PitchPlus, Spectrogram and Create Table. Other features keep the standard Praat windows."
else
    @setUIMode: "praat"
    @showUIModeMessage: "The Windows interface cannot be used on this computer (it needs Windows, Praat 6.4.60 or newer, and the helper program built). AERoPlot will keep using the standard Praat windows."
endif

include _genFnBank.praat
include _ui_common.praat
