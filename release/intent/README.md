# Release intent contract

The files in this directory describe the credential-free authorization subject for an MNF module release. `schema.json` and `policy/release-control.json` are authoritative; this document is explanatory only.

The initial intent is compact canonical JSON encoded as UTF-8 without a byte-order mark or trailing whitespace. Objects are emitted in schema order, policy-owned arrays retain policy order, floating-point values and unexpected Unicode are rejected, and unknown properties are not accepted. The initial canonical object deliberately omits `root_intent_sha256`, because embedding its own digest would create a hash cycle. Its SHA-256 becomes both `intent_sha256` and the external `root_intent_sha256` dispatch/journal binding.

A forward correction retains that immutable initial root, names exactly one latest authorized predecessor, advances the correction sequence by one, uses `refs/tags/modules-correction-<positive-decimal>`, and binds incident, advisory, compatibility, version-absence, archive, interface, and qualification evidence. A mismatched old intent is terminal. It cannot resume or mutate; recovery begins from a newly qualified, unpublished, forward version under a fresh source, tag, current digest, and manual authorization.

An intent digest is content identity only. It is not a signature, credential, filename authority, branch authority, local-login proof, dry-run authority, public-account authority, or permission to publish. Required generation and validation never read Mooncakes credentials and never perform publication.
