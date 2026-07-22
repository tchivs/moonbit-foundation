# Phase 8: Ordered Mooncakes Publication and Registry Consumers - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-18
**Phase:** 8-ordered-mooncakes-publication-and-registry-consumers
**Areas discussed:** Executable live seam, one-module publication cadence, exact cold registry consumers, propagation and ambiguity, public metadata evidence

---

## Executable Live Seam

| Option | Description | Selected |
|--------|-------------|----------|
| Complete and verify the live seam first | Build the real prepared bundle, adapter, ephemeral credential state, and isolation before dispatch | ✓ |
| Dispatch the Phase 7 skeleton | Attempt the current structurally validated but placeholder workflow | |
| Publish locally | Bypass the hosted intent and journal control plane | |

**User's choice:** Auto-selected the recommended first option under the user's standing instruction to choose the optimal solution.
**Notes:** Current workflow writes `{}` but later requires at least eleven payloads, passes no live adapter, and does not export `MOON_HOME`. No tag or dispatch is allowed until these gaps close.

---

## One-Module Publication Cadence

| Option | Description | Selected |
|--------|-------------|----------|
| One module per run | Publish only the next module, then stop for observation and consumer proof | ✓ |
| All three in one run | Publish the full graph without independent external gates | |
| Manual local sequence | Run three local publishes outside the hosted journal | |

**User's choice:** Auto-selected one module per run.
**Notes:** This is the smallest irreversible unit and preserves Phase 7's monotonic one-step state machine.

---

## Exact Cold Registry Consumers

| Option | Description | Selected |
|--------|-------------|----------|
| Cold external consumer plus resolved-graph assertion | Empty Moon home, repository-external consumer, exact observed graph and archive evidence | ✓ |
| Workspace consumer | Reuse local members or `moon.work` | |
| Warm-cache build | Accept success from an existing registry cache | |

**User's choice:** Auto-selected the cold external proof.
**Notes:** A `0.1.0` dependency is an MVS floor, not sufficient evidence that the selected version is exactly `0.1.0`.

---

## Propagation and Ambiguity

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded observation then stop | Poll read-only surfaces, record a terminal disposition, and stop on ambiguity | ✓ |
| Immediate republish | Retry after timeout/nonzero without proving absence | |
| Continue downstream | Publish a dependent module before predecessor proof | |

**User's choice:** Auto-selected bounded observation then stop.
**Notes:** Only fresh read-only absence evidence plus renewed authorization may permit a retry.

---

## Public Metadata Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Public API/assets evidence | Compare structured manifest, index, archive, and versioned assets | ✓ |
| SPA HTML scraping | Treat the client-rendered page shell as machine authority | |
| Manual screenshot only | Human visual confirmation without exact structured comparison | |

**User's choice:** Auto-selected structured public evidence.
**Notes:** All observation surfaces must agree with the qualified source; missing or ambiguous required metadata fails closed.

## the agent's Discretion

- Exact bounded polling cadence.
- Exact closed-schema filenames and consumer package layout.
- Internal helper boundaries for API, index, archive, assets, and graph normalization.

## Deferred Ideas

- Phase 9 immutable provenance ledger and milestone closure.
- Organization namespace migration, destructive recovery, multi-maintainer ceremony, and new module families.
