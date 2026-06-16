# Load example textgrid, sound, and table files
# ============================================
# A feature of the AERoplot plugin.
#
# Written for Praat 6.0.60 or later
#
# script by Antoin Eoin Rodgers
#
# email:     antoin.rodgers@tcd.ie
# github:    github.com/AERodgers
#
# This is just a script to load example files for demonstration purposes.


@checkPraatVersion

@checkDirectoryStructure
@purgeDirFiles: preferencesDirectory$ + "/plugin_AERoPlot/data/temp"

Read from file: preferencesDirectory$ + "/plugin_AERoPlot/example/AER_NI_I.wav"
Read from file: preferencesDirectory$ + "/plugin_AERoPlot/example/AER_NI_I.TextGrid"


include _aeroplotFns.praat
include _genFnBank.praat
