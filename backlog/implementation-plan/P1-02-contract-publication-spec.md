# P1-02 Spec — Deploy-time Contract Publication and Registrar Workflow

Purpose: define the deploy-time control-plane flow for contract publication, without introducing runtime contract metadata lookups.

## Status
- Phase: P1-02
- Owner: Platform + Tooling
- Effective date: 2026-03-03

## Scope
- Contract publication at deploy time (manual in dev first, CI-driven later).
- Versioned artifact storage for contracts and generated GraphQL outputs.
- Registrar-triggered update signaling for GraphQL Consumer/codegen.

## Out of scope
- Runtime Table Storage or any runtime contract registry dependency.
- Runtime dynamic schema resolution over metadata tables.
- Full CI pipeline implementation (covered by later items).

## Design principles
- Runtime data plane remains independent from control-plane metadata stores.
- Contract publication must be idempotent and traceable.
- Artifacts are immutable by version.
- Promotion follows environment boundaries (dev -> stage -> prod).

## Contract identity and versioning
- Contract key: `{provider}.{domain}.{entity}` (lowercase, dot-separated).
- Version format: SemVer (`MAJOR.MINOR.PATCH`).
- Immutable version rule: once published, same key+version cannot be overwritten.
- Recommended alias pointers (mutable): `latest`, `latest-major` (for tooling only, not runtime).

## Artifact model

### Storage location
- Primary store: existing `schemas` blob container.
- Path conventions:
  - Canonical contract: `contracts/{contract_key}/{version}/contract.json`
  - Validation report: `contracts/{contract_key}/{version}/validation.json`
  - Metadata envelope: `contracts/{contract_key}/{version}/publish.json`
  - GraphQL SDL output: `graphql/{contract_key}/{version}/schema.graphql`
  - Generated types output: `graphql/{contract_key}/{version}/types.json`

### `publish.json` minimal fields
- `eventId` (uuid)
- `publishedAt` (ISO-8601 UTC)
- `environment` (`dev|stage|prod`)
- `contractKey`
- `version`
- `contentHash` (sha256 of `contract.json`)
- `sourceCommit` (git SHA)
- `publisher` (user/service principal)
- `status` (`published`)

## Registrar workflow

### Dev (manual-first)
1. Author/update contract in source package.
2. Run local validation (`schema lint`, compatibility checks, examples).
3. Publish versioned artifacts to `schemas` container paths.
4. Emit `contract.published` control event.
5. Run GraphQL regeneration/update task.
6. Validate generated outputs and commit.

### Stage/Prod (pipeline target)
1. Validate on PR merge.
2. Publish artifacts with service identity.
3. Emit `contract.published` event.
4. Run policy checks (diff, breaking-change gate, approval).
5. Promote artifacts/environment references.

## Control event: `contract.published`

### Event contract (JSON)
```json
{
  "eventType": "contract.published",
  "eventVersion": "1.0",
  "eventId": "3f7f1f3e-3f17-4e5b-902f-d8e84f8f5d7d",
  "occurredAt": "2026-03-03T12:00:00Z",
  "environment": "dev",
  "contract": {
    "key": "provider.orders.order",
    "version": "1.3.0",
    "contentHash": "sha256:...",
    "uri": "https://<storage>/schemas/contracts/provider.orders.order/1.3.0/contract.json"
  },
  "artifacts": {
    "publishMetaUri": "https://<storage>/schemas/contracts/provider.orders.order/1.3.0/publish.json",
    "graphqlSchemaUri": "https://<storage>/schemas/graphql/provider.orders.order/1.3.0/schema.graphql"
  },
  "source": {
    "repo": "MapStreamKit",
    "commit": "<git-sha>",
    "publisher": "<identity>"
  }
}
```

### Delivery and idempotency rules
- `eventId` is unique per publication attempt.
- Duplicate `(contract.key, contract.version, contentHash)` is no-op.
- Different hash for existing key+version is rejected.
- Consumers process by `(contract.key, contract.version)` and ignore duplicates.

## Security and access model
- Publish identity requires write to `schemas` container only.
- Runtime identities (Adapter/Tail Processor) do not require contract metadata table access.
- GraphQL Consumer/tooling identities require read access to published artifacts.
- All publication actions must include trace fields (`eventId`, `sourceCommit`, `publisher`).

## Operational checks
- Pre-publish: schema valid + compatibility policy pass.
- Post-publish: artifact paths exist and hashes match.
- Post-event: GraphQL generation receives event and updates outputs.
- Audit: publication record searchable by `contractKey`, `version`, `sourceCommit`.

## Failure handling
- Validation failure: block publication, return typed error report.
- Artifact write failure: retry with backoff, no event emission on final failure.
- Event emission failure: retry idempotently using same `eventId`.
- GraphQL update failure: mark run as failed, keep contract publication immutable.

## Acceptance criteria (P1-02)
- A contract can be published in `dev` using manual registrar workflow.
- Published artifacts are versioned and immutable at key+version.
- `contract.published` payload conforms to this spec.
- GraphQL Consumer/tooling receives signal and resolves artifact URIs.
- No runtime Table Storage dependency is introduced.

## Implementation notes
- Initial execution can be script-driven from `tooling/schema-registry`.
- CI/CD enforcement and approvals are completed under P3-01/P3-02.
