# Pitfalls Research

**Domain:** Bounded static OpenType CFF1 admission and Type 2 cubic outline extraction in MoonBit
**Project:** MoonBit Native Foundation v0.34 CFF Outline Foundation
**Researched:** 2026-07-28
**Confidence:** MEDIUM overall; HIGH for existing MNF integration contracts, MEDIUM for specification-derived CFF1/Type 2 edge cases

## Executive Warning

CFF1 is not merely another table decoder. It combines several offset coordinate
systems, compact numeric encodings, per-glyph execution environments, and a
small stack language whose inline mask bytes affect instruction framing. A
parser that accepts ordinary Latin fonts can still be unsafe or semantically
wrong for CID fonts, subroutine-heavy programs, deprecated compatibility
operators, collection faces, or hostile resource amplification.

The central prevention strategy is to separate four concerns and implement them
in order:

1. **Phase 104 — CFF1 profile and bounded data model:** exact static profile
   classification, checked Header/INDEX/DICT parsing, name/CID keying, and one
   unambiguous CharString/Private-DICT/local-Subrs environment per GID.
2. **Phase 105 — bounded Type 2 validation and retained metrics:** one iterative
   VM, fixed limits plus caller work authority, exact hint-mask framing,
   deterministic numeric policies, all-glyph validation, and atomically retained
   bounds.
3. **Phase 106 — cubic `Path2` and public/TTC integration:** reuse the same VM
   with a path sink, preserve `cmap`/`hmtx` authority, enable standalone and
   selected collection faces, and keep the qualified `glyf` backend frozen.
4. **Phase 107 — hostile, licensed, and four-target qualification:** close
   exact/one-short limits, mutation and recovery cases, licensed provenance,
   independent oracles, frozen compatibility evidence, and semantic equality
   across `js`, `wasm`, `wasm-gc`, and `native`.

Do not combine Phases 104 and 105. Structural offset/keying failures and VM
execution/resource failures have different invariants, error precedence, and
test matrices. Do not publish CFF-backed `Font` values before Phase 105 has
proved all-glyph validation and truthful retained bounds.

## Critical Pitfalls

### Pitfall 1: CFF INDEX offsets are treated as ordinary zero-based file offsets

**What goes wrong:**
INDEX object windows point one byte early or outside object data; a malicious
`count`, `offSize`, or terminal offset overflows during `count + 1`, offset-table
length, or final-range arithmetic. Empty and non-empty INDEX forms become
ambiguous, and different INDEX consumers apply different validation.

**Why it happens:**
CFF INDEX offsets are 1-based and relative to the start of INDEX object data,
not the beginning of the INDEX, CFF table, SFNT, or TTC. The encoding also uses
variable-width offsets and a special empty form.

**How to avoid:**
Use one shared INDEX parser for Name, Top DICT, String, Global Subrs,
CharStrings, FDArray, and local Subrs. Check `offSize` is 1–4; preflight
`count + 1` and offset-table bytes in checked wide arithmetic; require first
offset exactly 1; require monotonic offsets; convert each `[offset_i - 1,
offset_(i+1) - 1)` only after the terminal extent is proven inside the INDEX
window. A zero-count INDEX is exactly its count field. Retain bounded views or
compact offsets rather than eagerly copying attacker-sized objects.

**Warning signs:**
Separate INDEX implementations exist; helper names omit the offset base;
`count + 1` or `count * offSize` uses a narrow integer; test coverage omits
every `offSize`, descending/equal offsets, terminal offset 0/1, maximum count,
and exact/one-short windows.

**Phase to address:**
Phase 104, with private white-box fixtures before DICT/keying code depends on
INDEX.

---

### Pitfall 2: DICT numbers and offsets escape checked authority

**What goes wrong:**
Malformed integer/real encodings, stack overflow, wrong arity, duplicate
structural operators, or unchecked conversions produce wrapped ranges,
target-dependent numeric facts, or acceptance of a structurally ambiguous
font. `CharStrings`, `charset`, `Encoding`, `Private`, `FDArray`, `FDSelect`,
and `Subrs` are resolved against the wrong base.

