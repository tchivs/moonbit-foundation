# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## phase6-qualification-order — Release qualification ran before canonical identity prerequisites
- **Date:** 2026-07-17
- **Error patterns:** release policy identity repository fixture manifest drifted, manifest repository drifted, qualification ordering
- **Root cause:** Phase 6 omitted a prerequisite plan between 06-09 and 06-13 for the three manifest repository fields and the shared qualification helper, so 06-13 consumed mixed canonical and stale identity truth.
- **Fix:** Added bounded plan 06-25, rewired only pending dependencies and waves, removed duplicate later helper ownership, and preserved the partial 06-13 Task 1 commit with an explicit Task 2 resume handoff.
- **Files changed:** Phase 6 planning graph, ROADMAP.md, 06-25-PLAN.md, 06-13-DEFERRED.md
---
