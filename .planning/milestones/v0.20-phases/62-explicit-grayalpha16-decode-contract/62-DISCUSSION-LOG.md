# Phase 62: Explicit GrayAlpha16 Decode Contract - Discussion Log

> **Audit trail only.** Decisions are recorded in CONTEXT.md.

**Date:** 2026-07-23
**Areas discussed:** public result surface, source admission, byte order, compatibility

- Selected one additive eager preservation selector over generic result widening.
- Selected encoded-sRGB Type-4/16-only admission over implicit colour conversion.
- Selected final-sink LE conversion after full MSB-first PNG unfiltering over a parallel decoder.
- Selected a frozen generic RGBA8 high-byte baseline plus an independent preserved-byte oracle.
