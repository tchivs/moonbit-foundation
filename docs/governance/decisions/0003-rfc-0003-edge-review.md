# Edge Review Record: RFC 0003 (mb-canvas)

> **Historical record.** The edge-review process this file records was a mandatory precondition of the `sole-project-owner-bootstrap` acceptance route, which was removed from the [RFC process](../../rfcs/README.md) on 2026-07-23. This edge review is retained as a genuine architectural review of RFC 0003, but it is **no longer a mandatory acceptance precondition** — no acceptance route exists in the simplified process. The "Acceptance-route note" below should be read as a description of the now-removed machinery, not a live requirement.

- **RFC:** 0003 — mb-canvas Charter
- **RFC status at review time:** Proposed
- **Review date:** 2026-07-23
- **Reviewer:** edge-review (recorded under rfc-process §8)
- **Effect of this record:** Records the two mandatory edge reviews. Does NOT advance RFC 0003; it remains Proposed until an acceptance route is satisfied.

## Edge review results

- `EDGE-GOV-01-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed: module identity `tchivs/mb-canvas` in the Graphics Layer; the three downward edges (mb-canvas -> {mb-image, mb-color, mb-core}), mirroring the already-accepted mb-image edges; the compositing-delegation boundary (§3.3, §4.1, §9 rejection 3 — canvas delegates raster-raster composite to `mb-image/ops::composite_source_over` and does not re-own it); the image-vs-canvas cut (§3.1: two-rasters-in -> image/ops; geometry-into-raster -> canvas); the canvas-vs-svg cut (§3.2: canvas is format-neutral); the drawing-list contract (§5: pure-data, value-typed, append-only, deterministic); the portable reference rasterizer plus native leaf (§6); binding v0.x deferral (§7.2); and the accepted-RFC gate. Result: no material architectural omission or blocking objection found. Non-blocking observations: G1–G4.
- `EDGE-GOV-02-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed: RFC status (Proposed); header honesty (header claims no route, no approvals, no evidence; review open); ledger transitions (only `-> Draft -> Proposed` recorded); fails-closed behavior; and header/ledger/index agreement on Proposed. Result: no omitted transition or authority case; no blocking objection. Non-blocking forward-looking finding: sole-owner route is unavailable to RFC 0003 — the sole-project-owner-bootstrap route (§4.3 / Decision 0001) is scoped "Applies to: RFC 0001 only" and its preauthorization (`AUTH-NO-LATER-APPROVAL`) was consumed by RFC 0001, so RFC 0003 must instead advance via the project-lead public-review route (§4.2: real ≥7-day window + project-lead approval); the maintainer route (§4.1) is unavailable (one maintainer). This is not a defect in the Proposed header; it is the live authority gap for the acceptance step. Cosmetic: A1.
- Unresolved blocking objections: **none**.

## Non-blocking observations (EDGE-GOV-01)

None of the following is a boundary violation. Each is a gap the RFC could make explicit.

1. **(G1) Inbound consumer edges undeclared.** Inbound consumer edges (mb-svg / mb-pdf / mb-layout -> mb-canvas) are implied by §3.2 and §10 but declared nowhere — RFC 0003 declares only its own outbound edges. Recommend a footnote that canvas does not pre-authorize consumer inbound edges; those are owned by each consumer's RFC.
2. **(G2) Deferred-raster-op contract is implicit.** The contract for "a consumer wants a raster op canvas defers" (e.g. a gradient fill) is not stated in RFC 0003. The implicit fallback is that the consumer uses its own image-raster path per RFC 0002 §7.2 option 2, or waits for a scope-widening RFC.
3. **(G3) Rasterizer threading/reentrancy unspecified.** Whether `render(list, target)` is safe on disjoint targets is not specified. This is internal per §12, but a one-line reentrancy statement would help.
4. **(G4) Resource-budget supplier unnamed.** Who supplies the resource budget to a render call (caller / canvas / core defaults) is not named — a runtime-contract seam.

## Non-blocking observations (EDGE-GOV-02)

**Critical forward-looking finding — sole-owner route unavailable.** The sole-project-owner-bootstrap route (§4.3 / Decision 0001) is scoped "Applies to: RFC 0001 only", and its preauthorization was consumed by RFC 0001 (`AUTH-NO-LATER-APPROVAL`). RFC 0003 cannot reuse it. To advance, RFC 0003 must take one of:

- (a) **Project-lead public-review route (§4.2)** — a real, announced public-review window of no less than seven days, followed by project-lead approval; or
- (b) **Maintainer route (§4.1)** — currently unavailable, because there is only one maintainer.

This is not a defect in the Proposed header (the header honestly claims no route/approvals/evidence); it is the live authority gap for the *acceptance* step, surfaced here so it is not discovered late.

**Cosmetic note (A1).** The ledger's "no transition to Accepted, Implemented, Rejected, or Superseded" lists `Implemented`, which is not a legal *direct* next state from Proposed. This mirrors RFC 0001's own phrasing and is non-blocking.

## Charter revisions prompted by this review

- None. RFC 0003 required no charter revision. (The review found it the most carefully drawn of the charters.)

## Acceptance-route note (does not advance the RFC)

This record does NOT advance RFC 0003; the RFC remains Proposed. The two mandatory edge reviews (EDGE-GOV-01, EDGE-GOV-02) are now recorded with disposition **no-omission-found** and **no blocking objections**. However, satisfying §8's edge-review requirement is necessary but not sufficient for acceptance: RFC 0003 still needs a valid acceptance route. As noted above, the sole-project-owner-bootstrap route is exhausted (scoped to RFC 0001, preauthorization consumed), and the maintainer route is unavailable (single maintainer). The available path is the project-lead public-review route (§4.2): a genuine, announced ≥7-day public-review window followed by project-lead approval. Until that route (or a future newly-available route) is satisfied, RFC 0003 stays Proposed.
