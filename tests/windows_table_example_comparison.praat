form Windows Table example comparison
    boolean Base_tier_times_only 1
endform

result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
originalPath$ = result$ + ".original.tsv"
prototypePath$ = result$ + ".prototype.tsv"
if fileReadable(result$) or fileReadable(originalPath$) or fileReadable(prototypePath$)
    exitScript: "Choose an unused AEROPLOT_TEST_RESULT path for this comparison."
endif

sound = Read from file: "../example/AER_NI_I.wav"
grid = Read from file: "../example/AER_NI_I.TextGrid"
selectObject: sound
plusObject: grid
nowarn runScript: "../plotScripts/nestedTiers2Table.praat"
selectObject: "Table native_comparison"
original = selected("Table")
selectObject: sound
plusObject: grid
nowarn runScript: "../plotScripts/windowsTablePrototype.praat"
prototype = selected("Table")

selectObject: original
originalRows = Get number of rows
originalColumns = Get number of columns
selectObject: prototype
prototypeRows = Get number of rows
prototypeColumns = Get number of columns
if originalColumns != prototypeColumns
    labels$ = ""
    selectObject: original
    for col to originalColumns
        label$ = Get column label: col
        labels$ += " " + label$
    endfor
    selectObject: prototype
    newLabels$ = ""
    for col to prototypeColumns
        label$ = Get column label: col
        newLabels$ += " " + label$
    endfor
    exitScript: "Column mismatch: original", labels$, "; prototype", newLabels$
endif
assert originalRows = prototypeRows
assert originalColumns = prototypeColumns
assert originalRows = 35
if base_tier_times_only
    assert originalColumns = 5
else
    assert originalColumns = 9
endif
selectObject: original
Save as tab-separated file: originalPath$
selectObject: prototype
Save as tab-separated file: prototypePath$
originalText$ = readFile$(originalPath$)
prototypeText$ = readFile$(prototypePath$)
assert originalText$ = prototypeText$
removeObject: original, prototype, sound, grid
writeInfoLine: "Example comparison passed: ", originalRows, " rows, ",
... originalColumns, " columns, base-tier times only = ", base_tier_times_only, "."
writeFileLine: result$, "Example comparison passed: ", originalRows, " rows, ",
... originalColumns, " columns, base-tier times only = ", base_tier_times_only, "."
