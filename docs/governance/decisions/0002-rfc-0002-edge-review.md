# Edge Review Record: RFC 0002 (mb-svg)

> **Historical record.** The edge-review process this file records was a mandatory precondition of the `sole-project-owner-bootstrap` acceptance route, which was removed from the [RFC process](../../rfcs/README.md) on 2026-07-23. This edge review is retained because it is a genuine architectural review of RFC 0002 (it found and prompted the §7.1 mb-canvas factual-drift fix), but it is **no longer a mandatory acceptance precondition** — no acceptance route exists in the simplified process. The "Acceptance-route note" below should be read as a description of the now-removed machinery, not a live requirement.

- **RFC:** 0002 — mb-svg Charter
- **RFC status at review time:** Proposed
- **Review date:** 2026-07-23
- **Reviewer:** edge-review (recorded under rfc-process §8)
- **Effect of this record:** Records the two mandatory edge reviews. Does NOT advance RFC 0002; it remains Proposed until an acceptance route is satisfied.

## Edge review results

- `EDGE-GOV-01-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed:
  the module identity `tchivs/mb-svg` in the Document and Scene Layer; the three declared downward
  public dependency edges (`mb-svg` -> `{mb-image, mb-color, mb-core}`); the deferred/conditional
  `mb-canvas` edge as a non-hard initial dependency rather than an undeclared hard edge; the
  explicit prohibition of reverse, cyclic, self, and undeclared public edges; the deferred-layer
  rule (RFC 0001 §6.4) as the citation for deferred dependencies; owned vs excluded
  responsibilities and their non-overlap; the portability seam (portable core plus native-only leaf
  adapter); the v0.x subset scope with binding deferral; and the accepted-RFC gate (RFC 0001 §11).
  Result: no material architectural omission or blocking objection found. Non-blocking observations:
  (1) The §7.1 factual drift about `mb-canvas` — the charter previously stated `mb-canvas` had "no
  implementation, no accepted charter, and no module declaration," but RFC 0003 (mb-canvas) now
  exists at Proposed status; this is NOW RESOLVED by the charter revision prompted by this review
  (see "Charter revisions prompted by this review" below). (2) The future text-rendering re-entry
  edge — i.e., how `mb-svg` would gain an `mb-text` edge once advanced text rendering is
  un-deferred — is correctly held under §12 deferral but is not explicitly stated in the charter;
  this is acceptable for a charter-level document and is recorded here for traceability. (3) Two
  under-specified "documented minimum" inclusion seams in §6.2 (`<use>` shadow trees "beyond a
  documented minimum"; filters "beyond a documented minimum, if any") leave the "minimum"
  unspecified; non-blocking for a Proposed charter, but should be nailed down before either
  deferred category is un-deferred.
- `EDGE-GOV-02-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed:
  the RFC 0002 status (Proposed); the header's honest claim of no acceptance route, no approvals,
  no acceptance evidence, and review open; the transition ledger, which records only the
  `--` -> `Draft` -> `Proposed` transitions; the fails-closed behavior under PROV-GOV-02-EVIDENCE;
  and the agreement of header, ledger, and index on the Proposed state. Result: no omitted
  transition or authority case in the current header/ledger; no blocking objection. Non-blocking
  forward-looking finding: the `sole-project-owner-bootstrap` acceptance route (rfc-process §4.3 /
  Decision 0001) is scoped "Applies to: RFC 0001 only," and its preauthorization was already
  consumed by RFC 0001 (`AUTH-NO-LATER-APPROVAL`). Therefore RFC 0002 CANNOT reuse that route. To
  advance to Accepted, RFC 0002 must close the live authority gap at the acceptance step via either
  (a) the project-lead public-review route (§4.2: a real ≥7-day public review window with evidenced
  open/close plus project-lead approval) or (b) the maintainer route (§4.1: two distinct maintainer
  approvals — currently unavailable, as the roster holds a single maintainer). This is not a defect
  in RFC 0002's Proposed header, which correctly claims nothing; it is the authority gap the
  acceptance step must still close.
- Unresolved blocking objections: **none**.

## Charter revisions prompted by this review

- RFC 0002 §7.1: corrected the `mb-canvas` factual drift. The prior wording ("no implementation,
  no accepted charter, and no module declaration") was inaccurate after the filing of RFC 0003
  (mb-canvas) at Proposed status. The revised §7.1 now reads: `mb-canvas` has a Proposed charter
  (RFC 0003) but no Accepted charter, no implementation, and no module declaration. The §7.2
  two-option resolution remains valid because `mb-canvas` is not yet Accepted.

## Acceptance-route note (does not advance the RFC)

This record completes the two mandatory edge reviews required before any acceptance route may be
used, but it does NOT itself advance RFC 0002. The `sole-project-owner-bootstrap` route (Decision
0001) is unavailable to RFC 0002: it is scoped "Applies to: RFC 0001 only" and its one-time
preauthorization was consumed by RFC 0001 under `AUTH-NO-LATER-APPROVAL`. Accordingly, RFC 0002's
path to Accepted is the project-lead public-review route under rfc-process §4.2 — a genuine,
evidenced public review window of no fewer than seven days with recorded open/close timestamps and
project-lead approval — or, once the roster supports it, the two-distinct-maintainer route under
§4.1. Until one of those routes is satisfied with evidence, RFC 0002 correctly remains Proposed.
