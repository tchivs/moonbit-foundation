# Phase 46: Portable Gray8 Public Evidence - Discussion Log

**Date:** 2026-07-22
**Mode:** Automatic recommended decisions, authorized by the user.

## Evidence approach

Selected: exercise only public eager encode/decode and caller-buffered APIs in the existing PNG tests. Generated deterministic source samples and semantic pixel comparison are more useful than opaque snapshots.

## Stream schedule approach

Selected: reuse the existing drain helper with zero, one-byte, and ragged capacity schedules. This validates the real acknowledgement path without adding a second test framework.

## Portability approach

Selected: independently invoke the existing package tests for js, wasm, wasm-gc, and native, recording commands/results in phase artifacts. No CI or release scripting is needed.

