# Phase 58: Portable Adam7 Public Evidence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 58-portable-adam7-public-evidence
**Areas discussed:** public multipass fidelity, caller-buffer schedules, compatibility and portability

---

## Public multipass fidelity

| Option | Description | Selected |
|--------|-------------|----------|
| Public non-symmetric wire/decode vector | Proves literal Adam7 pass placement through public factories and documented decode behavior. | ✓ |
| Private profile/cursor inspection | Couples evidence to internal representation. | |

**User's choice:** Automatic recommended selection authorized by the standing instruction to choose the optimal option.
**Notes:** Public contracts are the Phase 58 proof boundary.

---

## Caller-buffer schedules

| Option | Description | Selected |
|--------|-------------|----------|
| All six legal strategy pairs | Fresh zero, one-byte, and ragged drains each prove parity, tails, and sticky terminals. | ✓ |
| Representative subset | Leaves public strategy combinations unproven. | |

**User's choice:** Automatic recommended selection.
**Notes:** Matches the Phase 57 six-pair bounded/replay coverage.

---

## Compatibility and portability

| Option | Description | Selected |
|--------|-------------|----------|
| Freeze existing public bytes and run all targets | Guards legacy output and proves portability. | ✓ |
| Target-specific or new-format behavior | Expands scope beyond the milestone. | |

**User's choice:** Automatic recommended selection.
**Notes:** Big-endian admission, alternate encoders, release automation, and source copying remain excluded.

---

## the agent's Discretion

- Reuse existing public test helpers and add production code only for a proven public contract defect.

## Deferred Ideas

- None.