**Why it happens:**
CFF DICT is a compact operand/operator language, not a fixed record. Its
operators use different arities and defaults. Most Top/Font DICT offsets are
CFF-table-relative, the Private operator contains a checked size/offset pair,
and Private DICT `Subrs` is relative to the start of that Private DICT.

**How to avoid:**
Decode at most 48 operands into a checked typed representation. Validate
integer and real encodings completely, reject reserved/truncated forms, and
perform every narrowing, fixed/rational conversion, offset addition, size
addition, and matrix operation with overflow checks. Give Top, Font, and
Private DICTs separate typed schemas with exact operand arity/type, defaults,
and duplicate-singleton policy. Resolve each operator through a helper whose
name and input window identify the base; construct a bounded `TableWindow` or
`ByteView` immediately and never retain a raw unchecked offset.

**Warning signs:**
One generic map stores untyped operand arrays; offsets are added directly to a
root buffer; `Double` is used while parsing DICT reals; duplicate `CharStrings`,
`Private`, `ROS`, `FDArray`, or `FDSelect` keys silently use first/last wins;
negative or oversized values are narrowed before validation.

**Phase to address:**
Phase 104; FontMatrix arithmetic is frozen in Phase 105 before geometry is
published.

---

### Pitfall 3: CID keying is reduced to a name-keyed special case

**What goes wrong:**
A CID-keyed CJK font uses the wrong Private DICT, local subroutine INDEX, width
defaults, random seed, or FontMatrix for a glyph. Malformed FDSelect ranges or
out-of-range FD indices are discovered only during outline extraction.

**Why it happens:**
Presence of `ROS` changes the keying model. CID fonts require a CID charset,
`FDArray`, and `FDSelect`; they omit CFF Encoding and cannot use predefined
name-keyed charsets. Each GID may select a different Font DICT and Private
environment.

**How to avoid:**
Make name-keyed versus CID-keyed a closed admitted representation. For CID
fonts require `ROS`, `FDArray`, `FDSelect`, a CID charset, and absence of
Encoding. Support FDSelect formats 0 and 3; for format 3 require the first range
at GID 0, strictly increasing ranges, a sentinel equal to `numGlyphs`, and every
FD index in range. Validate every Font DICT, Private DICT, and local Subrs INDEX
before publication. Resolve the execution environment once per GID before the
VM runs; a global subroutine's `callsubr` still uses the calling glyph's
selected local environment.

**Warning signs:**
The VM parses FDSelect itself; one global “local subrs” field exists on
`CffOutlineFacts`; predefined charset/Encoding is accepted with `ROS`; only
FDSelect format 0 has tests; unused FDs or the terminal range are not validated.

**Phase to address:**
Phase 104, with generated multi-FD CID fixtures; Phase 107 adds a licensed CID
fixture and high-GID/range stress.

---

### Pitfall 4: Type 2 depth limits are mistaken for complete resource safety

**What goes wrong:**
Repeated shallow subroutine calls, large CharStrings, stack churn, transient
array operations, or geometry expansion consume unbounded work even though
nesting never exceeds 10. Host recursion produces different failure behavior
on different targets. Incorrect subroutine bias selects the wrong program.

**Why it happens:**
The format ceilings are necessary but not sufficient caller authority. Local
and global subroutine biases depend on INDEX count (107, 1131, or 32768).
Subroutine frames share the operand stack and execution state, and a shallow
program can repeat calls indefinitely or amplify output.

**How to avoid:**
Use an explicit iterative frame stack with a hard depth ceiling of 10 and
active identities that distinguish `Global(index)` from
`Local(private_environment, index)`. Enforce the 48-entry argument stack before
every push/operator. Implement a fixed 32-slot transient array with initialized
bits and checked index conversion. Compute bias from the selected INDEX count
and validate the biased index before entry. Charge every decoded byte/token,
operator, stack action, subroutine call/return, repeated execution, mask byte,
arithmetic operation, emitted point/command, and contour against private
ledgers, `max_work`, and caller `Budget`. Cap cumulative executed bytes, calls,
commands, points, contours, and allocations independently from nesting.

**Warning signs:**
`callsubr` is a recursive MoonBit function; only maximum depth is tested;
subroutine count is used as the direct operand index; transient reads default
to zero; call work is charged only once per unique subroutine; path growth has
no separate ceiling.

