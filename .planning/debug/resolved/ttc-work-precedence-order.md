---
status: resolved
trigger: "Phase 101 final code review found that staged work preflight and DSIG declaration validation violate frozen D-18 error precedence, while late preflight violates the bounded-work authority contract."
created: 2026-07-27
updated: 2026-07-28
---

# TTC work precedence order

## Symptoms

- Expected: Collection parsing has a coherent, documented order that prevents attacker-controlled work before its authority is established while returning deterministic structural, capability, state, and resource categories according to the Phase 101 contract.
- Actual: A late total-work preflight performs unauthorized traversal; the staged preflight in `1a768538` can return Resource at `structural_work - 1` before structural Data/Capability errors; DSIG version/count/flags validation can return a DSIG error before earlier face or alias errors.
- Error: Final `101-REVIEW.md` reports one BLOCKER after the 3/3 automatic review-fix loop.
- Timeline: Introduced while fixing code-review CR-01, partially revised in `1a768538`, and detected by the final iteration-3 review.
- Reproduction: Inspect the combination cases described by `101-REVIEW.md`; add exact one-short tests for declaration, structural, and total work boundaries plus DSIG-declaration versus face/alias conflicts.

## Current Focus

- bug_class: bohrbug
- reasoning_checkpoint:
    hypothesis: "The blocker has two contributing causes: D-18 and its plan/research copies omit the resource tiers required before declaration and structural loops, while font_collection_parse_dsig_declaration couples early record-count authority discovery to later version/count-zero/flags semantics."
    confirming_evidence:
      - "The exact regression passes at declaration_work-1=10, structural_work-1=42, and exact_work-1=56 for both max_work and caller Budget, proving three externally observable tiers."
      - "The combined malformed-face reproduction returns DSIG version/count/flags contexts before font-collection-search-facts, while the DSIG tuple correctly remains authority-first."
      - "Direct source inspection shows declaration and structural preflights before their attacker-counted loops and a single DSIG helper that validates both bounded count authority and semantic header fields."
    falsification_test: "The hypothesis would be false if splitting only record-count discovery while preserving both staged preflights failed to make all DSIG semantic conflicts return the earlier face error, or if any stage one-short test traversed its unauthorized loop or changed its resource result."
    fix_rationale: "Documenting declaration/structural preflights makes the public contract match the security mechanism; splitting DSIG count discovery from semantic validation preserves bounded work and the max_dsig_records ceiling while restoring face/protected/alias precedence over DSIG version/count-zero/flags."
    blind_spots: "Mid-open concurrent mutation is not injectable before normalization in the public path; verification must therefore retain the existing revision tests and check all four targets, but cannot stress an unexposed inter-stage mutation hook."
    candidate_causes:
      - "code: monolithic DSIG declaration parsing validates semantic fields at the authority-discovery site"
      - "config/contract: frozen D-18, research precedence, and Plan 101-03 omit required staged work/budget tiers"
      - "environment: toolchain/target variation is unlikely because the failure is deterministic data-order logic on native, but four-target verification remains required"
      - "data: combined malformed fixtures expose the ordering but do not cause it; valid inputs and single faults retain their established results"
    and_gate: "yes — resolving only the contract mismatch leaves DSIG semantic order wrong, while resolving only DSIG order leaves the staged resource behavior contradicting D-18; both fixes are required to clear the blocker."
- current_hypothesis: independently verified and resolved in commit 21fe5f42
- next_action: archive this session, append its prevention entry to the debug knowledge base, and commit the documentation

## Evidence

- timestamp: 2026-07-28
  checked: Existing debug state and final Phase 101 review
  found: The reviewer reports structural_work=43 and complete_work=57 for the shipped one-face DSIG fixture; max_work=42 returns Resource before malformed structural facts, and DSIG declaration validation runs before face/protected/alias validation.
  implication: The investigation must test two separable observable orderings and cannot accept a parser-only reorder without reconciling bounded-work authority with D-18.
- timestamp: 2026-07-28
  checked: Complete collection_parser.mbt implementation
  found: font_collection_declaration_facts preflights declaration_work before the per-face declaration scan; font_collection_parse_dsig_declaration both discovers record_count and immediately validates version/count/record ceiling/flags/record-array range; font_collection_parse then preflights structural_work before face/protected/alias/DSIG-body traversal.
  implication: The implementation has explicit staged authority but the published D-18 order omits those stages, and DSIG authority discovery cannot currently be deferred independently from semantic declaration errors.
- timestamp: 2026-07-28
  checked: Code knowledge graph discovery
  found: A fresh fast index produced no MoonBit function nodes for the relevant symbols, so graph search was insufficient and the investigation fell back to exact text search and complete file reading as allowed by AGENTS.md.
  implication: Caller/callee evidence must be established from the directly read MoonBit source and focused tests.
