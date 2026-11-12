# Called by the Windows plot dialog (through Praat's message window) each time
# the user presses Draw. Not a menu command.
form AERoPlot Windows plot request
    word cbToken
    word cbInterface
    integer cbSound
    integer cbGrid
    integer cbPitch
endform

if not index_regex(cbToken$, "^[a-f0-9]{32}$")
    exitScript: "The plot request from the Windows dialog was not valid."
endif
if cbInterface$ = "Spectrogram"
    spectrogram_only = 1
elsif cbInterface$ = "PitchPlus"
    spectrogram_only = 0
else
    exitScript: "The plot request from the Windows dialog was not valid."
endif
plot_interface$ = cbInterface$
asyncPlotToken$ = cbToken$
aeroAsyncPlotCallback = 1

# Remember what the user has selected now, so it can be restored afterwards.
asyncPlotPrevious# = selected#()

missing$ = ""
nocheck selectObject: cbSound
if numberOfSelected() = 0
    missing$ = "the Sound"
endif
if cbGrid > 0
    nocheck selectObject: cbGrid
    if numberOfSelected() = 0
        missing$ = "the TextGrid"
    endif
endif
if cbPitch > 0
    nocheck selectObject: cbPitch
    if numberOfSelected() = 0
        missing$ = "the Pitch object"
    endif
endif
if missing$ <> ""
    exitScript: "Cannot draw: " + missing$ + " was removed from the Praat Objects list. Close the AERoPlot window and start again."
endif

selectObject: cbSound
if cbGrid > 0
    plusObject: cbGrid
endif
if cbPitch > 0
    plusObject: cbPitch
endif

include _pitch_plus.praat
