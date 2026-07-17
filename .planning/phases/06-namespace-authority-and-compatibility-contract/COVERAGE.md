# API Coverage — Mooncakes authority observation

> Full coverage by default. Opt-outs are explicit, reasoned decisions. The deterministic detector fired on the Phase 6 API/OAuth surface; this matrix covers only the read-only authority-observation boundary and does not authorize publication.

| capability | decision | reason |
|---|---|---|
| documented username-prefixed module ownership | INTEGRATE | |
| authenticated personal account identity | INTEGRATE | |
| exact `tchivs` namespace authority | INTEGRATE | |
| exact three-module `tchivs/*` identity observation | INTEGRATE | |
| exact `0.1.0` availability observation | INTEGRATE | |
| authenticated publish-seam observation without mutation | INTEGRATE | |
| capability classification and explicit unknown dispositions | INTEGRATE | |
| automated OAuth registration or login | OPT-OUT | Human GitHub OAuth is an explicit checkpoint and credentials or raw auth output must not enter repository automation. |
| production publish or duplicate-publish probing | OPT-OUT | Phase 6 forbids production registry mutation; ordered publication belongs to Phase 8. |
| overwrite, delete, unpublish, yank, rename, or transfer probing | OPT-OUT | Destructive semantics remain unknown and recovery is forward-only. |
| propagation and published artifact identity proof | OPT-OUT | These require a real published artifact and belong to Phase 8 distribution proof. |
| rendered Mooncakes metadata equality | OPT-OUT | Post-publication rendering is PROV-05 in Phase 8. |
