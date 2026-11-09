@checkPraatVersion

durations# = {0.01, 0.1, 1, 10, 60, 3600}
expectedMajor# = {0.002, 0.02, 0.2, 2, 10, 1000}
for i to size(durations#)
    @niceTimeInterval: durations#[i]
    assert abs(niceTimeInterval.major - expectedMajor#[i]) < 1e-10
    assert niceTimeInterval.minor = niceTimeInterval.major / 2
    assert durations#[i] / niceTimeInterval.major <= 6.000001
endfor

sound = Create Sound from formula: "short", 1, 0, 0.1, 8000, "0.1*sin(2*pi*100*x)"
@warnLongRecording: sound
assert warnLongRecording.proceed = 1
assert selected("Sound") = sound
removeObject: sound

table = Read Table from tab-separated file: "../example/AER_NI_I.txt"
@makeTimeRelative: table, "Context", "Element", "Element_t", "Rep", "2"
rows = Get number of rows
for row to rows
    element$ = Get value: row, "Element"
    time = Get value: row, "Element_t"
    if element$ = "2"
        assert abs(time) < 1e-10
    endif
endfor
removeObject: table
writeInfoLine: "Shared helper tests passed."

include ../plotScripts/_genFnBank.praat
