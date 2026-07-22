---
status: resolved
trigger: "Required source inventory audit fails after the v0.2 milestone replaced the active REQUIREMENTS.md"
created: 2026-07-17
updated: 2026-07-17T15:49:38+08:00
---

# Debug Session: Required source audit after v0.2 transition

## Symptoms

- Expected behavior: `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required` passes without weakening the v0.1 Required contract.
- Actual behavior: Required reaches the Source inventory fail-closed matrix and rejects the canonical source audit.
- Error: `Source audit 'GOV-01' anchor 'charter-and-governance' does not exist in '.planning/REQUIREMENTS.md'.`
- Timeline: observed after v0.1 was archived and `.planning/REQUIREMENTS.md` became the v0.2 requirement set.
- Reproduction: run `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required` from the repository root.

## Current Focus

- hypothesis: Confirmed. The v0.1 ledger and reciprocal plan lookup used mutable active-milestone paths, and `Resolve-PhaseSourceAuditFile` preferred any existing active file before its archive fallback.
- test: Canonical and negative source-audit matrix plus the full Required controller.
- expecting: Historical v0.1 audit inputs are accepted only from the canonical v0.1 archive; mutable active paths fail closed.
- next_action: None. The debug session is resolved and verified.

## Evidence

- timestamp: 2026-07-17T15:43:00+08:00
  observation: Required reproduced the failure after all Phase 6 credential-free work passed focused tests.
  command: `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required`
- timestamp: 2026-07-17T15:44:00+08:00
  observation: The canonical focused matrix reproduced GOV-01 resolving against the active v0.2 requirements file. The v0.1 roadmap, requirements, context, research, and plans all exist under `.planning/milestones/` with the declared anchors.
  command: `pwsh -NoProfile -File scripts/quality/Test-SourceAudit.ps1`
- timestamp: 2026-07-17T15:45:00+08:00
  observation: `Resolve-PhaseSourceAuditFile` checked the active path first. Because `.planning/REQUIREMENTS.md` exists for v0.2, the later mapping to `.planning/milestones/v0.1-REQUIREMENTS.md` was unreachable; the same policy would let recreated active Phase 1 paths shadow archived evidence.
  command: `Get-Content scripts/quality/Assert-Policy.ps1 | Select-Object -Skip 275 -First 95`
- timestamp: 2026-07-17T15:46:00+08:00
  observation: The focused source-audit matrix passed canonical archive evidence, rejected mutable active requirements and phase paths, and preserved anchor, covering-plan, and reciprocal-marker negatives.
  command: `pwsh -NoProfile -File scripts/quality/Test-SourceAudit.ps1`
- timestamp: 2026-07-17T15:48:00+08:00
  observation: The RFC acceptance matrix passed all containment and symbolic-link cases, confirming the shared repository leaf resolver protections remain intact.
  command: `pwsh -NoProfile -File scripts/quality/Test-RfcAcceptance.ps1`
- timestamp: 2026-07-17T15:49:00+08:00
  observation: Full Required passed, including the source inventory matrix, four targets with 197/197 tests per target, docs, interfaces, package allowlists, release qualification, and read-only tracked checkout proof.
  command: `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required`

## Eliminated

- hypothesis: The Phase 6 module documentation changes caused the source-audit failure.
  reason: The failing ID is historical GOV-01 and the error targets the active milestone requirements file.

## Resolution

- root_cause: The historical v0.1 source ledger encoded mutable active paths. Its resolver used an active-first compatibility fallback, so the current v0.2 `.planning/REQUIREMENTS.md` shadowed the immutable v0.1 archive and caused GOV-01 anchor validation to fail. Reciprocal plan lookup carried the same latent shadowing policy.
- fix: Repoint every v0.1 ledger source to its explicit `.planning/milestones/v0.1-*` artifact, require source-audit files to belong to that canonical archive, and resolve reciprocal Phase 1 plan markers from archived plans. Add negatives that reject active requirements and active Phase 1 paths.
- verification: `Test-SourceAudit.ps1` passed; direct `Assert-PhaseSourceAudit` passed exact 1/9/16/29/17/5; `Test-RfcAcceptance.ps1` passed containment/symlink coverage; full Required passed with exit code 0.
- files_changed: `policy/phase-01-source-audit.json`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Test-SourceAudit.ps1`, `.planning/debug/required-source-audit-v02.md`
