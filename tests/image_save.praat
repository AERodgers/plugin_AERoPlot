form Image save test
    sentence Test_folder
endform

if folderExists(test_folder$)
    exitScript: "Choose a test folder that does not already exist."
endif

saveDir$ = ""
@useDefaultSaveFolder
assert saveDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/AERoPlot_Images"
saveDir$ = test_folder$
@useDefaultSaveFolder
assert saveDir$ = test_folder$

folder$ = replace$(test_folder$, "\", "/", 0) + "/nested/output"
@prepareImageSave: folder$, "vowel.plot.PNG"
assert prepareImageSave.path$ = folder$ + "/vowel.plot.png"
assert folderExists(folder$)
Axes: 0, 1, 0, 1
Draw line: 0, 0, 1, 1
Save as 300-dpi PNG file: prepareImageSave.path$
assert fileReadable(prepareImageSave.path$)

@prepareImageSave: folder$ + "/", "vowel.plot.png"
assert prepareImageSave.path$ = folder$ + "/vowel.plot_1.png"
Save as 300-dpi PNG file: prepareImageSave.path$
assert fileReadable(prepareImageSave.path$)

@prepareImageSave: folder$, "vowel.plot"
assert prepareImageSave.path$ = folder$ + "/vowel.plot_2.png"

varsFile$ = folder$ + "/savetest.var"
writeFileLine: varsFile$, "variable", tab$, "value"
appendFileLine: varsFile$, "saveDir$", tab$, "?"
@readVars: folder$ + "/", "savetest.var"
@useDefaultSaveFolder
assert saveDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/AERoPlot_Images"
save_folder$ = folder$
save_name$ = "vowel"
output_units = 1
inputUnits = 1
show_legend = 1
font_choice = 1
base_font_size = 3
modify_colour_scheme = 1
add_or_change_colour_scheme = 0
@processShared_UIs
assert saveDir$ = folder$
@writeVars: folder$ + "/", "savetest.var"
saveDir$ = ""
@readVars: folder$ + "/", "savetest.var"
assert saveDir$ = folder$
save_folder$ = ""
@processShared_UIs
assert saveDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/AERoPlot_Images"
writeInfoLine: "Image save tests passed."

include ../plotScripts/_aeroplotFns.praat
include ../plotScripts/_genFnBank.praat
