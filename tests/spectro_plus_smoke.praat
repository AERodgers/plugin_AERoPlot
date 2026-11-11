# Interactive Spectrogram smoke test: select tiers, toggle boundaries, and use Draw to
# verify the settings persist before completing the test with Draw & Exit.
# The settings window must not contain pitch, intensity, or contour controls.
sound = Create Sound from formula: "test", 1, 0, 0.5, 44100, "0.2*sin(2*pi*120*x)"
grid = Create TextGrid: 0, 0.5, "words points", "points"
selectObject: grid
Insert boundary: 1, 0.1
Insert boundary: 1, 0.4
Set interval text: 1, 2, "word"
Insert point: 2, 0.2, "point"
selectObject: sound, grid
runScript: "../plotScripts/spectro_plus.praat"
assert selected("Sound") = sound
assert selected("TextGrid") = grid
removeObject: {sound, grid}
writeInfoLine: "Spectrogram interactive smoke test passed."
