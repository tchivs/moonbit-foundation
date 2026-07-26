# Deferred Items

## Open

- **Full repository Required quality gate is blocked by pre-existing governance
  status drift.**
  - Planned command:
    `.\scripts\quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/local`
  - Wrapper result: the existing wrapper fails before lane execution because
    `Invoke-MoonQuality.ps1` is dot-sourced without its mandatory `Lane`
    parameter.
  - Underlying lane command:
    `.\scripts\quality\Invoke-MoonQuality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/local`
  - Underlying result: all stages through D-14 pass, then the Foundation policy
    stage fails with `RFC header status does not match policy.`
  - Evidence: `policy/foundation.json` records RFC 0001 as `Accepted`, while
    `docs/rfcs/0001-moonbit-native-foundation.md` and
    `docs/rfcs/README.md` still record `Proposed`.
  - Disposition: governance artifacts and the quality wrapper are outside Plan
    97-03 ownership. The root executor will address them in a separate GSD
    quick, then rerun the full repository gate. Font-scoped policy,
    publication, documentation, interface, and four-target tests pass.
