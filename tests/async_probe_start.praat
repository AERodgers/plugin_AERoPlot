form Isolated asynchronous probe
    sentence Probe_executable
    sentence Result_path
    sentence Ready_path
    sentence Probe_tag
endform

sound = Create Sound from formula: "probe_" + probe_tag$, 1, 0, 1, 8000, "0"
grid = To TextGrid: "word", ""
Set interval text: 1, 1, "hello"
selectObject: sound, grid
asynchronous runSubprocess: probe_executable$, result_path$
writeFileLine: ready_path$, sound, tab$, grid, tab$, probe_tag$
