form Tier reference error test
    sentence Case
endform

aeroPrototypeInclude = 1
grid = Create TextGrid: 0, 1, "Segment IPA Element", "IPA Element"
if case$ = "missing"
    @resolveTierReference: grid, "99", "Test", "any"
elsif case$ = "point"
    @resolveTierReference: grid, "Segment", "Test", "point"
elsif case$ = "interval"
    @resolveTierReference: grid, "IPA", "Test", "interval"
elsif case$ = "ambiguous"
    Set tier name: 2, "1"
    @resolveTierReference: grid, "1", "Test", "any"
elsif case$ = "duplicate"
    Set tier name: 2, "1"
    Set tier name: 3, "1"
    @resolveTierReference: grid, "1", "Test", "any"
else
    exitScript: "Unknown tier reference error test."
endif

include nestedTiers2Table.praat
