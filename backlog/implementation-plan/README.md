# MapStreamKit Implementation Plan

Purpose: provide an execution-ready task plan for the agreed target architecture and delivery order.

Target runtime topology:
- Head pullers: Container Apps (source-side fetchers)
- Adapter: Function App (trusted ingress funnel to Event Hubs)
- Tail: Function App (Event Hubs consumer to Cosmos)
- GraphQL: client-facing query API over canonical data
- Contract registry flow: deploy-time registration + versioned schema artifacts + update signaling

Status legend: Planned | In Progress | Done | Blocked

## Phase 0 — Alignment and docs

### P0-01: Document agreed architecture in top-level docs
- Priority: P0
- Status: Done
- Tasks:
  - Align root README setup flow and roadmap links.
  - Clarify backlog track structure and ownership.
- Acceptance criteria:
  - Root README links to backlog tracks.
  - Backlog index resolves to per-track READMEs.

### P0-02: Clarify dataflow semantics and naming
- Priority: P0
- Status: Done
- Tasks:
  - Update diagram labels to show direct Event Hubs -> Tail path.
  - Clarify that Storage is auxiliary for schema/checkpoints/DLQ.
  - Add naming note: Tail Processor is backend processor, GraphQL is client API.
- Acceptance criteria:
  - No ambiguity in README dataflow around Event Hubs/Storage/Tail roles.

## Phase 1 — Infrastructure baseline (IaC)

### P1-01: Lock target hosting model in Terraform
- Priority: P0
- Status: Planned
- Tasks:
  - Keep Adapter + Tail as Function Apps in Terraform.
  - Keep/validate App Service Plan dependency for those Function Apps.
  - Keep Head as containerized runtime path (Container Apps/Jobs plan).
- Acceptance criteria:
  - Terraform resources match target topology without contradictory placeholders.

### P1-02: Contract registry storage primitives
- Priority: P0
- Status: Planned
- Tasks:
  - Add schema metadata store (Table Storage or equivalent).
  - Define versioned schema artifact location conventions.
  - Add IAM role assignments for registry writer/reader identities.
- Acceptance criteria:
  - Registry metadata and schema artifacts can be written/read via managed identity.

### P1-03: Runtime config and identity wiring
- Priority: P0
- Status: Planned
- Tasks:
  - Standardize env vars for Adapter/Tail/Head around schema references.
  - Ensure least-privilege RBAC at container/data scope.
  - Validate Event Hub sender/receiver roles and Cosmos permissions.
- Acceptance criteria:
  - Each runtime identity has only required permissions.
  - Runtime apps boot with complete config without key sprawl.

## Phase 2 — Runtime implementation

### P2-01: Adapter minimal ingress contract
- Priority: P0
- Status: Planned
- Tasks:
  - Implement `POST /events` with envelope validation.
  - Publish to Event Hubs with deterministic metadata.
  - Enforce payload size and basic trusted-ingress safeguards.
- Acceptance criteria:
  - Valid envelopes publish successfully; invalid envelopes fail with typed errors.

### P2-02: Tail processing contract enforcement
- Priority: P0
- Status: Planned
- Tasks:
  - Consume Event Hubs using processor consumer group.
  - Resolve schema by version reference and validate payload.
  - Apply dedupe and canonical mapping, then write to Cosmos.
  - Route failures to DLQ and persist checkpoints.
- Acceptance criteria:
  - Replay-safe processing with no duplicate canonical writes.
  - Invalid messages are visible in DLQ with diagnostics.

### P2-03: Head pullers as source adapters
- Priority: P1
- Status: Planned
- Tasks:
  - Implement source puller plugin contract.
  - Emit standardized envelopes to Adapter.
  - Add deploy-time registration hook per source package.
- Acceptance criteria:
  - New puller onboarded by config/contract package without middle-layer code edits.

## Phase 3 — Tooling and automation

### P3-01: Contract publication workflow
- Priority: P0
- Status: Planned
- Tasks:
  - Define `contract.published` event payload schema.
  - CI validates contracts and publishes artifacts + metadata.
  - Emit update signal for GraphQL/codegen consumers.
- Acceptance criteria:
  - Contract publish is versioned, idempotent, and traceable.

### P3-02: GraphQL updater/codegen pipeline
- Priority: P1
- Status: Planned
- Tasks:
  - Consume contract updates and regenerate GraphQL schema/types.
  - Add CI guard for stale generated artifacts.
- Acceptance criteria:
  - GraphQL schema updates are reproducible and policy-checked.

### P3-03: Developer onboarding UX
- Priority: P1
- Status: Planned
- Tasks:
  - Define source package template (schema + mapping + polling config).
  - Add examples and docs for add-a-new-source workflow.
- Acceptance criteria:
  - New provider onboarding follows documented flow end-to-end.

## Phase 4 — Production hardening and governance

### P4-01: Execute production hardening P0 set
- Priority: P0
- Status: Planned
- Tasks:
  - Complete P0 items in production-hardening backlog.
  - Validate via dev -> stage -> prod promotion.
- Acceptance criteria:
  - P0 hardening checklist complete with evidence.

### P4-02: Add policy and operational guardrails
- Priority: P1
- Status: Planned
- Tasks:
  - Alerts, budgets, compliance checks, and CI policy gates.
  - Runbooks and ownership model finalized.
- Acceptance criteria:
  - Incident and change-management controls are operational.

## Immediate next actions
1. Start P1-01 in Terraform: lock target hosting model (Adapter + Tail Function Apps, Head containerized path).
2. Create IaC task issue list for P1-02/P1-03 with owners.
3. Implement Adapter/Tail runtime skeletons against agreed contracts.
