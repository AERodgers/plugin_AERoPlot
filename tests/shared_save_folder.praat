form Shared save folder test
    sentence Isolated_preferences
endform

expectedPrefs$ = replace$(isolated_preferences$, "\", "/", 0)
actualPrefs$ = replace$(preferencesDirectory$, "\", "/", 0)
assert actualPrefs$ = expectedPrefs$
assert not variableExists("sharedSaveFolderFile$")

plugin$ = actualPrefs$ + "/plugin_AERoPlot"
data$ = plugin$ + "/data"
file$ = data$ + "/sharedSaveFolder.txt"
assert not folderExists(plugin$)
createFolder: plugin$
createFolder: data$

saveDir$ = "old per-plot setting"
@readSharedSaveFolder
assert saveDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/AERoPlot_Images"
saveDir$ = actualPrefs$ + "/a folder"
@setSharedSaveFolder
assert fileReadable(file$)
saveDir$ = "another old setting"
@readSharedSaveFolder
assert saveDir$ = actualPrefs$ + "/a folder"
saveDir$ = ""
@setSharedSaveFolder
assert saveDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/AERoPlot_Images"
assert not fileReadable(file$)
@readSharedSaveFolder
assert saveDir$ = preferencesDirectory$ + "/plugin_AERoPlot/data/AERoPlot_Images"

sharedSaveFolderFile$ = ""
saveDir$ = actualPrefs$ + "/another folder"
@setSharedSaveFolder
saveDir$ = ""
@readSharedSaveFolder
assert saveDir$ = actualPrefs$ + "/another folder"
saveDir$ = ""
@setSharedSaveFolder
assert not fileReadable(file$)
writeInfoLine: "Shared save folder tests passed."

include ../plotScripts/_aeroplotFns.praat
