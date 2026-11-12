aeroPrototypeInclude = 1
grid = Create TextGrid: 0, 1, "Segment IPA Element", "IPA Element"
Insert boundary: 1, 0.2
Insert boundary: 1, 0.8
Set interval text: 1, 2, "vowel"
Insert point: 2, 0.3, "a"
Insert point: 2, 0.7, "b"
Insert point: 3, 0.3, "1"
Insert point: 3, 0.7, "2"

ui.lowestTier$ = "3"
ui.otherTiers$ = "1, 2"
ui.vowelDur$ = "1"
ui.baseTierTimeOnly = 1
ui.formants2tabulate = 2
@resolveTableTierSettings: grid
assert ui.lowestTier$ = "Element"
assert ui.otherTiers$ = "Segment,IPA"
assert ui.vowelDur$ = "Segment"
@tiers2Table: grid, "'ui.lowestTier$','ui.otherTiers$'", "durationResult"
selectObject: durationResult
rows = Get number of rows
duration1 = Get value: 1, "Segment_dur"
duration2 = Get value: 2, "Segment_dur"
assert rows = 2
assert abs(duration1 - 0.6) < 0.0001
assert abs(duration2 - 0.6) < 0.0001
removeObject: durationResult
ui.lowestTier$ = "Element"
ui.otherTiers$ = "Segment, IPA"
ui.vowelDur$ = "Segment"
@resolveTableTierSettings: grid
@tiers2Table: grid, "'ui.lowestTier$','ui.otherTiers$'", "namedResult"
selectObject: namedResult
namedDuration = Get value: 1, "Segment_dur"
assert namedDuration = duration1
removeObject: namedResult

# Tiers inside the base tier cannot fill columns; tiers containing it can.
@tierNested: grid, 3, 1
assert tierNested.ok = 1
@tierNested: grid, 3, 2
assert tierNested.ok = 1
@tierNested: grid, 1, 2
assert tierNested.ok = 0
@tierNested: grid, 1, 3
assert tierNested.ok = 0
@tierNested: grid, 2, 1
assert tierNested.ok = 1
asserterror lies inside the base tier
runScript: "table_tier_reference_error.praat", "lowerTier"

# With soft errors the problem is reported and the settings stay as entered.
aeroSoftErrors = 1
ui.lowestTier$ = "Segment"
ui.otherTiers$ = "IPA"
ui.vowelDur$ = ""
@resolveTableTierSettings: grid
assert index(resolveTableTierSettings.error$, "lies inside the base tier") > 0
assert ui.lowestTier$ = "Segment"
assert ui.otherTiers$ = "IPA"
ui.otherTiers$ = "99"
@resolveTableTierSettings: grid
assert index(resolveTableTierSettings.error$, "no tier matches") > 0
ui.lowestTier$ = "Element"
ui.otherTiers$ = "Segment"
ui.vowelDur$ = "IPA"
@resolveTableTierSettings: grid
assert index(resolveTableTierSettings.error$, "must identify an interval tier") > 0
aeroSoftErrors = 0

@resolveTierReference: grid, " Segment ", "Test", "interval"
assert resolveTierReference.tier = 1
@resolveTierReference: grid, "2", "Test", "point"
assert resolveTierReference.name$ = "IPA"
asserterror no tier matches
runScript: "table_tier_reference_error.praat", "missing"
asserterror must identify a point tier
runScript: "table_tier_reference_error.praat", "point"
asserterror must identify an interval tier
runScript: "table_tier_reference_error.praat", "interval"

selectObject: grid
Set tier name: 2, "1"
asserterror Please rename the numeric tier
runScript: "table_tier_reference_error.praat", "ambiguous"
@resolveTierReference: grid, "2", "Test", "point"
assert resolveTierReference.name$ = "1"
selectObject: grid
Set tier name: 2, "99"
@resolveTierReference: grid, "99", "Test", "point"
assert resolveTierReference.tier = 2
selectObject: grid
Set tier name: 2, "1"
Set tier name: 3, "1"
asserterror multiple tiers are named
runScript: "table_tier_reference_error.praat", "duplicate"
removeObject: grid
writeInfoLine: "Table tier reference tests passed."

include ../plotScripts/nestedTiers2Table.praat