**Phase to address:**
Phase 105, including exact-limit/one-over tests for stack 48, transient 32,
depth 10, bias thresholds, call count, executed bytes, path growth, and total
work.

---

### Pitfall 5: `hintmask` and `cntrmask` are skipped as no-op operators

**What goes wrong:**
The next mask byte is interpreted as a number or operator, desynchronizing the
rest of the CharString. A mask spanning a subroutine boundary, truncated mask,
implicit stem declaration, or excessive stem count is accepted inconsistently.

**Why it happens:**
Hint effects are out of scope, but hint syntax is part of bytecode framing.
Mask length depends on cumulative stems declared across the glyph and all
subroutines. Immediately before a mask, pending even operands may declare
omitted vertical stems.

**How to avoid:**
Recognize `hstem`, `vstem`, `hstemhm`, and `vstemhm`; handle the optional width
before operand-pair parity; maintain a cumulative maximum of 96 H/V stems.
Before `hintmask` or `cntrmask`, consume valid pending vstem pairs, require the
mask to remain in the current frame, then consume exactly
`(stem_count + 7) / 8` inline bytes. Validate truncation, ordering/phase rules,
and unused low bits in the final byte. Count mask work, discard mask effects,
and never move the current point.

**Warning signs:**
Hint operators simply clear the stack; mask size is based only on stems in the
current frame; the program counter advances by one after a mask operator;
tests cover only an 8-stem mask and omit 1/7/8/9/96/97 stems and truncation.

**Phase to address:**
Phase 105, before any general CharString acceptance or path comparison.

---

### Pitfall 6: Deprecated and compatibility operators get partial semantics

**What goes wrong:**
Legacy fonts are accepted with wrong geometry or nondeterministic output:
four-operand `endchar`/seac composition nests or uses the wrong glyph mapping;
flex is flattened based on a device heuristic; `random` differs by target or
run; `dotsection` disturbs state; FontMatrix composition overflows or emits
coordinates in a different unit space.

**Why it happens:**
These behaviors look peripheral but can be exercised by valid static CFF1.
Their policies affect both admission-time bounds and later `Path2`, so a
“mostly supported” operator creates validator/renderer drift.

**How to avoid:**

- Freeze one explicit seac policy before VM implementation. If supported,
  resolve StandardEncoding names only for name-keyed fonts, admit at most two
  components, prohibit nesting, and apply the same work/component authority as
  ordinary outlines. If deliberately unsupported, return a stable recognized
  capability outcome—never partial geometry.
- Emit `flex`, `hflex`, `hflex1`, and `flex1` as two cubic segments. Device-size
  flattening belongs to hint execution/rasterization and is deferred.
- Treat deprecated `dotsection` as a validated no-op if admitted.
- Specify a project-owned deterministic PRNG, `initialRandomSeed` handling, and
  reset semantics for Type 2 `random`; ambient host randomness is forbidden.
- Specify Top/Font DICT FontMatrix composition, normalization to
  `head.unitsPerEm`, fixed-point precision/rounding, and overflow errors before
  calculating bounds.

**Warning signs:**
Admission and outline modes implement separate operator switches; flex becomes
a line; `random` calls a host API; a CID Font DICT matrix is ignored;
coordinates are converted to `Double` before repeated arithmetic; seac tests
omit CID rejection, missing components, nesting, and budgets.

**Phase to address:**
Policy decisions and generated vectors in Phase 105; public and licensed
interoperability verification in Phases 106–107.

---

### Pitfall 7: Glyph bounds and metrics are computed lazily or admitted partially

**What goes wrong:**
`Font::open` succeeds but a malformed unqueried glyph fails later; budgetless
`horizontal_metrics` performs hidden VM work; CFF bounds are `None` or fake
zero extents; right-side bearing is wrong; a failure leaks some retained bounds
or charges an uncommitted budget transaction.

**Why it happens:**
CFF has no `glyf` header with cheap stored bounds, while the existing public
metrics query has no budget parameter. Reusing `glyf` assumptions or postponing
CharString validation violates the opaque format-neutral `Font` contract.

