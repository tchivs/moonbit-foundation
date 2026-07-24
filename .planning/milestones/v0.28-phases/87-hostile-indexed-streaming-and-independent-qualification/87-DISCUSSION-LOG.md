# Phase 87: Hostile Indexed Streaming and Independent Qualification - Discussion Log

> **Audit trail only.** Decisions are captured in `87-CONTEXT.md`.

**Date:** 2026-07-24
**Phase:** 87-Hostile Indexed Streaming and Independent Qualification
**Areas discussed:** hostile caller leases, independent wire/decode oracle, compatibility and portability gates

---

## Hostile caller leases

| Option | Description | Selected |
|--------|-------------|----------|
| Existing acknowledged harness | Reuse present/acknowledge helpers and test zero, one-byte, and ragged schedules with sentinels. | ✓ |
| New stream abstraction | Add a separate qualification-only encoder or buffering layer. | |

**User's choice:** Recommended existing acknowledged harness (auto-selected).
**Notes:** Accepted-only progress, untouched tails, sticky release/replay failures, and zero-write terminal pulls are mandatory.

## Independent wire/decode oracle

| Option | Description | Selected |
|--------|-------------|----------|
| Test-local parser and public decoder | Parse eager and collected chunk-origin bytes independently, then public-decode coordinates. | ✓ |
| Eager parity only | Compare chunk bytes to eager output without independent framing/DEFLATE checks. | |

**User's choice:** Recommended independent parser (auto-selected).
**Notes:** The oracle must not call production planning, matcher, packing, frame, or preflight helpers.

## Compatibility and portability gates

| Option | Description | Selected |
|--------|-------------|----------|
| Frozen vectors plus explicit four-target package gates | Freeze legacy non-interlaced/Adam7 bytes and run native, wasm, wasm-gc, and js gates. | ✓ |
| Native-only qualification | Defer portable targets and compatibility vectors. | |

**User's choice:** Recommended full compatibility and target matrix (auto-selected).
**Notes:** Record concrete command results; skip only an unavailable pinned target with evidence.

## the agent's Discretion

- Keep the corpus and parser in the smallest existing test modules.
- Select exact target command syntax and test helper placement while preserving scope fences.

## Deferred Ideas

- Dynamic/adaptive/Adam7 indexed compression, source-model changes, FFI,
  copied trees, registry publication, and release automation remain deferred.
