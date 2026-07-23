# RFC 0006: mb-pdf Charter

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-22
- **Target:** Document and Scene Layer PDF module charter
- **Discussion:** To be established
- **Normative process:** [RFC process](../governance/rfc-process.md)
- **Authority / project owner:** `sole-project-owner`

> The acceptance-machinery header fields this RFC previously carried (acceptance route, maintainer approvals, blocking objections, public review window, acceptance evidence) were removed on 2026-07-23 when the RFC process was simplified to `Draft -> Proposed` for this sole-owner project. A Proposed RFC is now sufficient to proceed. See the [RFC process](../governance/rfc-process.md).

## Transition history

| From | To | Evidence |
|---|---|---|
| — | Draft | Initial RFC in repository history |
| Draft | Proposed | This revision makes the charter reviewable; repository history is the transition record |

No transition to Rejected or Superseded has occurred. Under the simplified RFC process the lifecycle is `Draft -> Proposed`; a Proposed RFC is sufficient to proceed. Every future transition must update this ledger.

## 1. Abstract

This RFC proposes `tchivs/mb-pdf` as a new MNF module in the Document and Scene Layer, responsible for parsing, representing, and serializing a bounded subset of the Portable Document Format (PDF). It establishes the module boundary, the allowed public dependency direction, the PDF subset scope, and the critical principle that `mb-pdf` is a **document container**, not a renderer: it reads and writes PDF structure, deferring pixel production to the same graphics and text stack the rest of MNF uses.

`mb-pdf` answers two questions: how does an MNF consumer read a PDF's pages, content streams, and resources without a foreign library, and how does a consumer write one deterministically. RFC 0001 names `mb-pdf` in the Document and Scene Layer but Section 6 does not define its responsibilities. This RFC fills that gap.

This RFC does not implement `mb-pdf`. It creates no `.mbt` source, no package manifest, and no module declaration. Per [RFC 0001](0001-moonbit-native-foundation.md) Section 11, creation of a new MNF module requires a Proposed RFC before implementation may merge.

## 2. Relationship to RFC 0001

[RFC 0001](0001-moonbit-native-foundation.md) Section 5 places `mb-pdf` in the Document and Scene Layer alongside `mb-svg`, `mb-font`, `mb-text`, and `mb-layout`, above the Graphics Layers and the Foundation. RFC 0001 Section 6.4 governs deferred layers: `mb-pdf` may consume accepted lower-layer contracts and may not redefine them through implementation alone.

The allowed public dependency direction proposed here is:

```text
tchivs/mb-pdf -> tchivs/mb-image
tchivs/mb-pdf -> tchivs/mb-color
tchivs/mb-pdf -> tchivs/mb-core
```

