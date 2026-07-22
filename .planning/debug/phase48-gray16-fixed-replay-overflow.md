---
status: resolved
trigger: "Gray16 Fixed replay after acknowledged bytes and U16 source mutation must return the required sticky replay error without writing the current lease."
created: "2026-07-22T00:00:00Z"
updated: "2026-07-22T00:00:00Z"
---

# Phase 48 Gray16 Fixed and Dynamic replay guard

## Symptoms

- Expected: after accepted output, a Gray16 source mutation makes the next replay pull fail with zero written bytes, unchanged accepted progress, and a sticky terminal error.
- Actual before the fix: native execution exits `0xc0000409`; generated native source maps this to the RED assertion `png gray16 replay first terminal`, not a stack overflow.
- Reproduction: run `moon -C modules/mb-image test png --target native --frozen --filter 'PNG Gray16 Fixed and Dynamic replay mutations are sticky'`.
- Timeline: discovered while closing Phase 48 code-review finding WR-01; the Gray8 equivalent passes.

## Current Focus

- resolved: Gray16 Fixed and Dynamic replay compare an O(1) retained source mutation revision before writing each caller lease.
- next_action: none; focused replay, full PNG, and bytes verification passed.

## Evidence

- timestamp: 2026-07-22
  note: One-byte post-mutation pulls and fixed seven-byte leases both reproduce the `0xc0000409` fast-fail after a 43-byte accepted prefix, so the fault is not the lease shape.
- timestamp: 2026-07-22
  note: The generated native test source shows the fast-fail is the RED assertion `png gray16 replay first terminal`: end-of-stream replay fingerprint validation occurs after a seven-byte pull has already acknowledged bytes and modified its lease.
- timestamp: 2026-07-22
  note: `PngEncodeMachine::validate_gray16_fixed_replay` reruns the bounded scalar Fixed traversal and compares its existing `matcher_work` and fingerprint with the admitted plan before a Gray16 Fixed replay pull writes a lease.
- timestamp: 2026-07-22
  note: Second code review found Dynamic has no pre-lease drift guard and Fixed rebuilds the complete plan on every active pull.
- timestamp: 2026-07-22
  note: Added a periodic 128-pixel U16 Gray corpus for `DynamicOrFixedOrStored`; its acknowledged prefix proves BTYPE=10 with `(prefix[43] & 0x07) == 0x05`, then its next seven-byte lease fails zero-byte/sticky after `set_component_byte`.
- timestamp: 2026-07-22
  note: `OwnedBytes` now retains one shared scalar mutation revision through `ByteView`, `ImageView`, and callback-scoped mutable leases. Successful writes advance it; normal reads and small PNG leases do not.
- timestamp: 2026-07-22
  note: `PngEncodeMachine` freezes the source revision after preflight. Its Gray16 Fixed/Dynamic pull guard compares only the current scalar revision, replacing the full `_png_fixed_plan_with_interlace` traversal while retaining the terminal matcher-work/fingerprint checks.

## Eliminated

- hypothesis: the overflow is caused solely by one-byte post-mutation leases
  evidence: fixed seven-byte post-mutation leases reproduce the same `0xc0000409` exit.
- hypothesis: Gray16 `PngFilteredMatchCursor` initialization alone causes the failure
  evidence: temporarily bypassing that cursor did not change the focused failure; the diagnostic remained the first-terminal lease assertion.

## Resolution

- root_cause: Dynamic had no pre-lease replay guard, while Fixed recomputed the entire source plan on every active pull. The storage/view stack exposed no shared mutation identity, so the encoder could not distinguish normal small leases from an externally changed source without replanning.
- fix: Add a monotonic owned-backing mutation revision, retain it through byte/image views, and freeze it at PNG preflight completion. Gray16 Fixed/Dynamic replay returns its existing route-specific sticky drift error before writing when the revision differs; Stored and legacy/Gray8 behavior remains unchanged.
- verification: Dynamic RED failed before the fix with `0xc0000409` at the first-terminal assertion. Focused replay passed after the fix; `moon -C modules/mb-image test png --target native --frozen` passed (188/188); `moon -C modules/mb-core test bytes --target native --frozen` passed (16/16).
- files_changed: `modules/mb-core/bytes/views.mbt`; `modules/mb-core/bytes/owned_bytes.mbt`; `modules/mb-image/storage/views.mbt`; `modules/mb-image/png/stream_encode.mbt`; `modules/mb-image/png/stream_encode_test.mbt`; this session record.
