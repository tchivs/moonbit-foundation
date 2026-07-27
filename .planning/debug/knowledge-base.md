---
status: complete
type: resolved-debug-knowledge-base
updated: 2026-07-28
---

# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## required-colr-manifest-cwd — PNG structural generation wrote platform newlines into the shared manifest
- **Date:** 2026-07-27
- **Error patterns:** `Failed to canonicalize input filter directory README.missing.mbt.md`, `Generated artifact is stale or non-deterministic: fixtures/manifest.json`, COLR deterministic generated evidence, CRLF manifest drift
- **Root cause(s):** code: `Generate-PngStructuralVectors.ps1` writes raw platform-newline `ConvertTo-Json` text into the shared manifest; environment: Windows emits CRLF, producing raw bytes that violate the repository LF contract while Git filtering hides the drift
- **Fix:** added a platform-independent canonical text helper with CRLF/LF/no-terminal/repeated-terminal boundary self-tests and routed the PNG structural manifest write through it
- **Files changed:** `scripts/fixtures/Generate-PngStructuralVectors.ps1`
- **Why not caught:** the generator's existing checks covered fixture identity, digest, and generated tables but had no boundary contract for manifest newline bytes; Git normalization hid the raw-byte drift until a later deterministic generator compared the manifest
- **Recurrence guard:** `Assert-CanonicalTextContract` in `scripts/fixtures/Generate-PngStructuralVectors.ps1` exercises CRLF, LF, missing-terminal-newline, and repeated-terminal-newline inputs before every generation/check, while `ConvertTo-CanonicalText` enforces exactly one terminal LF at the manifest writer boundary
---
