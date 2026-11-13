# Called by the Windows F1-F2 dialog (through Praat's message window) when the
# user presses Draw, Draw & Exit, Save image or applies colour settings.
form AERoPlot Windows F1-F2 request
    word cbToken
    integer cbTable
    integer cbAction
endform

if not index_regex(cbToken$, "^[a-f0-9]{32}$") or cbAction < 1 or cbAction > 4
    exitScript: "The plot request from the Windows dialog was not valid."
endif
aeroPrototypeInclude = 1
include f1f2Plot.praat
include _windows_f1f2_ui.praat

# Remember what the user has selected now, so it can be restored afterwards.
f1f2Previous# = selected#()
nocheck selectObject: cbTable
if numberOfSelected() = 0
    exitScript: "Cannot draw: the Table was removed from the Praat Objects list. Close the AERoPlot window and start again."
endif

@windowsF1F2Run

for i to size(f1f2Previous#)
    if i = 1
        nocheck selectObject: f1f2Previous#[i]
    else
        nocheck plusObject: f1f2Previous#[i]
    endif
endfor
if cbAction = 1 or cbAction = 3 or cbAction = 4
    writeFile: preferencesDirectory$ + "/plugin_AERoPlot/data/temp/f1f2-ui/f1f2-complete-" + cbToken$ + ".txt", "OK"
endif