`mb-pdf` depends on `mb-image` (for embedded raster images: decode a PDF's image XObjects into `ImageView`s, and encode raster outputs), `mb-color` (for PDF color-space and ICC profile identity), and `mb-core` (for checked arithmetic, bounded readers/writers, budgets, and structured errors).

`mb-pdf` does **not** hard-depend on `mb-canvas`, `mb-font`, or `mb-text` as initial public edges, but it **interoperates** with them (Section 3.4). This is a deliberate scoping decision: a PDF's content stream references fonts and renders operators, but the boundary between "PDF container" and "text/graphics execution" is drawn so that PDF does not own shaping or rasterization.

## 3. The boundary problem and its resolution

### 3.1 PDF is a container, not a renderer

The central boundary decision is: **`mb-pdf` parses and serializes PDF document structure; it does not rasterize.** This mirrors the svg/canvas and font/canvas splits in RFCs 0002–0004.

- `mb-pdf` owns the **document container**: the cross-reference structure, the page tree, the resource dictionary, content streams, image XObjects, and the PDF object model.
- A renderer — built from the graphics stack — consumes the content stream and produces pixels. That renderer is a consumer of `mb-pdf`, `mb-font`, `mb-text`, and `mb-canvas`; it is not `mb-pdf` itself.

The cut is: **PDF owns structure and serialization; rendering is a separate concern composing the graphics stack.** This keeps `mb-pdf` testable and consumable as a producer/consumer of document data without forcing every PDF reader to also be a rasterizer.

### 3.2 PDF content streams and the graphics stack

A PDF content stream is a sequence of drawing operators (path construction, painting, text, image, state). `mb-pdf` parses this stream into a typed operator sequence. Translating that sequence into a `mb-canvas` drawing list, or into shaped text via `mb-text`, is a **consumer** operation.

This RFC proposes that `mb-pdf` exposes a parsed content-stream model, and that an optional, separate rendering layer (a phase or even a separate package) translates operators to canvas draws. This keeps the container's public surface focused and lets the rendering layer evolve independently.

### 3.3 PDF images and mb-image

PDF embeds raster images as image XObjects. `mb-pdf` owns the **PDF-level** image wrapper (the XObject dictionary, filter chains like FlateDecode/DCTDecode, and color-space mapping). The actual raster decode/encode delegates to `mb-image` codecs where they overlap (for example, a PDF DCTDecode image is a JPEG; a FlateDecode raw image is a deflate stream over raw pixels).

The cut is: **PDF owns the XObject wrapper and filter-chain orchestration; image owns the codec decode/encode.** `mb-pdf` hands a decoded XObject to the consumer as an `ImageView`; it does not reimplement JPEG or PNG decode.

### 3.4 PDF text and mb-text/mb-font

PDF content streams reference fonts by name and embed font programs or subsets. `mb-pdf` owns the **PDF-level** font resource (the font dictionary, embedded font streams, and CID/ToUnicode mapping). Translating a PDF text-show operator (`Tj`/`TJ`) into a shaped, positioned glyph sequence is a consumer operation combining `mb-pdf`'s font resources with `mb-font` and `mb-text`.

The cut is: **PDF owns the font resource wrapper and embedded-stream extraction; font and text own the geometry and shaping.** This defers full text rendering to a composition layer rather than embedding it in the container.

## 4. Module boundary

### 4.1 `tchivs/mb-pdf` owns

- **PDF object model**: parsing the cross-reference table, trailer, and indirect object graph into a validated, queryable document model, with bounds on object count, nesting depth, and stream size.
- **Page tree**: the page tree structure (Pages/Page nodes), MediaBox/CropBox, rotation, and page resource inheritance.
- **Content stream parsing**: tokenizing and parsing a content stream into a typed sequence of PDF operators (path, painting, text, image, state) within the in-scope subset (Section 6).
- **Resource dictionaries**: resolving named resources (color spaces, fonts, images, graphics states) from resource dictionaries.
- **Image XObjects**: parsing image XObject dictionaries and filter chains (FlateDecode, DCTDecode, raw), decoding to `mb-image` `ImageView`s by delegating codec work to `mb-image`.
- **Color-space mapping**: mapping PDF color spaces (DeviceGray, DeviceRGB, DeviceCMYK, ICCBased) to `mb-color` identities, and handling ICC profile streams via `mb-color`'s profile seams.
- **Serialization**: writing a valid, deterministic PDF document from a document model, with canonical cross-reference construction, reproducible object numbering, and declared filter choices.
- Conformance fixtures with provenance and license metadata.

### 4.2 `tchivs/mb-pdf` does not own

- Rasterization or pixel production — a renderer composes the graphics stack; PDF is the container.
- Font binary parsing, glyph geometry, or outline extraction — those belong to `mb-font`. PDF owns the font resource wrapper.
- Text shaping, bidi, or line breaking — those belong to `mb-text`. PDF owns the font resource and text-show operators; shaping is a consumer.
- Raster codec implementation (JPEG, PNG, CCITT, JBIG2) — those belong to `mb-image` (where MNF provides them) or are external. PDF orchestrates filter chains; it does not reimplement codecs.
- A GUI, print dialog, or interactive viewer.
- Encryption and DRM beyond a documented minimum (Section 7.3).
- Embedded JavaScript, interactive forms (AcroForm) execution, or multimedia — those are deferred or out of scope.

## 5. Portability and native integration

`mb-pdf` proposes the same portable contract: supported targets are `js`, `wasm`, `wasm-gc`, and `native`. Core parsing, the object model, content-stream tokenization, and serialization are portable MoonBit with no ambient host capability.

Any target-specific acceleration (for example, a native zlib for FlateDecode) is an optional leaf adapter behind a documented seam, never making the portable package transitively native-only, consistent with RFC 0001 Section 8. Where a filter (e.g., FlateDecode) overlaps existing MNF work (e.g., PNG's pure-MoonBit DEFLATE), `mb-pdf` consumes or shares that implementation rather than duplicating it.

## 6. v0.x PDF subset scope

Full PDF (ISO 32000-2) is enormous. This section proposes a bounded, useful subset focused on document interchange.

### 6.1 In scope (proposed for v0.x)

- **Structure**: PDF 1.4–1.7 cross-reference table and cross-reference stream parsing, trailer, indirect objects, the document catalog, and **compressed object streams (ObjStm, PDF 1.5+)**. Object streams are resolved through the same bounded FlateDecode path shared with `mb-image`'s PNG DEFLATE discipline (Section 7.2); they are in scope for object resolution, not deferred, because real-world PDF 1.5+ documents store the majority of their objects in `ObjStm` streams and a parser that cannot resolve them is not interchange-useful.
- **Page tree**: Pages/Page nodes, MediaBox/CropBox, rotation, and inherited resources.
- **Content streams**: a bounded subset of PDF operators — path construction (`m l c h re`), painting (`S f f* B B*`), state (`q Q w J j M d`), basic transformations (`cm`), and color (`CS cs SC SCN sc scn g G rg RG k K`).
- **Image XObjects**: raw, FlateDecode, and DCTDecode (JPEG) image XObjects, decoded to `mb-image` views.
- **Color spaces**: DeviceGray, DeviceRGB, DeviceCMYK, and ICCBased via `mb-color` profiles.
- **Text operators and font resources**: the text-state and text-show operators (`Tf Tm Td TD T* Tj TJ ' "`) and font dictionary parsing, including embedded TrueType and CFF font program streams (extracted for `mb-font` consumption).
- **Serialization**: deterministic PDF writing with canonical xref construction, declared object numbering, and chosen filters.
- **Linearization-ready structure**: output that is structurally clean, even if full linearization (PDF 1.5) is deferred.

### 6.2 Deferred (explicitly out of v0.x scope)

- Full linearization (fast-web-view) and the HintStream.
- PDF 2.0 (ISO 32000-2:2020) additions beyond the shared 1.4–1.7 subset.
- Form XObjects and complex Patterns beyond a documented minimum.
- Transparency groups, soft masks, and advanced blending beyond source-over delegation to image.
- ICC v4 profile color management beyond identity/passthrough via `mb-color`.
- Tagged PDF, accessibility trees, and PDF/UA.
- Interactive forms (AcroForm/XFA) and signature/encryption beyond a documented read-only minimum.
- Embedded JavaScript, 3D, multimedia, and rich media annotations.
- Optional Content Groups (layers) beyond a documented minimum.
- JPEG2000 (JPXDecode), CCITT, JBIG2, and RunLengthDecode filter implementations beyond what `mb-image` or shared MNF code provides.

Deferral is binding until a follow-up RFC or phase explicitly widens scope. Implementation MUST NOT silently pull in a deferred category.

## 7. Determinism, bounds, and resource safety

### 7.1 Deterministic serialization

PDF serialization is deterministic: a given document model and configuration produce byte-identical output on every target, with canonical cross-reference construction, reproducible object numbering, and declared filter choices. No host clock, no nondeterministic dictionary iteration in the public contract.

### 7.2 Bounds and hostile inputs

PDF is a common attack vector for malicious documents. Consistent with RFC 0001 Section 10:

- **Bounded parsing.** Object-count, nesting-depth, stream-size, xref-chain-length, and operator-count limits are enforced through `mb-core` budgets; malformed structures fail with structured errors before allocation.
- **Stream safety.** Decompression bombs (FlateDecode streams that expand beyond a declared factor) are rejected by bounded decompression with declared expansion limits, reusing the bounded-decompression discipline already established for PNG DEFLATE in MNF.
- **Hostile structure.** Recursive/indirect-reference loops, oversized xref offsets, truncated streams, and crafted object streams are rejected at parse time.

### 7.3 Encryption and security

PDF encryption (standard security handler) is a read-only, bounded concern in v0.x: a reader may recognize and, where the credential is supplied, decrypt, but does not implement DRM circumvention. Password-protected documents without a supplied credential fail closed with a structured error. Encryption is a documented minimum; advanced security handlers are deferred.

## 8. Alternatives considered and rejected

- **Make mb-pdf a renderer.** Rejected. PDF-as-renderer would bundle container logic, font parsing, text shaping, and rasterization into one module, violating the module boundaries in RFC 0001 Section 6 and the independent-consumption principle (Section 4.3). The container/execution split keeps each concern independently testable and consumable.
- **Wrap a mature PDF library (e.g., MuPDF, PDFium) as the core.** Rejected per RFC 0001 Section 4.1. A foreign library may appear only as an isolated, replaceable native adapter, never as the portable public contract.
- **Bundle font parsing and text shaping into PDF.** Rejected. Those are `mb-font` and `mb-text` responsibilities. PDF owns font resources and text operators; geometry and shaping are consumer concerns.
- **Depend on mb-canvas as an initial hard edge.** Rejected. PDF is a container; canvas is a renderer. A rendering layer composes them, but the container's public edge does not require canvas. This keeps `mb-pdf` consumable by extraction/inspection/validation tooling that never rasterizes.
- **Include PDF 2.0, tagged PDF, or interactive forms in v0.x.** Rejected. Each is a large surface; the 1.4–1.7 document-interchange subset delivers the majority of read/write value first.
- **Duplicate JPEG/PNG/DEFLATE decode in mb-pdf.** Rejected. Filter orchestration is PDF's job; codec implementation belongs to `mb-image` (JPEG, PNG) or shared MNF DEFLATE. Duplication risks drift.

## 9. Compatibility consequences

This RFC proposes a new module and new public dependency edges. It does not modify any accepted module's boundary, public API, dependency direction, or portability seam. If accepted, this RFC adds one row to the allowed public module edges and is subject to the publication and compatibility policies governing all MNF modules.

Because `mb-pdf` would ship as a `candidate`-stability module, it carries no pre-1.0 compatibility promise beyond the executable four-class policy in RFC 0001 Section 10.

This RFC interoperates with, but does not hard-depend on, [RFC 0003](0003-mb-canvas.md), [RFC 0004](0004-mb-font.md), and [RFC 0005](0005-mb-text.md): a PDF renderer is a composition layer consuming `mb-pdf`'s document model, `mb-font`'s outlines, `mb-text`'s shaping, and `mb-canvas`'s rasterization. The container edges (image, color, core) are sufficient for the document-interchange subset.

## 10. Verification plan

Before `mb-pdf` may merge, the implementing phases must produce, consistent with RFC 0001 Section 10:

1. Public and internal tests validating object-model parsing, page-tree traversal, content-stream tokenization, XObject decoding, color-space mapping, and serialization for the in-scope subset.
2. Declared-target CI evidence on `js`, `wasm`, `wasm-gc`, and `native`.
3. Conformance fixtures with provenance and license metadata, covering valid, edge, and hostile PDFs (including decompression-bomb and crafted-reference cases).
4. Deterministic serialization tests proving byte-identical output for a given model and configuration across targets.
5. Deterministic benchmarks with declared workloads and reproducible baselines for parse and serialize.
6. A security and resource-limit review for untrusted PDFs, covering the bounds in Section 7.2.

## 11. What this RFC does not decide

- The exact internal representation of the object model and content-stream operators.
- The exact filter set implemented natively vs. delegated to `mb-image`.
- The exact ICC profile-management depth in v0.x.
- Whether the rendering layer (content-stream-to-canvas) is a package within `mb-pdf` or a separate module.
- The milestone version number and roadmap placement for `mb-pdf` phases.

Any of these, if later shown to affect the module boundary, dependency direction, or portability seam, requires its own RFC per RFC 0001 Section 11.

## 12. References

- [RFC 0001: MoonBit Native Foundation](0001-moonbit-native-foundation.md) — canonical charter
- [RFC 0003: mb-canvas Charter](0003-mb-canvas.md) — rasterization consumer of PDF content streams
- [RFC 0004: mb-font Charter](0004-mb-font.md) — font model for PDF font resources
- [RFC 0005: mb-text Charter](0005-mb-text.md) — shaping for PDF text operators
- [MNF RFC process](../governance/rfc-process.md) — lifecycle, authority routes, and evidence
- PDF Reference 1.7 (ISO 32000-1:2008) and ISO 32000-2 — the format subset referenced by Section 6
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
