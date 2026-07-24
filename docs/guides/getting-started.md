<!-- generated-by: gsd-doc-writer -->
# Getting Started

## Prerequisites

Install the MoonBit toolchain used by the repository quality workflow:

| Tool | Version |
| --- | --- |
| `moon` | `0.1.20260713` (`75c7e1f`) |
| `moonc` | `v0.10.4+2cc641edf` |
| `moonrun` | `0.1.20260713` (`75c7e1f`) |

<!-- VERIFY: The repository records the exact toolchain identity but does not contain the external installer instructions. -->

PowerShell is required for the repository quality scripts. No Node.js, Python,
Docker, database, or `.env` file is required by the workspace manifests.

## Installation steps

1. Clone the repository and enter it:

   ```bash
   git clone https://github.com/tchivs/moonbit-foundation.git
   cd moonbit-foundation
   ```

2. Confirm the toolchain is on `PATH`:

   ```powershell
   moon version
   moonc -v
   moonrun --version
   ```

3. Run the required quality lane:

   ```powershell
   ./scripts/quality.ps1 `
     -Lane Required `
     -EvidenceDirectory artifacts/release-qualification/local
   ```

## First run

The smallest runnable document-to-pixels path is the SVG example:

```powershell
moon -C examples/mb-svg-demo run main --target native --frozen
```

It parses bounded SVG input, lowers the scene into a canvas drawing list, and
renders into an `mb-image` RGBA8 surface. The example is portable and can also
be run with `--target js`, `--target wasm`, or `--target wasm-gc`.

## Common setup issues

- **`moon` is not recognized:** install the pinned MoonBit toolchain and make
  sure its binaries are available to the PowerShell process.
- **A frozen command reports manifest drift:** use the repository's declared
  workspace and module manifests; do not run a synchronization command as a
  substitute for resolving the drift.
- **A target is unavailable:** verify the installed toolchain version before
  diagnosing package code. The supported target set is `js`, `wasm`,
  `wasm-gc`, and `native`.
- **A quality run leaves evidence files:** pass an explicit evidence directory
  under `artifacts/` and inspect the generated report rather than copying
  generated files into module source directories.

## Next steps

- Read [`DEVELOPMENT.md`](development.md) for the local edit and review loop.
- Read [`TESTING.md`](../testing/testing.md) for target-specific tests and
  test-file conventions.
- Read [`CONFIGURATION.md`](../configuration/configuration.md) for manifests and
  environment assumptions.
- Read the module README that matches the package you want to consume.
