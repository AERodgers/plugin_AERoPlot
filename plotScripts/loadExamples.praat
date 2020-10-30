# Load example textgrid, sound, and table files
# ============================================
# A feature of the AERoplot plugin.
#
# Written for Praat 6.0.40 or later
#
# script by Antoin Eoin Rodgers
# Phonetics and speech Laboratory, Trinity College Dublin
# October 30th 2020
#
# email:     rodgeran@tcd.ie
# twitter:   @phonetic_antoin
# github:    github.com/AERodgers
#
# This is just a script to load example files for demonstration purposes.

@checkPraatVersion
@purgeDirFiles: "../data/temp"
@checkDirectoryStructure

Read from file: "../example/AER_NI_I.wav"
Read from file: "../example/AER_NI_I.TextGrid"


include _aeroplotFns.praat
include _genFnBank.praat
