<!-- generated-by: gsd-doc-writer -->
# Configuration

## Environment variables

The repository does not define application environment variables. There is no
`.env.example`, `.env` loader, or runtime service configuration in the source
tree. Toolchain executables are discovered from `PATH` by the quality scripts.

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| None | — | — | No runtime environment variables are declared. |

## Configuration files

| File | Format | Purpose |
| --- | --- | --- |
| `moon.work` | MoonBit workspace file | Lists the modules and runnable examples that compose the local workspace. |
| `modules/*/moon.mod.json` | JSON | Declares each module's identity, version, license, targets, and direct module dependencies. |
| `examples/*/moon.mod.json` | JSON | Declares example module identities, targets, and workspace dependencies. |
| `.github/workflows/quality.yml` | YAML | Defines the blocking required CI lane and the non-blocking LLVM experiment. |
| `scripts/quality.ps1` | PowerShell | Selects a quality lane and evidence output directory. |

The module manifests are the source of truth for package boundaries and target
claims. `moon.work` provides local coordination without collapsing the modules
into one publication unit.

## Required vs optional settings

No application startup settings are required because this repository builds
libraries and examples rather than launching a service. A developer must have
the pinned MoonBit executables available to run checks; a missing executable is
reported by the command shell or quality script.

## Defaults

The quality script defaults its evidence directory to
`artifacts/release-qualification/current` when `-EvidenceDirectory` is omitted.
The CI workflow supplies an explicit evidence directory for the required job.
Module manifests default their development version to `0.1.0` candidate status
and declare `native` as the preferred target.

## Per-environment overrides

There are no development, staging, or production environment overlays. Choose
the quality lane and evidence directory at invocation time; keep generated
evidence under `artifacts/` and do not mutate manifests during validation.
