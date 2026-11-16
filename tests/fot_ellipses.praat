form Formants-over-time ellipse regression
    sentence Actual_path
    sentence Jittered_path
    sentence Expected_path
endform

aeroPrototypeInclude = 1
include fotPlot.praat

previous# = selected#()
table = Create Table with column names: "ellipse_fixture", 13,
... "Context Element TimeDrawValue F1DrawValue F2DrawValue"
for row to 12
    group = floor((row - 1) / 3)
    sample = (row - 1) mod 3
    Set string value: row, "Context", string$(floor(group / 2) + 1)
    Set string value: row, "Element", string$(group mod 2 + 1)
    Set numeric value: row, "TimeDrawValue", group * 2 + sample * 0.3
    Set numeric value: row, "F1DrawValue", 200 + group * 250 + (sample = 1) * 70
    Set numeric value: row, "F2DrawValue", 400 + group * 200 + (sample = 0) * 50
endfor
Set string value: 13, "Context", "1"
Set string value: 13, "Element", "3"
Set numeric value: 13, "TimeDrawValue", 0
Set numeric value: 13, "F1DrawValue", 50
Set numeric value: 13, "F2DrawValue", 100

oLevels = 2
iLevels = 3
numFormants = 2
oFactor$ = "Context"
iFactor$ = "Element"
timeCol$ = "Time"
f1Col$ = "F1"
f2Col$ = "F2"
minT = -1
maxT = 8
minF = 0
maxF = 1200
ellipsisSDs = 2
colrAdj# = {0.299, 0.587, 0.114}
possRows.matrix## = zero##(2, 3)
iLevel$[3] = "3"
for o to oLevels
    oLevel$[o] = string$(o)
    oColour$[o,2] = "{0.2,0.2,0.2}"
    oColour$[o,4] = "{0.2,0.4,0.8}"
    oColour$[o,5] = "{0.8,0.8,0.8}"
    selectObject: table
    plotTable[o] = Extract rows where: "self$[oFactor$] = oLevel$[o]"
    for i to 2
        iLevel$[i] = string$(i)
        possRows.matrix##[o,i] = 3
        stDevFAct[o,i,1] = 1
        stDevFAct[o,i,2] = 1
    endfor
endfor
possRows.matrix##[1,3] = 1
stDevFAct[1,3,1] = undefined

Erase all
Select inner viewport: 1, 4, 1, 5
Axes: minT, maxT, minF, maxF
@drawEllipses
Save as 300-dpi PNG file: actual_path$

for o to oLevels
    selectObject: plotTable[o]
    rows = Get number of rows
    for row to rows
        x = Get value: row, "TimeDrawValue"
        Set numeric value: row, "TimeDrawValue", x + 0.6
    endfor
endfor
Erase all
Select inner viewport: 1, 4, 1, 5
Axes: minT, maxT, minF, maxF
@drawEllipses
Save as 300-dpi PNG file: jittered_path$

Erase all
Select inner viewport: 1, 4, 1, 5
Axes: minT, maxT, minF, maxF
for o to oLevels
    for i to 2
        selectObject: table
        expected = Extract rows where:
        ... "self$[oFactor$] = oLevel$[o] and self$[iFactor$] = iLevel$[i]"
        for f to numFormants
            column$ = "F" + string$(f) + "DrawValue"
            Line width: 4
            Colour: oColour$[o,5]
            Draw ellipses: "TimeDrawValue", minT, maxT, column$, minF, maxF,
            ... oFactor$, ellipsisSDs, 0, "no"
            Line width: 2
            Colour: oColour$[o,4]
            Draw ellipses: "TimeDrawValue", minT, maxT, column$, minF, maxF,
            ... oFactor$, ellipsisSDs, 0, "no"
        endfor
        removeObject: expected
    endfor
endfor
Save as 300-dpi PNG file: expected_path$
removeObject: table, plotTable[1], plotTable[2]
if size(previous#) > 0
    selectObject: previous#
endif
