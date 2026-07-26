## OUTLINE COMPLETE

| Plan ID | Objective | Wave | Depends On | Requirements |
|---|---|---:|---|---|
| 97-01 | Establish the portable `tchivs/mb-font` module and a production-quality tracer that opens one minimal valid standalone `0x00010000` TrueType SFNT from retained immutable bytes under `FontLimits` and `Budget`, then exposes one named global metric through the opaque `Font` API. | 1 | — | FONT-01 |
| 97-02 | Expand the tracer into strict atomic directory and cross-table admission: checked table-local windows, canonical directory facts, alignment/non-overlap/checksums, required-table/profile validation, bounded core-table facts, and separately named global bounds plus `hhea` and `OS/2` typographic line metrics. | 2 | 97-01 | FONT-01 |
| 97-03 | Complete opaque glyph IDs and per-glyph horizontal metrics, including `hmtx` tail advances, short/long `loca`, empty-glyph bounds, checked right-side bearing, revision-drift and budget atomicity, deterministic repeated/independent query behavior, four-target tests, interface review, and workspace/policy/documentation integration. | 3 | 97-02 | FONT-01 |