**How to avoid:**
Run every glyph through the same Type 2 VM with a validation/bounds sink during
CFF admission. Retain only a conservative integer bound per GID, using
`floor(min)`/`ceil(max)` over checked transformed endpoints and cubic control
points. Keep `hmtx` authoritative for advances and side-bearing inputs; Type 2
widths are validated but do not replace public metrics. Accumulate all CFF
charges in a private ledger, perform a final source-revision guard, commit once,
then publish the complete `Font`. On any structural, glyph, resource, numeric,
or mutation failure publish no font, no bounds, and no committed admission
charge.

**Warning signs:**
`horizontal_metrics` calls the VM; bounds are optional for all CFF glyphs;
admission validates only `.notdef` or mapped glyphs; a `Font` is constructed
before the all-glyph pass; budget charges occur inside individual glyph loops.

**Phase to address:**
Phase 105 establishes validation/bounds and atomic admission; Phase 106 proves
public metric parity and selected-outline transactions.

---

### Pitfall 8: TTC face bases are mixed with table-relative and CFF-relative offsets

**What goes wrong:**
Standalone CFF works, but the same font selected from TTC/OTC reads a different
table or object. Shared CFF tables are copied, double-rebased, or rejected, and
face-local `cmap`/`hmtx` facts are accidentally taken from another face.

**Why it happens:**
In TTC/OTC, a table-record offset remains relative to collection byte zero; it
is not relative to the selected face directory. After a checked `'CFF '`
table window is created, CFF internal `(0)` offsets are relative to that table,
INDEX offsets are relative to object data, and Private `Subrs` is relative to
the Private DICT.

**How to avoid:**
Reuse the v0.33 retained-root, root-relative selected-face adapter. First turn
the root-relative table record into a checked `TableWindow`; only then resolve
CFF-internal offsets inside that window. Never add the selected directory base
to a table record or CFF offset. Permit exact shared table ranges while keeping
face-local common tables authoritative. Preserve collection checksum and final
root-revision rules rather than materializing a fake standalone SFNT.

**Warning signs:**
The CFF parser accepts both root and face bases; a selected face is copied to a
new buffer; shared CFF is treated as overlap corruption; standalone and
collection admission use separate CFF parsers; collection tests use only a
face directory at offset zero.

**Phase to address:**
Phase 106, after standalone structural and VM semantics are proven.

---

### Pitfall 9: Four-target equality is inferred from compilation or one backend

**What goes wrong:**
`js`, `wasm`, `wasm-gc`, and `native` compile but disagree on overflow, fixed
point rounding, host recursion failure, `Double` conversion, random output,
allocation failure, error precedence, or command fingerprints.

**Why it happens:**
CFF/Type 2 combines numeric edge cases and state-machine amplification that
exercise backend differences. A target-produced snapshot can also confirm its
own bug.

**How to avoid:**
Keep VM arithmetic in checked integer/fixed-point form until final `Point2`
emission, use explicit frames and a project-owned PRNG, and make allocation/work
preflight target-neutral. Run the same complete package and qualification
matrix independently on all four targets in isolated target directories.
Compare exactly four ordered semantic records, normalizing only declared
runner/target fields. Keep CFF commands, bounds, errors, budget effects,
mutation outcomes, frozen `glyf` facts, dependency/API facts, and toolchain
identity byte-visible.

**Warning signs:**
Only `moon check --target all` is run; native results are copied as expected
data for portable targets; coordinates are compared with broad tolerances;
random values or error categories are omitted from evidence; test output uses
one shared build directory.

**Phase to address:**
Phase 105 makes semantics portable by construction; Phase 107 closes independent
four-target execution and comparison.

---

### Pitfall 10: Licensed fixtures lack provenance or become their own oracle

**What goes wrong:**
A moving download, system-installed font, or unlicensed derivative cannot be
reproduced or redistributed. A font transformed by one tool is validated only
against expectations produced by that same tool or by MNF itself. CID behavior
is claimed without a real multi-FD fixture.

**Why it happens:**
Generated fixtures are convenient but do not prove desktop interoperability;
large CJK assets encourage undocumented subsetting. Tool output is easy to
mistake for independent truth.

**How to avoid:**
Commit or integrity-pin one immutable name-keyed static CFF1 OTF and one
immutable CID-keyed CFF1 OTF or license-compliant deterministic derivative.
Record source URL and revision, original and derivative SHA-256, license and
notice, exact generator identity/version/command, transformation recipe, and
offline oracle versions in a manifest. Preserve license/notice files. Use
hand-derived generated vectors for exact structure/operator truths and
cross-check licensed semantic facts with independent tools; target-produced
MNF output must never generate its own expected result.

