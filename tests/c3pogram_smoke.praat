sound = Create Sound from formula: "test", 1, 0, 0.5, 44100, "0.2*sin(2*pi*120*x)"

for parameter to 4
    parameter$[1] = "Cepstral Peak Prominence"
    parameter$[2] = "Residual of intensity (linear regression)"
    parameter$[3] = "H1-H2 of differentiated glottal pulse (LPC-IF)"
    parameter$[4] = "Harmonicity (Praat function)"
    selectObject: sound
    runScript: "../plotScripts/c3pogram.praat",
    ... "Test", 1, 999, 1, 0, 8, 60, 400, 30, 90,
    ... "F0 + secondary parameter", "Semitones re 1 Hz", parameter$[parameter], "courier"
    assert selected("Sound") = sound
endfor

selectObject: sound
runScript: "../plotScripts/c3pogram.praat",
... "Test", 1, 999, 1, 1, 8, 60, 400, 30, 90,
... "F0 only", "Hertz", "Cepstral Peak Prominence", "courier"
assert selected("Sound") = sound

selectObject: sound
runScript: "../plotScripts/c3pogram.praat",
... "Test", 1, 999, 0, 0, 8, 60, 400, 30, 90,
... "Intensity only", "Hertz", "Cepstral Peak Prominence", "courier"
assert selected("Sound") = sound

selectObject: sound
runScript: "../plotScripts/c3pogram.praat",
... "Test", 1, 999, 1, 0, 8, 60, 400, 30, 90,
... "Background only", "Hertz", "Cepstral Peak Prominence", "courier"
assert selected("Sound") = sound

removeObject: sound

sound = Read from file: "../example/AER_NI_I.wav"
grid = Read from file: "../example/AER_NI_I.TextGrid"
selectObject: sound, grid
runScript: "../plotScripts/c3pogram.praat",
... "Example", 1, 999, 1, 1, 8, 60, 400, 30, 90,
... "F0 only", "Semitones re 1 Hz", "Cepstral Peak Prominence", "courier"
assert size(selected#()) = 2
assert selected("Sound") = sound
assert selected("TextGrid") = grid
removeObject: {sound, grid}
writeInfoLine: "C3PoGram smoke tests passed."