- timestamp: 2026-07-28
  checked: Debug knowledge base semantic/keyword recall
  found: MemPalace recall is unavailable and the only local knowledge-base entry concerns Windows newline canonicalization, with no semantic or keyword match to staged parser authority.
  implication: There is no known-pattern shortcut; the parser contract must be tested directly.
- timestamp: 2026-07-28
  checked: Spectrum-based fault localization preconditions
  found: The focused native suite has 129 passing and 0 failing tests, so there is no failing spectrum and no per-test coverage ranking to compute.
  implication: SBFL is skipped; deterministic targeted reproduction is the appropriate Bohrbug route.
- timestamp: 2026-07-28
  checked: Focused native baseline
  found: moon test --target native modules/mb-font/font passes 129/129 before adding the missing precedence reproductions.
  implication: Existing tests do not exercise the reported declaration/structural stage boundaries or DSIG declaration conflicts.
- timestamp: 2026-07-28
  checked: New exact staged-authority regression
  found: declaration_work-1 (10), structural_work-1 (42), and exact_work-1 (56) each return Resource under both FontCollectionLimits.max_work and caller Budget work exactly as predicted.
  implication: The staged preflights are externally observable and internally necessary; the frozen contract must name them rather than claiming a single late work/budget tier.
- timestamp: 2026-07-28
  checked: New malformed-face versus DSIG declaration reproduction
  found: With exact authority, malformed DSIG tuple already precedes the malformed face as required for authority discovery, but DSIG version, zero count, and flags currently return [font-collection-dsig-version, font-collection-dsig-count, font-collection-dsig-flags] instead of font-collection-search-facts.
  implication: DSIG authority and DSIG semantics are distinct precedence tiers, and the current monolithic parser is the direct code cause of the semantic-order violation.
- timestamp: 2026-07-28
  checked: Targeted regressions after the code and contract split
  found: Both TTC-01 staged work authority has exact stable precedence boundaries and TTC-01 DSIG authority precedes faces but DSIG semantics follow them pass on native.
  implication: The minimal split preserves all three authority tiers and changes the confirmed DSIG semantic conflict to the intended face-first result.
- timestamp: 2026-07-28
  checked: Full adjacent and cross-target package verification
  found: The complete mb-font/font suite passes 131/131 independently on js, wasm, wasm-gc, and native.
  implication: The private parser split is target-neutral and did not regress standalone or adjacent font behavior.
- timestamp: 2026-07-28
  checked: Interface, policy, target-all check, and whitespace gates
  found: moon info --target all, generated-interface ignore policy, Assert-FontFoundationPolicy, moon check --target all --frozen, and git diff --check all pass.
  implication: The fix does not widen the public API or violate package/policy boundaries.
- timestamp: 2026-07-28
  checked: Formatter availability
  found: moon fmt --check cannot serve as a scoped gate because this pinned repository uses deprecated moon.mod.json and contains pre-existing formatter drift across unrelated modules; the command fails before isolating the changed files.
  implication: Formatting is recorded as unavailable for this fix; compiler/tests and git diff --check remain the applicable syntax/whitespace signals.
- timestamp: 2026-07-28
  checked: Revert-and-reconfirm causality
  found: Temporarily moving DSIG semantic validation back ahead of face scanning made TTC-01 DSIG authority precedes faces but DSIG semantics follow them fail; restoring the fixed order made it and the staged-boundary regression pass again.
  implication: The parser-order change, rather than an unrelated test or environment change, directly fixes the reproduced precedence defect.
- timestamp: 2026-07-28
  checked: Fix diff and mutation tooling
  found: The diff adds a bounded authority/semantic split and tests rather than deleting or short-circuiting behavior; no Stryker configuration exists, while the manually seeded old-order mutant was killed by the driving regression.
  implication: The no-op/deletion guard passes, automated mutation is explicitly skipped, and supplemental manual mutation evidence supports the test oracle.
- timestamp: 2026-07-28
  checked: Atomic fix commit and unrelated worktree state
  found: Commit 21fe5f42 contains exactly the parser, regression, and D-18 contract/plan files; .planning/config.json remains separately modified with _auto_chain_active=true and the debug session remains untracked for the parent checkpoint/archive flow.
  implication: The requested fix is committed without absorbing or reverting the pre-existing auto-chain modification.
- timestamp: 2026-07-28
  checked: Independent Phase 101 re-review and human verification checkpoint
  found: 101-REVIEW.md is clean with zero findings; the reviewer independently verified staged declaration/structural/exact authority, DSIG semantic ordering, 28/28 focused tests and 131/131 full package tests on all four targets, target-all check, policy, parsing, commit, and whitespace gates without making source changes.
  implication: The original blocker is resolved end-to-end and the session can be archived.
