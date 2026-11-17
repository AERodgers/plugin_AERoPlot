sound = Create Sound from formula: "sample", 1, 0, 0.5, 16000,
... "0.2*sin(2*pi*500*x)+0.1*sin(2*pi*1200*x)"
grid = Create TextGrid: 0, 0.5, "words points", "points"
selectObject: grid
Insert point: 2, 0.1, "vowel"
Insert point: 2, 0.2, ""
Insert point: 2, 0.25, "  "
Insert point: 2, 0.3, "vowel"

@validateLineSpectrum: sound, 3, 0, 0.025, 0, 5000, 1, 0, 100, -20, 80, 8
assert validateLineSpectrum.order = 18
@collectLineSpectrumPoints: grid, 2, 0, 0.5, 0.025
assert collectLineSpectrumPoints.count = 2
assert collectLineSpectrumPoints.index[2] = 4
assert abs(collectLineSpectrumPoints.time[2] - 0.3) < 1e-10
asserterror too close
runScript: "line_spectrum_error.praat", "time"
asserterror Nyquist
runScript: "line_spectrum_error.praat", "frequency"
asserterror FFT maximum
runScript: "line_spectrum_error.praat", "axis"
asserterror point tier
runScript: "line_spectrum_error.praat", "tier"
asserterror no labelled points
runScript: "line_spectrum_error.praat", "empty"
@lineSpectrumFilename: "sample", "a/b", 0, 0.1
assert lineSpectrumFilename.name$ = "sample_a_b.png"

for mode to 3
    @createLineSpectrumAnalysis: sound, mode, 0, 0.025, 18, 5000
    @drawLineSpectrum: sound, mode, 0, 0.1, "vowel", "", 5000,
    ... 1, 0, 100, -20, 80, 1, 8, 2
    @removeLineSpectrumAnalysis
endfor
for mode to 3
    @createLineSpectrumAnalysis: sound, mode, 1, 0.025, 18, 5000
    if mode != 1
        selectObject: createLineSpectrumAnalysis.lpc
        frames = Get number of frames
        assert frames = 1
        frameTime = Get time from frame number: 1
        assert abs(frameTime - 0.25) < 1e-10
    endif
    @drawLineSpectrum: sound, mode, 1, 0.25, "", "", 5000,
    ... 0, 0, 0, 0, 0, 0, 8, 2
    @removeLineSpectrumAnalysis
endfor
stereo = Create Sound from formula: "stereo", 2, 0, 0.5, 16000, "0.2*sin(2*pi*500*x)"
@createLineSpectrumAnalysis: stereo, 3, 0, 0.025, 18, 5000
@drawLineSpectrum: stereo, 3, 0, 0.25, "", "", 5000, 0, 0, 0, 0, 0, 0, 8, 2
@removeLineSpectrumAnalysis
@createLineSpectrumAnalysis: stereo, 3, 1, 0.025, 18, 5000
@drawLineSpectrum: stereo, 3, 1, 0.25, "", "", 5000, 0, 0, 0, 0, 0, 0, 8, 2
@removeLineSpectrumAnalysis
removeObject: stereo
removeObject: {sound, grid}
writeInfoLine: "Line spectrum tests passed."

include ../plotScripts/_line_spectrum.praat
