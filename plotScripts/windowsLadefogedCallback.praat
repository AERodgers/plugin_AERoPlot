# Called by the Windows Ladefoged dialog when the user requests a plot action.
form AERoPlot Windows Ladefoged request
    word cbToken
    integer cbTable
    integer cbAction
endform

if not index_regex(cbToken$, "^[a-f0-9]{32}$") or cbAction < 1 or cbAction > 4
    exitScript: "The plot request from the Windows dialog was not valid."
endif
aeroPrototypeInclude = 1
include ladPlot.praat
include _windows_lad_ui.praat

ladPrevious# = selected#()
nocheck selectObject: cbTable
if numberOfSelected() = 0
    exitScript: "Cannot draw: the Table was removed from the Praat Objects list. Close the AERoPlot window and start again."
endif

@windowsLadRun

for i to size(ladPrevious#)
    if i = 1
        nocheck selectObject: ladPrevious#[i]
    else
        nocheck plusObject: ladPrevious#[i]
    endif
endfor
if cbAction = 1 or cbAction = 3 or cbAction = 4
    writeFile: preferencesDirectory$ + "/plugin_AERoPlot/data/temp/lad-ui/lad-complete-" + cbToken$ + ".txt", "OK"
endif