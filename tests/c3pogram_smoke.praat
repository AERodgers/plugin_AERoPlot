# This smoke test is interactive because C3PoGram now uses a pause window.
# Run with the words tier displayed and crop set to Do not crop. Check that the
# tier touches the plot and its boundaries align with the corresponding times.
# Repeat with Show TextGrid boundaries off and on: only the dotted extensions
# over the plot should change. Reopen to check that this setting is remembered.
# Try different TextGrid fonts; these do not persist.
# Repeat with the words crop tier and with the points display tier.
# Use Draw to check that all settings, including F0 limits, both tier
# selections and the TextGrid font, remain selected. Draw & Exit completes the test.
sound = Create Sound from formula: "test", 1, 0, 0.5, 44100, "0.2*sin(2*pi*120*x)"
grid = Create TextGrid: 0, 0.5, "words points", "points"
selectObject: grid
Insert boundary: 1, 0.1
Insert boundary: 1, 0.4
Set interval text: 1, 2, "word"
Insert point: 2, 0.2, "point"

selectObject: sound, grid
runScript: "../plotScripts/c3pogram.praat"
assert selected("Sound") = sound
assert selected("TextGrid") = grid
removeObject: {sound, grid}
writeInfoLine: "C3PoGram interactive smoke test passed."