**Warning signs:**
Fixtures come from `%WINDIR%\Fonts`; URLs point to `latest`; only derivative
hashes are recorded; notice or parent digest is absent; fontTools both generates
the file and provides the sole golden JSON; the CID fixture selects only one FD.

**Phase to address:**
Select and approve provenance during Phase 107 planning; qualification cannot
close until manifests, notices, digests, recipes, and independent oracle facts
are verified.

## Moderate Pitfalls

### Pitfall 11: CFF profile recognition is tag-only

**What goes wrong:**
Any `OTTO` font or any file containing `CFF ` reaches the new parser despite
mixed `glyf`/`loca`, `CFF2`, variation tables, missing common tables, wrong
`maxp` version, or CharStrings count mismatch.

**Prevention:**
Classify a closed static profile: `OTTO`, exactly one supported `CFF ` outline
profile, required common tables, `maxp` 0.5, and
`maxp.numGlyphs == CharStrings.count`. Preserve the existing static `glyf`
branch and reject recognized CFF2/variable/WOFF profiles with stable capability
outcomes.

### Pitfall 12: CFF Encoding, charset, and OpenType `cmap` are conflated

**What goes wrong:**
Public Unicode lookup changes with CFF Encoding, CID fonts appear unmappable,
or public GIDs are renumbered by SID/CID order.

**Prevention:**
Keep OpenType GID equal to CharStrings INDEX position and keep admitted SFNT
`cmap` authoritative for `glyph_for_scalar`. Validate charset and Encoding as
CFF structures and for seac compatibility only; CID fonts have no Encoding.

### Pitfall 13: The qualified `glyf` decoder is generalized during CFF work

**What goes wrong:**
Existing metrics, error precedence, budget counts, quadratic paths, collection
selection, or fingerprints regress, and the source of the regression becomes
hard to isolate.

**Prevention:**
Use a private closed `FontOutlineSource::Glyf | Cff1` dispatch. Share only the
public facade and common metric boundary. Keep the current `outline.mbt` path
and frozen evidence unchanged.

### Pitfall 14: Unsupported scope is silently partially accepted

**What goes wrong:**
CFF2/variable fonts, WOFF containers, shaping requests, or device hint/raster
behavior appear to succeed while geometry is incomplete or wrong.

