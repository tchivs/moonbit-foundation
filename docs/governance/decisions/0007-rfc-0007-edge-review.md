# Edge Review Record: RFC 0007 (mb-layout)

> **Historical record.** The edge-review process this file records was a mandatory precondition of the `sole-project-owner-bootstrap` acceptance route, which was removed from the [RFC process](../../rfcs/README.md) on 2026-07-23. This edge review is retained as a genuine architectural review of RFC 0007, but it is **no longer a mandatory acceptance precondition** — no acceptance route exists in the simplified process. The "Acceptance-route note" below should be read as a description of the now-removed machinery, not a live requirement.

- **RFC:** 0007 — mb-layout Charter
- **RFC status at review time:** Proposed
- **Review date:** 2026-07-23
- **Reviewer:** edge-review (recorded under rfc-process §8)
- **Effect of this record:** Records the two mandatory edge reviews. Does NOT advance RFC 0007; it remains Proposed until an acceptance route is satisfied.

## Edge review results

- `EDGE-GOV-01-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed:
  module identity `tchivs/mb-layout` in the Document and Scene Layer; the three downward edges
  (`mb-layout` -> `{mb-text, mb-image, mb-core}`) and the explicit non-edges (`mb-color`,
  `mb-canvas`, `mb-font` — font metrics reached only transitively through `mb-text`); the
  paragraph-vs-document-flow boundary (§3.1: text owns line-breaking within a paragraph; layout
  owns block placement across pages/regions; layout never shapes glyphs or breaks lines itself);
  layout-vs-rendering (§3.2); layout-vs-document-format (§3.3); layout-vs-canvas-clip (§3.4); the
  portable seam (§5, no native accelerator anticipated for v0.x but the seam preserved); the v0.x
  subset (block flow, page model, pagination, multi-column, basic floats IN; CSS flexbox/grid,
  cascade, rich content DEFERRED) with binding deferral; and the accepted-RFC gate. Result: no
  material architectural omission or blocking objection was found; every reviewed boundary is
  explicit, dependency direction is downward-only, and deferred items are named rather than silently
  decided. Non-blocking observations (recorded for acceptance attention, none blocking at Proposed):

  1. **Measurement contract (strongest candidate finding).** The public cross-module seam between
     `mb-layout` and `mb-text` — the "shaped-run reference", the "height-at-width query", and the
     per-line wrap-contour feedback — is described only in prose (§2, §4.1); its exact
     signature/type is deferred under §11. The entire module's value depends on this interface,
     which IS the public seam to `mb-text`. §11 says deferred items are acceptable unless they
     affect "module boundary, dependency direction, or portability seam", which is arguable here.
     Recommendation: the measurement protocol should be minimally specified before the edge is
     accepted (potential blocker if pressed), OR explicitly affirmed as an acceptable §11-deferred
     internal detail. Recorded as non-blocking but flagged for acceptance attention.
  2. **"shaped-run reference" type undefined.** The type is not defined and is owned by `mb-text`;
     cross-RFC contract coupling exists without a named interface.
  3. **Float↔measurement feedback loop.** The loop (layout computes wrap contour -> text measures
     against contour -> layout places) is described but not formalized as a contract; "circular
     float dependencies" is listed as hostile input (§7), but the legitimate float↔measurement
     feedback boundary itself is not nailed down.
  4. **Reverse/cyclic/self-edge prohibition implicit.** The prohibition is not re-stated in
     RFC 0007; it is inherited from RFC 0001 §5. Defensible but implicit rather than explicit — a
     weaker posture than RFC 0001's own charter.
  5. **§9 pipeline-coherence claim is conditional.** The "completes the Document and Scene Layer /
     end-to-end coherent pipeline" claim depends on RFCs 0002/0004/0005/0006 also being Accepted;
     their status is not asserted here. If any is not Accepted, the claim is conditional. Minor.

- `EDGE-GOV-02-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed:
  RFC status (Proposed); the header's conservative honesty versus RFC 0001's Accepted header
  (claims nothing not earned: no route, no approvals, no evidence, review open); the transition
  ledger (only Draft -> Proposed recorded); the closed failure mode; and header/ledger/index
  agreement on Proposed. Result: no omitted transition or authority case, and no blocking objection.
  Non-blocking forward-looking finding: the `sole-project-owner-bootstrap` route (§4.3 / Decision
  0001) is scoped "RFC 0001 only" and its preauthorization has been consumed
  (`AUTH-NO-LATER-APPROVAL`); RFC 0007 cannot reuse it. Authority is named as `sole-project-owner`
  (identity, not approval). To advance, RFC 0007 must satisfy either (a) the project-lead
  public-review route (§4.2: ≥7-day window + project-lead approval) or (b) the maintainer route
  (§4.1, currently unavailable). This is a live authority gap at acceptance, not a Proposed-header
  defect.

- Unresolved blocking objections: **none**.

## Charter revisions prompted by this review

- None. RFC 0007 required no charter revision.

## Acceptance-route note (does not advance the RFC)

This record satisfies the §8 requirement that both mandatory edge reviews be recorded before
acceptance. It does not advance RFC 0007, which remains Proposed. The `sole-project-owner-bootstrap`
acceptance route is unavailable to RFC 0007: Decision 0001 scoped that preauthorization to RFC 0001
only and it has been consumed. The two remaining acceptance routes are the project-lead public-review
route (§4.2: a public review window of no less than seven days followed by recorded project-lead
approval) and the maintainer route (§4.1, currently unavailable under the one-maintainer roster).
Before any acceptance, the EDGE-GOV-01 measurement-contract observation (item 1) should be resolved
— either by minimally specifying the `mb-layout`↔`mb-text` measurement protocol or by explicitly
affirming it as an acceptable §11-deferred internal detail — and the §9 pipeline-coherence claim
should be reconciled with the actual status of RFCs 0002/0004/0005/0006.
