# Phase 7 External API Coverage

| API surface | Capability | Decision |
|---|---|---|
| GitHub Actions | Manual workflow_dispatch with exact actor, repository, ref, SHA, root and current intent | INTEGRATE - sole-maintainer authorization stays explicit and content-addressed. |
| GitHub Actions | Repository plus canonical-initial-root concurrency, queued without cancellation | INTEGRATE - corrections sharing one root cannot escape serialization. |
| GitHub Actions | Start/genesis and exact prior-run resume | INTEGRATE - resume is paired, exact-run, hash-checked, and monotonic. |
| GitHub Actions | Full-SHA actions, read-only preparation, actions-read-only publisher, no publisher checkout | INTEGRATE - least privilege is mechanically reviewable. |
| GitHub Actions | Content-addressed prepared bundle and sanitized checkpoint upload | INTEGRATE - the secret job consumes only verified immutable payloads. |
| GitHub Actions | Dedicated mooncakes-production environment and one step-scoped secret | INTEGRATE - credential exposure begins after non-secret gates. |
| GitHub Actions | Automatic publication | OPT-OUT - irreversible publication requires the Phase 8 checkpoint. |
| GitHub Actions | Multi-approver ceremony | OPT-OUT - exact sole-maintainer intent authorization is the control. |
| GitHub Actions | OIDC federation | OPT-OUT - no verified Mooncakes federation contract exists. |
| GitHub Actions | GitHub Release/provenance closure | OPT-OUT - immutable closure belongs to Phase 9. |
| GitHub Actions | Phase 8 consumers | OPT-OUT - cold registry consumption follows real publication. |
| Mooncakes | Local identity projection, archive checks, and dry-run | INTEGRATE - proves readiness without claiming remote authority. |
| Mooncakes | One guarded mutation then read-only re-observation | INTEGRATE - ambiguity cannot trigger automatic retry. |
| Mooncakes | Destructive recovery | OPT-OUT - overwrite, delete, unpublish, yank, transfer, rename, rollback are forbidden. |
| Mooncakes | Scratch production probes | OPT-OUT - no production version is consumed to test authority. |
| Mooncakes | Ordinary-test live publication | OPT-OUT - Required remains credential-free. |
| Mooncakes | Phase 8 registry-only consumers | OPT-OUT - proof requires the published graph. |
