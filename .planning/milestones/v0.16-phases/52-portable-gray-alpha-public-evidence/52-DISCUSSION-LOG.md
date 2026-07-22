# Phase 52: Portable Gray+Alpha Public Evidence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 52-portable-gray-alpha-public-evidence
**Areas discussed:** public vectors, hostile caller schedules, legacy compatibility, portable targets

---

## Public vectors

| Option | Description | Selected |
|--------|-------------|----------|
| Freeze compact byte vectors | Public, readable compatibility evidence with non-symmetric pairs | ✓ |
| Generated fixture pipeline | Adds a generator and lifecycle work | |

**User's choice:** Automatically selected the compact frozen-vector approach under the standing instruction to choose the best option.
**Notes:** Decode proof remains at public API seams and must assert straight RGBA8 canonicalization.

---

## Hostile caller schedules

| Option | Description | Selected |
|--------|-------------|----------|
| All strategy pairs, real zero/one/ragged drains | Exercises the public bounded contract fully | ✓ |
| Default strategy only | Leaves strategy-specific acknowledgement behavior unproven | |

**User's choice:** Automatically selected all public strategy pairs.
**Notes:** Reuse existing drivers and terminal helpers; no artificial staging path.

---

## Compatibility and portability

| Option | Description | Selected |
|--------|-------------|----------|
| Freeze legacy bytes and run one portable suite on all targets | Detects regressions without target-specific code | ✓ |
| Rebaseline legacy output or add target branches | Weakens compatibility evidence and expands scope | |

**User's choice:** Automatically selected frozen legacy vectors plus `--target all` evidence.
**Notes:** Release automation and source-tree copy workflows remain out of scope.

---

## the agent's Discretion

- Use the nearest Gray16 test pattern and the smallest focused helper additions.
- Keep public evidence readable and test-local.

## Deferred Ideas

- Gray+Alpha16, Adam7, low-bit/palette formats, colour conversion, release automation, and platform-specific implementations.
