# Licensing and Fixture Policy

## Status

Project-authored source, documentation, and generated fixtures are licensed under Apache-2.0. The canonical license terms are in [`LICENSE`](../../LICENSE).

## Active requirements

### Project work

- **Requirement:** New project-authored source and documentation use Apache-2.0.
- **Rationale:** The license is permissive and includes an explicit patent grant while retaining notices and contribution terms.

### Fixture provenance

- **Requirement:** Every fixture record in [`fixtures/manifest.json`](../../fixtures/manifest.json) includes its source, author, retrieval date, SHA-256 digest, SPDX identifier or precise license, redistribution status, and expected use.
- **Rationale:** A fixture is both test evidence and redistributed content. Reproducibility requires identity and provenance; lawful repository inclusion requires known redistribution permission.

### Intake order

- **Requirement:** Prefer generated fixtures whose generator and expected use are documented.
- **Rationale:** Generated inputs reduce licensing ambiguity and make adversarial or conformance cases reproducible.

### External content

- **Requirement:** `PROH-GOV-04-EXTERNAL-FIXTURE` forbids committing an external fixture when redistribution is unconfirmed or any required provenance field is empty.
- **Rationale:** Unconfirmed permission fails closed. A useful test case does not override licensing and provenance obligations.

## Manifest contract

The manifest is versioned and begins with an empty `records` array. Each future non-empty record must satisfy every field listed in `required_record_fields`. `redistribution_status` must be an allowed enumerated value; externally sourced records must use `confirmed`, while `unconfirmed` records are rejected rather than merely warned about.

SHA-256 records fixture identity; it is provenance metadata, not a custom cryptographic protocol. Dates use ISO `YYYY-MM-DD`, licenses use SPDX identifiers when available, and expected use names the conformance, adversarial, regression, or example role.

## Out of scope

- The project license does not grant rights to third-party fixtures.
- A source URL or checksum alone does not establish redistribution permission.
- Generated fixture preference does not permit copying an external input into a generator and relabeling its origin.

## Observable outcome

A contributor can identify the project license before contributing, and automated validation can reject any fixture record with incomplete provenance, an invalid digest, or unconfirmed external redistribution.