**Prevention:**
Explicitly defer CFF2 and variable instantiation, WOFF1/WOFF2, GSUB/GPOS/bidi
shaping, hint execution, and rasterization. Detect recognized profiles at the
appropriate boundary and return the established structured unsupported
capability result. CFF1 hint syntax is still fully validated because it frames
the bytecode.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Separate INDEX readers per structure | Fast local progress | Divergent offset, overflow, and empty-form rules | Never |
| Untyped DICT operator map | Less schema code | Ambiguous arity/defaults, duplicate keys, unsafe offsets | Never |
| Recursive `callsubr` | Short interpreter | Target-dependent stack failure and hidden accounting | Never |
| Validate only requested glyphs | Faster open | Breaks atomic admission and budgetless metrics | Never under the existing public API |
| Store a `Path2` for every glyph | Easy metric bounds | CJK-scale memory amplification | Never; retain compact bounds and views |
| Memoize subroutine geometry | Faster repeated calls | Incorrect because stack, point, hint state, FD environment, and transient state are caller-dependent | Never |
| Use `Double` throughout Type 2 | Easier arithmetic | Cross-target drift and unclear overflow | Never for VM state; final emission only |
| Treat hints as zero-byte no-ops | Smaller VM | Instruction desynchronization | Never |
| Reject all CID fonts | Smaller initial slice | Not desktop-grade CFF1 and excludes CJK | Never for v0.34 |
| Treat seac/random/FontMatrix as “later” while accepting them | Smaller operator surface | Valid programs publish wrong bounds/paths | Never; support fully or reject explicitly |
| Build a parallel CFF public type | Avoid facade refactor | Splits consumer APIs and exposes unstable internals | Never for v0.34 |
| Float fixture downloads/oracle versions | Less fixture maintenance | Irreproducible and legally incomplete evidence | Never in Required CI |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| SFNT directory → CFF admission | Pass raw root offset and length | Pass one checked `'CFF '` `TableWindow` and common admitted facts |
| CFF INDEX → objects | Apply offsets from INDEX start | Apply 1-based offsets from object-data start after terminal proof |
| Private DICT → local Subrs | Apply `Subrs` from CFF table base | Apply it from the beginning of the selected Private DICT |
| CID keying → VM | Let VM choose FD/local Subrs | Resolve one environment per GID before execution |
| Global Subrs → local calls | Use one global local-Subrs set | Use the calling glyph's selected Private environment |
| Type 2 → metrics | Replace advance with CharString width | Validate Type 2 width; keep `hmtx` public authority |
| Type 2 → `Path2` | Publish commands incrementally | Build bounded scratch geometry and publish only after final guard/commit |
| TTC/OTC → CFF | Rebase table offsets by face directory | Keep table records root-relative; CFF offsets become table-relative only after windowing |
| Offline oracles → tests | Consume oracle tools at runtime | Pin host-only tools and commit/generated bounded semantic facts |
| Four-target runner | Reuse one backend's output as expected | Run four independent lanes and compare normalized semantic records |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Eager object/string copying | Memory scales with CFF table plus decoded copies | Retain root views and compact INDEX offsets | Large String/Subrs INDEX or CJK fonts |
| Retaining every glyph path | High open-time memory and allocation failure | Retain one conservative integer bound per GID | Tens of thousands of CID glyphs |
| Repeated subroutine work uncharged | Tiny CharString consumes extreme CPU | Count every executed byte/token/call and total work | Shallow repeated call programs |
| FDSelect linear scan per operation | CJK outline time grows with range count | Resolve selected FD once per GID; retain compact validated ranges | High GID and many ranges |
| Allocation after partial parsing | Late resource failures and wasted work | Preflight attacker-controlled counts/ranges before loops/allocations | Maximum-count hostile fonts |
| Broad floating-point tolerance | Cross-target regressions appear “close enough” | Fixed-point semantics and exact normalized evidence | Long arithmetic/FontMatrix chains |
| Optimizing before semantic freeze | Cache/desubroutinization bugs obscure correctness | Baseline licensed Latin/CJK workloads after Phase 107 correctness gates | Any premature optimization phase |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Narrow unchecked count/offset arithmetic | Out-of-range reads, panics, or allocation amplification | Checked wide arithmetic before every add/multiply/narrow/range |
| Trusting object count before terminal extent | Attacker-controlled traversal/allocation | Prove complete INDEX envelope and semantic ceilings first |
| Host recursion for subroutines | Backend stack exhaustion | Explicit depth-10 frames plus call/work budgets |
| Lazy malformed-glyph discovery | Partially trusted `Font` state | Validate every glyph before admission publication |
| Mutation guard only at open entry | TOCTOU between retained views and publication | Capture revision and guard immediately before each commit/publication |
| Executing embedded PostScript | Unbounded language/runtime behavior | Validate referenced SID/range only; never execute |
| Treating licensed corpus as trusted input | Uncovered parser defects in Required CI | Apply the same limits, budgets, mutation guards, and independent checks |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| CFF-backed font has a second public type | Consumers branch throughout document/graphics code | Return the same opaque `Font` and cubic `Path2` |
| CFF bounds are missing or fabricated | Wrong RSB/layout diagnostics despite valid outline | Retain truthful conservative bounds during atomic admission |
| Error taxonomy differs standalone vs collection | Callers cannot recover consistently | Preserve state/input/resource/data/capability precedence on both routes |
| Recognized deferred formats look malformed | Users cannot distinguish unsupported capability from corrupt input | Return stable unsupported outcomes for CFF2/variable, WOFF, shaping, and raster requests |
| Hinting claim exceeds implementation | Users expect device-quality raster output | State clearly: hint syntax validated, unhinted design-space geometry published |

## “Looks Done But Isn’t” Checklist

- [ ] Every INDEX consumer uses one checked implementation with `offSize` 1–4,
      first offset 1, monotonic offsets, terminal extent, and empty-form tests.
