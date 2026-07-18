# API Coverage — GitHub Actions and Mooncakes

> Full coverage by default. Opt-outs are explicit, reasoned decisions.

| capability | decision | reason |
|---|---|---|
| github-actions:manual-dispatch | INTEGRATE | Sole maintainer explicitly authorizes one exact release intent. |
| github-actions:actor-repository-ref-sha-binding | INTEGRATE | Publisher must reject any authorization not bound to `tchivs`, the canonical repository, immutable release ref, and exact source SHA. |
| github-actions:root-current-intent-binding | INTEGRATE | Initial and correction intents share the canonical initial intent digest while retaining separately validated current digests. |
| github-actions:full-sha-action-pins | INTEGRATE | Third-party action code must be immutable and reviewable. |
| github-actions:minimal-permissions | INTEGRATE | Preparation uses only `contents: read` and `actions: read`; publisher uses only `actions: read`. |
| github-actions:environment-secret-isolation | INTEGRATE | `MOONCAKES_TOKEN` is referenced only by the guarded shell mutation step. |
| github-actions:release-wide-concurrency | INTEGRATE | Repository plus canonical initial intent digest serializes the entire release lineage with `cancel-in-progress: false` and `queue: max`. |
| github-actions:start-resume-input-contract | INTEGRATE | Genesis and resume modes require mutually exclusive closed input shapes. |
| github-actions:exact-prior-run-artifact | INTEGRATE | Resume accepts only the named artifact from the exact authorized prior run after digest-chain verification. |
| github-actions:content-addressed-prepared-bundle | INTEGRATE | Publisher consumes only the exact current-run preparation output and revalidates every binding and payload digest. |
| github-actions:sanitized-checkpoint-artifacts | INTEGRATE | Monotonic journal checkpoints must survive runner failure without credential material. |
| github-actions:automatic-publish-on-merge | OPT-OUT | Explicit sole-maintainer authorization is required for every exact intent. |
| github-actions:multi-approver-ceremony | OPT-OUT | The project has one maintainer; a second approver would be fictional process. |
| github-actions:oidc-federation | OPT-OUT | Mooncakes OIDC support is not officially established; retain least-privilege secret isolation. |
| github-actions:release-provenance-closure | OPT-OUT | Immutable public ledger and provenance closure belong to Phase 9. |
| mooncakes:local-account-preflight | INTEGRATE | `moon whoami` must match `tchivs`, while remaining explicitly insufficient as remote authority proof. |
| mooncakes:package-archive-dry-run-preflight | INTEGRATE | Exact package/archive verification and `moon publish --dry-run` catch local readiness failures before mutation. |
| mooncakes:one-module-live-mutation-adapter | INTEGRATE | The publisher exposes one guarded dependency-ordered mutation transition at a time. |
| mooncakes:read-only-post-attempt-observation | INTEGRATE | Every success, failure, or ambiguity is re-observed before deciding the next transition. |
| mooncakes:destructive-recovery | OPT-OUT | Overwrite, delete, unpublish, and yank are not verified contracts and must never be assumed. |
| mooncakes:scratch-production-probes | OPT-OUT | Capability testing must not consume or pollute production module versions. |
| mooncakes:ordinary-test-live-publication | OPT-OUT | Required and negative rehearsals must remain credential-free and non-mutating. |
| mooncakes:registry-only-consumer-proofs | OPT-OUT | Independent cold registry consumers and actual dependency-ordered distribution belong to Phase 8. |
