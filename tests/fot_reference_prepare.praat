form Test filtered formants-over-time reference
    integer cbTable
    sentence Result_path
endform

aeroPrototypeInclude = 1
include fotPlot.praat
include _windows_lad_ui.praat
include _windows_fot_ui.praat

previous# = selected#()
oFactor$ = "Context"
iFactor$ = "Element"
timeCol$ = "Element_t"
repFactor$ = "Rep"
f1Col$ = "F1"
f2Col$ = "F2"
f3Col$ = "F3"
f4Col$ = ""
referenceLevel$ = "1"
coreLevelName$ = "2"
keepCount = 1
keepColumn$[1] = "Element"
keepValue$[1] = "2"
@windowsFoTPrepare
selectObject: table
rows = Get number of rows
assert rows = 2
for row to 2
    element$ = Get value: row, "Element"
    assert element$ = "2"
    time = Get value: row, "Element_t"
    assert abs(time - 0.1) < 1e-9
endfor
removeObject: table
selectObject: cbTable
originalTime = Get value: 1, "Element_t"
assert abs(originalTime - 0.1) < 1e-9
if size(previous#) > 0
    selectObject: previous#
endif
writeFileLine: result_path$, "PASS"
