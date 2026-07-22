---
status: resolved
trigger: "Gray16 Fixed replay after acknowledged bytes and U16 source mutation must return the required sticky replay error without writing the current lease."
created: "2026-07-22T00:00:00Z"
updated: "2026-07-22T00:00:00Z"
---

# Phase 48 Gray16 Fixed replay lease overflow

## Symptoms

- Expected: after accepted output, a Gray16 source mutation makes the next replay pull fail with zero written bytes, unchanged accepted progress, and a sticky terminal error.
- Actual before the fix: native execution exits `0xc0000409`; generated native source maps this to the RED assertion `png gray16 replay first terminal`, not a stack overflow.
- Reproduction: run `moon -C modules/mb-image test png --target native --frozen --filter 'PNG Gray16 Fixed and Dynamic replay mutations are sticky'`.
- Timeline: discovered while closing Phase 48 code-review finding WR-01; the Gray8 equivalent passes.

## Current Focus

- resolved: the Gray16 Fixed replay validates its admitted plan before another source-derived byte can enter a caller lease.
- next_action: none; native focused and package verification passed.

## Evidence

- timestamp: 2026-07-22
  note: One-byte post-mutation pulls and fixed seven-byte leases both reproduce the `0xc0000409` fast-fail after a 43-byte accepted prefix, so the fault is not the lease shape.
- timestamp: 2026-07-22
  note: The generated native test source shows the fast-fail is the RED assertion `png gray16 replay first terminal`: end-of-stream replay fingerprint validation occurs after a seven-byte pull has already acknowledged bytes and modified its lease.
- timestamp: 2026-07-22
  note: `PngEncodeMachine::validate_gray16_fixed_replay` reruns the bounded scalar Fixed traversal and compares its existing `matcher_work` and fingerprint with the admitted plan before a Gray16 Fixed replay pull writes a lease.

## Eliminated

- hypothesis: the overflow is caused solely by one-byte post-mutation leases
  evidence: fixed seven-byte post-mutation leases reproduce the same `0xc0000409` exit.
- hypothesis: Gray16 `PngFilteredMatchCursor` initialization alone causes the failure
  evidence: temporarily bypassing that cursor did not change the focused failure; the diagnostic remained the first-terminal lease assertion.

## Resolution

- root_cause: Fixed replay detected a post-acknowledgement U16 source mutation only at its existing end-of-stream `matcher_work`/fingerprint comparison. A multi-byte caller pull had already written and acknowledged bytes, while `PngChunkEncoder::pull` returned the terminal result as zero bytes.
- fix: Before a Gray16 Fixed replay pull with source bytes already in flight, recompute the bounded profile-aware Fixed traversal and compare its `matcher_work` and fingerprint to the admitted plan. On mismatch, transition directly to the existing sticky failure state before touching the caller lease.
- verification: `moon -C modules/mb-image test png --target native --frozen --filter 'PNG Gray16 Fixed and Dynamic replay mutations are sticky'` passed; `moon -C modules/mb-image test png --target native --frozen` passed (188/188).
- files_changed: `modules/mb-image/png/stream_encode_test.mbt` (RED reproducer, `d9862c4`); `modules/mb-image/png/stream_encode.mbt` (GREEN fix, `4b47472`); this session record.
