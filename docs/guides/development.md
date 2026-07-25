<!-- generated-by: gsd-doc-writer -->
# Development

## Local setup

Follow [`GETTING-STARTED.md`](getting-started.md) to install the pinned MoonBit
toolchain and run the first quality lane. The repository has no package-manager
install step: dependencies are declared in `moon.mod.json` and resolved through
`moon.work`.

Before editing a module, read its `README.mbt.md`, `moon.mod.json`, and the RFC
that defines its boundary. Keep changes inside the owning module and update
tests or literate examples with public API changes.

## Build and quality commands

| Command | Description |
| --- | --- |
| `./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/local` | Runs the repository's required quality contract. |
| `./scripts/quality.ps1 -Lane LlvmExperimental` | Runs the non-blocking LLVM experiment. |
| `moon -C modules/mb-image info --target all --frozen` | Checks the image module's target-visible package information. |
| `moon -C modules/mb-image test png --target native --frozen` | Runs the focused PNG package tests on Native. |
| `moon -C examples/mb-svg-demo run main --target native --frozen` | Runs the SVG-to-canvas end-to-end example. |

Use `--frozen` for review and CI-equivalent checks so manifest resolution does
not silently rewrite dependency state.

## Code style

The repository uses MoonBit formatting and checking rather than ESLint,
Prettier, or a JavaScript build system. Keep portable algorithms in MoonBit,
use explicit checked limits before allocation or output, and keep Native FFI
adapters narrow and replaceable. Module literate examples are checked with
commands such as:

```powershell
moon check README.mbt.md --frozen --target native
```

Use the same command for `js`, `wasm`, and `wasm-gc` when validating a public
module README.

## Branch conventions

No formal branch naming policy is documented in the repository. Recent feature
work uses descriptive `feat/<area>` names; keep branch names short and tied to
one module or contract.

## Pull requests

1. Keep a change within one module boundary unless the public contract requires
   a coordinated workspace update.
2. Add or update public black-box tests and internal white-box tests for new
   behavior; preserve frozen compatibility vectors.
3. Run the focused target checks and the required quality lane before requesting
   review.
4. Link the relevant RFC or policy decision when changing a public boundary,
   dependency edge, target claim, or compatibility rule.
5. Describe any generated evidence and keep temporary probe directories out of
   the commit.
