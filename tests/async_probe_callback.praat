form Isolated asynchronous callback
    sentence Ready_path
    sentence Result_path
    sentence Completion_path
endform

ids$# = splitByWhitespace$#(readFile$(ready_path$))
assert size(ids$#) = 3
sound = number(ids$#[1])
grid = number(ids$#[2])
result$# = splitByWhitespace$#(readFile$(result_path$))
if size(result$#) = 1
    assert result$#[1] = "CANCEL"
    writeFileLine: completion_path$, "cancelled"
    exit
endif
assert size(result$#) = 5
assert result$#[1] = "OK"
assert result$#[2] = "aeroplot_table"
assert result$#[3] = "1"
assert result$#[4] = "1"
assert result$#[5] = "-"
if ids$#[3] = "AeroProbeOne"
    assert selected$("Sound") = "selection_changed"
endif
selectObject: sound
assert selected$("Sound") = "probe_" + ids$#[3]
selectObject: grid
assert selected$("TextGrid") = "probe_" + ids$#[3]
table = Down to Table: "no", 3, "yes", "no"
rows = Get number of rows
assert rows = 1
writeFileLine: completion_path$, "created", tab$, selected("Table"), tab$, sound, tab$, grid, tab$, ids$#[3]
