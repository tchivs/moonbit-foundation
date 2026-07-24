# Phase 83: Low-Bit Indexed Adam7 Machine and Eager Contract - Discussion Log

**Date:** 2026-07-24
**Mode:** Automatic recommended decisions authorized by the user.

- Selective Adam7 stays additive; legacy low-bit wrappers are explicit `None`.
- Pack each pass row independently, rather than reuse non-interlaced packed rows.
- Keep all machine/resource facts atomic and defer hostile caller lease testing to Phase 84.
