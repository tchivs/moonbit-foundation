<!-- generated-by: gsd-doc-writer -->
# Contributing

## Development setup

See [`docs/guides/getting-started.md`](docs/guides/getting-started.md) for
toolchain prerequisites and the first quality run, and
[`docs/guides/development.md`](docs/guides/development.md) for the local edit,
test, and review loop.

## Coding standards

- Keep core algorithms and data models in MoonBit; isolate Native adapters.
- Preserve explicit module boundaries and downward-only public dependencies.
- Preflight checked dimensions, budgets, work, and output before mutation or
  caller-buffer exposure.
- Add black-box public tests and white-box invariant tests for new behavior.
- Run the frozen focused checks and the required quality lane before review.

## Pull request guidelines

- Use a descriptive feature branch such as `feat/mb-image` or `fix/mb-core`;
  no stricter naming convention is currently enforced.
- Keep commits scoped to one contract or module and explain compatibility impact.
- Link an RFC or policy record when changing module boundaries, targets,
  publication policy, or stable API behavior.
- Include test commands and target results in the pull request description.
- Do not commit generated temporary trees, credentials, or unreviewed release
  artifacts.

## Issue reporting

Open an issue at
https://github.com/tchivs/moonbit-foundation/issues with the module, toolchain
version, target, exact command, expected behavior, actual behavior, and a
minimal reproduction or fixture where possible.
