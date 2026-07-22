---
status: awaiting_human_verify
trigger: "Phase 8 r6 HostedPreflight run 29671691604/1 prepare job 88151792308 failed P08-PREPARED-INTENT-BINDING"
created: 2026-07-19
updated: 2026-07-19
---

# Debug: Phase 08 Cross-Platform Prepared ZIP

## Symptoms

- Immutable r6 boundary: `c05cacb`.
- Windows local preparation produced intent prefix `b5359f` and prepared prefix `36f91f`.
- Linux hosted requalification produced intent prefix `5ad505`.
- ZIP bytes and digests differ for all three modules; downstream jobs did not run.
- Suspected nondeterminism includes ZIP timestamps, path separators, entry ordering, compression, and platform metadata.

## Current Focus

reasoning_checkpoint:
  hypothesis: "Missing repository EOL attributes cause Git to materialize different text bytes under Windows/Linux checkout policies; moon package faithfully archives those bytes, changing archive and derived intent digests."
  confirming_evidence:
    - "The same commit/toolchain produced different archives under only core.autocrlf=true versus false, with 35 decompressed text payloads differing."
    - "ZIP timestamps and external attributes were identical, excluding the initially suspected container metadata fields."
    - "The new focused test is RED with REL-XPLAT-EOL because no committed LF checkout contract exists."
  falsification_test: "After adding only a text=auto/eol=lf repository contract, dual-policy clones must package byte-identical archives and identical entry metadata/payloads; any remaining byte drift disproves EOL policy as sufficient."
  fix_rationale: "Pinning checkout text bytes to LF removes the causal platform variable before packaging while preserving tracked/source/archive byte provenance; it avoids rewriting archive content after qualification."
  blind_spots: "The focused test packages mb-core as the representative module; full qualification and prepared/consumer suites must verify all three modules and downstream contracts."

**Next Action:** Re-run the real hosted r7 preflight from a newly pushed immutable boundary and confirm `P08-PREPARED-INTENT-BINDING` no longer occurs; local verification is complete and no remote action was performed here.

## Evidence

- timestamp: 2026-07-19T00:00:00+08:00
  observation: HostedPreflight prepare job 88151792308 failed with P08-PREPARED-INTENT-BINDING before downstream execution.
  source: supplied run metadata

- timestamp: 2026-07-19T00:10:00+08:00
  checked: release qualification and hosted preparation paths
  found: Both `Invoke-ReleaseQualification.ps1` and hosted/workflow preparation consume raw `moon package` ZIP bytes; qualification only compares two clean copies on the same host and performs no cross-platform canonicalization before archive digests enter the release intent.
  implication: Same-host repeatability can pass while Windows/Linux ZIP metadata or encoding differences change all archive digests and therefore the intent digest.

- timestamp: 2026-07-19T00:15:00+08:00
  checked: existing local Moon ZIP metadata and Git checkout policy
  found: Moon entries already use fixed 1980 timestamps and stable-looking Unix external attributes, but the repository has no `.gitattributes`, global `core.autocrlf=true`, index content is LF, and module manifests show mixed working-tree EOLs.
  implication: Checkout byte normalization is a simpler falsifiable cause than ZIP timestamp/platform defaults and must be tested first.

- timestamp: 2026-07-19T00:20:00+08:00
  checked: isolated dual checkout/package experiment at the same `c05cacb` commit and pinned local Moon toolchain
  found: `core.autocrlf=true` produced mb-core SHA-256 `2d8c3179...` (38168 bytes), while `false` produced `8029970a...` (37794 bytes); 35 decompressed text entries differ, with identical fixed timestamps and external attributes.
  implication: Root cause is confirmed as checkout EOL drift entering package payload bytes; a ZIP rewriter would alter provenance semantics and is unnecessary if committed LF checkout policy makes source bytes identical.

- timestamp: 2026-07-19T00:25:00+08:00
  checked: `scripts/quality/Test-CrossPlatformReleaseArchive.ps1` before the fix
  found: Test failed RED with `REL-XPLAT-EOL`, proving the repository lacks the required checkout-byte contract before it attempts the dual-policy package assertion.
  implication: The regression test captures the missing invariant and is ready for the minimal GREEN change.

- timestamp: 2026-07-19T00:30:00+08:00
  checked: first GREEN run after adding `.gitattributes`
  found: Both package commands succeeded, but the test assumed the full workspace output location; its module-only fixture writes the archive under the module-local `_build`, so the assertion stopped at `REL-XPLAT-ARCHIVE` before comparing bytes.
  implication: This is a focused-test path bug, not evidence against the EOL fix; discover the unique expected archive by filename in each isolated clone.

- timestamp: 2026-07-19T00:32:00+08:00
  checked: second GREEN attempt after fixing archive discovery
  found: The module-only fixture omitted the repository `.gitignore`, so `moon package` included generated `_build/native/...` files whose local build evidence differed.
  implication: The fixture must preserve the repository's tracked package-exclusion semantics before it can test source checkout determinism.

- timestamp: 2026-07-19T00:35:00+08:00
  checked: focused cross-platform archive regression after `.gitattributes`
  found: `core.autocrlf=true` and `false` clones now produced byte-identical mb-core archives with SHA-256 `8029970aa96774627b0aec5c3b4a9293dbffe428e0b8b1624ff16b0f9a8609b3`; all entry payloads, order, timestamps, and attributes matched.
  implication: The minimal LF checkout contract is sufficient for the reproduced cross-platform nondeterminism; a canonical ZIP writer is not required.

- timestamp: 2026-07-19T00:45:00+08:00
  checked: adjacent regression suites before commit
  found: Prepared bundle, Phase 8 qualification composition, publisher reducer/recovery negatives, Phase 8 live adapter/dispatch/workflow fixtures, Mooncakes observation, and scoped `git diff --check` all passed.
  implication: The checkout policy does not alter prepared manifest semantics, authority/reducer behavior, live-seam guards, or observation contracts.

- timestamp: 2026-07-19T01:00:00+08:00
  checked: full committed-HEAD `Invoke-ReleaseQualification.ps1 -Check`
  found: All three modules passed clean-copy list/hash/byte/archive/manifest and consumer isolation checks. Canonical digests were mb-core `8029970a...`, mb-color `9c672c24...`, and mb-image `bcec6a9d...`; the derived intent binding was `4207e8dd...`.
  implication: The fix works across qualification's real clean-clone path for every prepared archive and preserves release intent/provenance semantics.

## Constraints

- No push, tag, GitHub/network access, secret access, StateRoot mutation, registry access, or publication.
- Do not move r6, plan r7, or include unrelated dirty files.
- Preserve provenance and prepared-manifest semantics.

## Resolution

**Root Cause:** The repository lacked a committed EOL policy, so Windows `core.autocrlf=true` clean clones fed CRLF text bytes to `moon package` while hosted Linux fed LF bytes. Moon's otherwise deterministic ZIP writer archived those different source bytes, changing all module archive digests and the derived r6 intent digest.

**Fix:** Add a repository-wide `text=auto eol=lf` contract and a dual-checkout package regression that verifies byte-identical ZIPs and entry payload/metadata across opposing `core.autocrlf` settings.

**Verification:** RED reproduced with `REL-XPLAT-EOL`; GREEN dual-checkout archive SHA-256 `8029970a...` matched byte-for-byte. Prepared, Phase 8 qualification, publisher, live-seam, observation, diff, and full committed-HEAD three-module release qualification all passed. Real hosted confirmation remains the human/environment verification boundary.
