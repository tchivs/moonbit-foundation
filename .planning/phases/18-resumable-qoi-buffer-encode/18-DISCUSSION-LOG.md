# Phase 18: Resumable QOI Buffer Encode - Discussion Log

> **Audit trail only.** Decisions are captured in `18-CONTEXT.md`.

**Date:** 2026-07-20
**Phase:** 18-Resumable QOI Buffer Encode
**Areas discussed:** output progress, preflight safety, source stability

---

## Output progress

| Option | Description | Selected |
|--------|-------------|----------|
| Private pending tokens | Supports every caller capacity without replaying or losing canonical bytes. | ✓ |
| Write directly from source each pull | Risks duplicate/reordered bytes across token boundaries. | |

**Choice:** private pending tokens (automatic best-fit selection).

## Source stability

| Option | Description | Selected |
|--------|-------------|----------|
| Caller keeps source unchanged | Zero-copy contract matching current image-view behavior. | ✓ |
| Implicit snapshot | Adds allocation and budget semantics outside this focused phase. | |

**Choice:** documented stable-source contract (automatic best-fit selection).

## Deferred Ideas

- Public streaming example and full evidence: Phase 19.
- Image snapshot/locking semantics: future dedicated contract.
