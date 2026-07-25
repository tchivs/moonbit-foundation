<!-- generated-by: gsd-doc-writer -->
# Testing

## Test framework and setup

Tests use MoonBit's built-in `test`, white-box test, and literate-document test
facilities. There is no external Jest, Vitest, PyTest, or Cargo test runner in
the repository. Install the pinned MoonBit toolchain and keep module manifests
frozen for reproducible checks.

## Running tests

Run the repository contract:

```powershell
./scripts/quality.ps1 `
  -Lane Required `
  -EvidenceDirectory artifacts/release-qualification/local
```

Run a focused package or target:

```powershell
moon -C modules/mb-image test png --target native --frozen
moon -C modules/mb-image test png --target js --frozen
moon -C modules/mb-image test png --target wasm --frozen
moon -C modules/mb-image test png --target wasm-gc --frozen
```

Public module documentation is checked with:

```powershell
moon check README.mbt.md --frozen --target native
```

Repeat the command for each declared target when changing a literate example.

## Writing new tests

- `*_test.mbt` files exercise the public API as black-box consumers.
- `*_wbtest.mbt` files cover internal invariants, parsers, checked arithmetic,
  packing, and representation details.
- Inline tests in `*.mbt.md` are public documentation examples and must import
  only the package surface available to a consumer.
- Conformance fixtures live under `fixtures/` and should be referenced through
  test helpers instead of duplicating large binary literals.
- Streaming APIs should cover zero-capacity, one-byte, ragged, released-lease,
  and post-finish schedules, including untouched destination tails.

Match neighboring test names and keep expected bytes or digests independent of
the production planner when validating a wire format.

## Coverage requirements

No line, branch, function, or statement coverage threshold is configured. The
quality contract instead checks exact public interfaces, target matrices,
fixtures, compatibility vectors, resource limits, and deterministic evidence.

## CI integration

The workflow [`.github/workflows/quality.yml`](../../.github/workflows/quality.yml)
runs on pushes and pull requests. Its blocking `required` job verifies the
toolchain identity and runs `./scripts/quality.ps1 -Lane Required`. The
`llvm-experimental` job runs the LLVM lane with `continue-on-error: true`.
