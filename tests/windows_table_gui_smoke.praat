result$ = environment$("AEROPLOT_TEST_RESULT")
assert result$ != ""
runScript: "windows_table_prototype.praat"
writeFileLine: result$, "Windows GUI integration passed."
