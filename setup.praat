# Menu Commands
Add menu command: "Objects", "New",
... "--",
... "",
... 0, ""

Add menu command: "Objects", "New",
... "AERoPlot",
... "",
... 0, ""

#Add menu command: "Objects", "New",
#... "F1F2 Plot...",
#... "AERoPlot",
#... 1, "plotScripts/f1f2Plot.praat"

#Add menu command: "Objects", "New",
#... "Ladefoged Formant Plot...",
#... "AERoPlot",
#... 1, "plotScripts/ladPlot.praat"

#Add menu command: "Objects", "New",
#... "Formants-over-time Plot...",
#... "AERoPlot",
#... 1,  "plotScripts/fotPlot.praat"

#Add menu command: "Objects", "New",
#... "--",
#... "AERoPlot",
#... 1, ""

#Add menu command: "Objects", "New",
#... "Generate data table from nested textgrid tiers...",
#... "AERoPlot",
#... 1,  "plotScripts/nestedTiers2Table.praat"

Add menu command: "Objects", "New",
... "Load example sound and text grid...",
... "AERoPlot",
... 1,  "plotScripts/loadExamples.praat"

# Action Commands

## AeroPlot Table
Add action command:
... "Table", 1,
... "", 0,
... "", 0,
... " ",
... "", 0,
... ""
Add action command:
... "Table", 1,
... "", 0,
... "", 0,
... "AERoPlot",
... "", 0,
... ""

Add action command:
... "Table", 1,
... "", 0,
... "", 0,
... "Formants-over-time Plot...",
... "AERoPlot", 0,
... "plotScripts/fotPlot.praat"

Add action command:
... "Table", 1,
... "", 0,
... "", 0,
... "Ladefoged Formant Plot...",
... "AERoPlot",0,
... "plotScripts/ladPlot.praat"


Add action command:
... "Table", 1,
... "", 0,
... "", 0,
... "F1F2 Plot...",
... "AERoPlot", 0,
... "plotScripts/f1f2Plot.praat"



## AERoPlot Sound + TextGrid
Add action command:
... "Sound", 1,
... "TextGrid", 1,
... "", 0,
... " ",
... "", 0,
... ""

Add action command:
... "Sound", 1,
... "TextGrid", 1,
... "", 0,
... "AERoPlot",
... "", 0,
... ""

Add action command:
... "Sound", 1,
... "TextGrid", 1,
... "", 0,
... "Create data table from nested textgrid tiers...",
... "AERoPlot", 0,
... "plotScripts/nestedTiers2Table.praat"


Add action command:
... "Sound", 1,
... "TextGrid", 1,
... "", 0,
... "C3P-o-Gram...",
... "", 0,
... "plotScripts/c3pogram.praat"

## AERoPlot Sound
Add action command:
... "Sound", 1,
... "", 0,
... "", 0,
... " ",
... "", 0,
... ""

Add action command:
... "Sound", 1,
... "", 0,
... "", 0,
... "AERoPlot",
... "", 0,
... ""

Add action command:
... "Sound", 1,
... "", 0,
... "", 0,
... "C3P-o-Gram...",
... "", 0,
... "plotScripts/c3pogram.praat"
