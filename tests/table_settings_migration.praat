aeroPrototypeInclude = 1
main.curVersion$ = "1.5.0.2"
firstPass = 0
createFolder: preferencesDirectory$ + "/plugin_AERoPlot"
createFolder: preferencesDirectory$ + "/plugin_AERoPlot/data"
createFolder: preferencesDirectory$ + "/plugin_AERoPlot/data/vars"
vars$ = preferencesDirectory$ + "/plugin_AERoPlot/data/vars/"
@initialiseVars: vars$ + "tier2Table.var"
@readVars: vars$, "tier2Table.var"
ui.vowelDur$ = "vowel"
@writeVars: vars$, "tier2Table.var"
@defineVars
assert ui.vowelDur$ = "vowel"
assert ui.duration2$ = ""
assert ui.intensityTier1$ = ""
assert ui.intensityPitch = 100
ui.duration2$ = "syllable"
ui.intensityTier1$ = "points"
ui.intensityMethod1 = 3
@writeVars: vars$, "tier2Table.var"
ui.duration2$ = ""
ui.intensityTier1$ = ""
ui.intensityMethod1 = 1
@readVars: vars$, "tier2Table.var"
assert ui.duration2$ = "syllable"
assert ui.intensityTier1$ = "points"
assert ui.intensityMethod1 = 3
writeInfoLine: "Table settings migration tests passed."

include ../plotScripts/nestedTiers2Table.praat