- [ ] Top, Font, and Private DICT schemas enforce number encoding, 48 operands,
      exact arity/type/default/duplicate policy, and named offset bases.
- [ ] `ROS` requires CID charset, FDArray, FDSelect, no Encoding, and a validated
      per-GID Private/local-Subrs environment.
- [ ] Type 2 tests cover stack 48/49, transient 32/out-of-range/uninitialized,
      all three subr bias bands, depth 10/11, cycles, repeated shallow calls,
      executed-byte limits, path limits, work, and caller budgets.
- [ ] `hintmask`/`cntrmask` consume exactly `ceil(stems/8)` bytes after pending
      vstem operands and cover 1/7/8/9/96/97 stems and truncation.
- [ ] Flex remains two cubic segments; seac is either fully bounded/non-nested
      or explicitly unsupported; random and FontMatrix policies are frozen and
      deterministic.
- [ ] All glyphs validate and produce retained bounds before `Font` publication;
      failed admission exposes no bounds and commits no charge.
- [ ] `hmtx` remains authoritative; CharString widths are validated but never
      silently replace public metrics.
- [ ] Selected TTC/OTC CFF faces use root-relative table offsets and CFF-local
      windows without copying or double rebasing.
- [ ] Existing static `glyf` bytes, errors, budgets, metrics, mappings, kerning,
      paths, interface, and dependency evidence remain frozen.
- [ ] Generated name-keyed and multi-FD CID fixtures cover structural and VM
      boundaries with hand-derived expected facts.
- [ ] Licensed name-keyed and CID assets have source/derivative hashes,
      revision, license/notice, exact recipe/tool identity, and independent
      oracle facts.
- [ ] `js`, `wasm`, `wasm-gc`, and `native` run independently and produce
      exactly four comparable semantic records.
- [ ] CFF2/variable, WOFF1/WOFF2, shaping/bidi/GSUB/GPOS, hint execution, and
      rasterization remain explicitly deferred and are not partially accepted.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong INDEX/DICT offset base | HIGH | Stop dependent work; centralize checked windows; regenerate structural fixtures; re-run every parser/keying case |
| CID environment selected incorrectly | HIGH | Replace global environment with per-GID keying facts; invalidate retained bounds; re-run multi-FD and licensed CID qualification |
| VM resource accounting incomplete | HIGH | Introduce one execution ledger; enumerate every loop/call/emission; add exact/one-short budgets before optimizing |
| Hint-mask desynchronization | MEDIUM | Centralize stem state and frame-local mask consumption; add byte-level program-counter fixtures |
| seac/random/FontMatrix policy drift | HIGH | Freeze policy in tests; make both sinks share one VM; regenerate all bounds/path oracle facts |
| Partial bounds or budget published | HIGH | Reinstate private admission ledger and all-glyph pass; move final revision guard/one charge immediately before publication |
| TTC double rebasing | MEDIUM | Restore root-relative selected-face adapter; make CFF parser accept only a checked table window; add non-zero-directory/shared-table fixtures |
| Four-target semantic mismatch | MEDIUM | Reduce to generated exact vector; compare ledger/state transitions; remove host recursion/random/early float conversion |
| Fixture provenance gap | MEDIUM | Quarantine the asset from Required CI; reconstruct parent/derivative lineage or replace with a fully licensed reproducible fixture |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| INDEX 1-based offsets/count overflow | Phase 104 | Every `offSize`; empty/non-empty; descending, truncated, terminal, exact/one-short, maximum-count cases |
| DICT number/offset/arity overflow | Phase 104 | Integer/real encodings, 48/49 operands, typed arity, duplicates, every coordinate base and checked range |
| Name/CID keying confusion | Phase 104 | Predefined/custom charset/Encoding plus ROS, FDArray, FDSelect 0/3, multiple FDs and local Subrs |
| Type 2 stack/transient/subr/work failure | Phase 105 | Stack/transient boundaries, biases 107/1131/32768, depth/cycle/calls/bytes/work/path/resource matrix |
| Hint-mask byte desynchronization | Phase 105 | Stem boundary matrix, pending vstem pairs, truncation, last-byte bits, frame-boundary rejection |
| seac/flex/random/FontMatrix drift | Phase 105 | One-VM two-sink equality, non-nested compatibility, exact cubics, deterministic PRNG, fixed-point matrix overflow |
| Bounds/metrics partial admission | Phase 105 | Every-glyph validation, retained conservative bounds, `hmtx` authority, mutation and no-charge-on-failure |
| Public cubic path and glyf regression | Phase 106 | Same VM BuildPath sink, complete `Path2` only, frozen glyf semantic/budget/interface evidence |
| TTC root/table/CFF offset confusion | Phase 106 | Non-zero face directories, shared CFF table, face-local cmap/hmtx, standalone/collection semantic equality |
| Deferred-scope leakage | Phase 106 | Stable unsupported outcomes for CFF2/variable, WOFF, shaping, hint execution, and rasterization |
| Four-target drift | Phase 107 | Independent complete package runs and four ordered exact semantic records |
| Licensed fixture provenance/self-oracle | Phase 107 | Manifest/license/notice/digests/recipe/tool versions plus two-source semantic cross-check |
| Hostile and atomicity gaps | Phase 107 | Closed structural/program/resource/mutation matrix with exact/one-short limits and final evidence negative probes |