- timestamp: 2026-07-28
  checked: Semantic knowledge-base indexing
  found: MemPalace is disabled in .planning/config.json, so cross-session semantic indexing was skipped after the durable knowledge-base entry was written.
  implication: .planning/debug/knowledge-base.md remains the authoritative keyword-recall fallback for this resolution.

## Eliminated

- hypothesis: Move all work and caller-budget preflights after complete structural validation to preserve the original unconditional D-18 order.
  evidence: Iteration-2 review and the exact structural formula show attacker-controlled face, protected, alias, and DSIG pair loops would execute without authority; this recreates the CPU denial-of-service.
  timestamp: 2026-07-28
- hypothesis: Move the complete exact-work preflight before all structure and declare resource errors unconditionally first.
  evidence: This changes established face/protected/alias/DSIG semantic results even when declaration and structural authority are sufficient; exact_work-1 regressions prove the full tier can remain late without unauthorized traversal.
  timestamp: 2026-07-28
- hypothesis: The failure is target, toolchain, or cache dependent.
  evidence: The current source order and focused reproduction deterministically produce the same wrong DSIG contexts on a clean native test invocation; no timing or external state participates.
  timestamp: 2026-07-28

## Resolution

- root_cause: "contract/config: D-18 and its research/plan copies omit the declaration-work and structural-work max_work/Budget preflights required before attacker-counted loops; code: font_collection_parse_dsig_declaration conflates early bounded record-count discovery with DSIG version/count-zero/flags semantics, placing those semantic failures before face/protected/alias validation"
- fix: "Split bounded DSIG record-count discovery from version/count-zero/flags and record-array semantic validation; kept tuple/count ceilings and declaration/structural work preflights early, deferred DSIG semantics until after face/protected/alias validation, documented the declaration/structural/exact authority tiers in D-18/research/Plan 101-03, and added exact stage-boundary plus DSIG conflict regressions."
- verification:
    oracle_type: specified
    target_test:
      result: pass
      tests:
        - "TTC-01 staged work authority has exact stable precedence boundaries"
        - "TTC-01 DSIG authority precedes faces but DSIG semantics follow them"
    mutation_check:
      result: skipped
      reason_if_skipped: "No Stryker configuration exists for this MoonBit repository."
      mutant_killed: true
      supplemental_evidence: "A manual old-order mutant that moved DSIG semantic validation ahead of faces was killed by the driving regression."
    no_op_deletion:
      result: pass
      deletion_justified_by_rca: false
    adjacent_tests:
      result: pass
      suites_run:
        - "mb-font/font js: 131/131"
        - "mb-font/font wasm: 131/131"
        - "mb-font/font wasm-gc: 131/131"
        - "mb-font/font native: 131/131"
        - "moon info --target all --frozen"
        - "Assert-FontFoundationPolicy"
        - "moon check --target all --frozen"
        - "git diff --check"
    revert_and_reconfirm:
      result: pass
      bug_returned_on_revert: true
      fixed_on_reapply: true
    guardrail_verdict: accepted
    human_verification:
      result: pass
      evidence: "Independent Phase 101 re-review reports status clean and zero findings for commit 21fe5f42."
- files_changed:
  - modules/mb-font/font/collection_parser.mbt
  - modules/mb-font/font/collection_test.mbt
  - .planning/phases/101-collection-contract-and-bounded-envelope/101-CONTEXT.md
  - .planning/phases/101-collection-contract-and-bounded-envelope/101-RESEARCH.md
  - .planning/phases/101-collection-contract-and-bounded-envelope/101-03-PLAN.md
  - .planning/phases/101-collection-contract-and-bounded-envelope/101-02-SUMMARY.md
  - .planning/phases/101-collection-contract-and-bounded-envelope/101-03-SUMMARY.md

## Prevention

- causal_branches:
    - "code: one helper served two lifecycle stages, so reading the bounded DSIG count also committed version/count-zero/flags semantics before earlier face/protected/alias facts were known."
    - "contract/config: D-18 described one late work/budget tier even though bounded hostile-input processing requires distinct declaration and structural preflights before their dependent loops."
    - "test/data: the existing multi-fault matrix used exact-total one-short authority and a late DSIG reserved-field fault, leaving declaration_work-1, structural_work-1, and early DSIG semantic conflicts uncovered."
- why_not_caught: "The Phase 101 verification/review gate had precedence tests, but they did not exercise declaration_work-1 or structural_work-1 under both authority sources and did not combine malformed face facts with DSIG version, zero-count, or flags errors."
- recurrence_guard: "The passing public regressions in modules/mb-font/font/collection_test.mbt — 'TTC-01 staged work authority has exact stable precedence boundaries' and 'TTC-01 DSIG authority precedes faces but DSIG semantics follow them' — freeze all three one-short tiers, both authority sources, tuple authority, and version/count-zero/flags semantic conflicts."