## Explicit Deferrals

The following are not implementation shortcuts inside v0.34; they are separate
capability boundaries and must remain visibly unsupported:

- **CFF2 and variable fonts:** different data model and VM semantics, including
  VariationStore, `vsindex`, and `blend`; not a CFF1 tag switch.
- **WOFF1 and WOFF2:** require bounded zlib/DEFLATE or Brotli plus transformed
  table reconstruction before SFNT/CFF admission.
- **Text shaping:** GSUB/GPOS, bidi, script/language selection, and glyph
  positioning belong to a future `mb-text` layer.
- **Hint execution and rasterization:** v0.34 validates hint syntax only and
  publishes deterministic unhinted design-space `Path2`; grid fitting, device
  scale, stem darkening, antialiasing, and pixels remain downstream work.

## Sources

### Authoritative format sources

- [OpenType 1.9.1 — The OpenType Font File](https://learn.microsoft.com/en-us/typography/opentype/spec/otff)
  — `OTTO`, required/shared tables, outline profile separation, TTC/OTC
  collection directories, sharing, and root-relative table-record offsets.
- [OpenType 1.9.1 — CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff)
  — one-font CFF FontSet restrictions, Type 2 requirement, OpenType GID /
  CharStrings identity, `maxp` cardinality, and CFF collection integration.
- [OpenType 1.9.1 — CFF2 table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff2)
  — authoritative contrast supporting the explicit CFF2/variable deferral.
- [Adobe Technical Note #5176 — The Compact Font Format Specification](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf)
  — Header, INDEX, DICT, charset, Encoding, Private DICT, Subrs, ROS, FDArray,
  FDSelect, offset bases, and FontMatrix.
- [Adobe Technical Note #5177 — The Type 2 Charstring Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf)
  — number/operator semantics, stack/transient limits, subroutine bias/depth,
  hints/masks, path/flex operators, deprecated seac compatibility, and
  implementation ceilings.

**Confidence:** MEDIUM. These are official Microsoft/Adobe primary sources
already cross-checked in the v0.34 stack, feature, and architecture research;
no new external search was performed for this recovery synthesis.

### Project sources

- `.planning/PROJECT.md` — v0.34 goal, active requirements, atomicity and
  four-target baseline, and explicit deferrals.
- `.planning/research/STACK.md` — recommended pure-MoonBit stack, format limits,
  deterministic VM policy, qualification tools, and fixture policy.
- `.planning/research/FEATURES.md` — desktop-grade table stakes, anti-features,
  acceptance matrix, and four-phase ordering.
- `.planning/research/ARCHITECTURE.md` — closed outline-source dispatch,
  checked-window boundaries, one-VM/two-sink design, atomic admission, TTC
  integration, and qualification architecture.
- `AGENTS.md` — repository constraints: pure MoonBit core, explicit targets,
  bounded deterministic automation, modularity, and RFC governance.

**Confidence:** HIGH for binding project scope and existing integration
contracts; MEDIUM where planning still must freeze random, FontMatrix, seac,
and exact licensed-CID fixture choices.

---
*Pitfalls research for: MoonBit Native Foundation v0.34 CFF Outline Foundation*
*Researched: 2026-07-28*
