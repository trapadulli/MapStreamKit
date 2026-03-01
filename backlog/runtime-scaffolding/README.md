# MapStreamKit Runtime Scaffolding Backlog

Purpose: track implementation work for runtime services in `runtime/`.

Status legend: Proposed | In Progress | Blocked | Done

## Scope
- `runtime/head` (provider pullers / envelope creation)
- `runtime/adapter` (ingress API to Event Hubs)
- `runtime/tail` (Event Hub processing to canonical store)
- `runtime/graphql` (read API over canonical model)

## Now (MVP)

### R0-01: Scaffold runtime project structure
- Priority: P0
- Status: Proposed
- Deliverables:
  - Language/runtime baseline and folder conventions.
  - Shared config loading and environment validation.
  - Local run scripts for each runtime component.
- Acceptance criteria:
  - Each runtime folder has runnable scaffold.
  - Local startup succeeds with documented env vars.

### R0-02: Implement Adapter ingress skeleton
- Priority: P0
- Status: Proposed
- Deliverables:
  - `POST /events` endpoint contract.
  - Envelope validation and schema checks.
  - Event Hubs publish path using managed identity.
- Acceptance criteria:
  - Valid request returns success and emits event.
  - Invalid request returns typed validation errors.

### R0-03: Implement Tail processor skeleton
- Priority: P0
- Status: Proposed
- Deliverables:
  - EventHub-triggered function handler.
  - Envelope validation + mapping placeholder.
  - Cosmos write path with dedupe key strategy.
- Acceptance criteria:
  - Incoming test events are processed and written to Cosmos.
  - Invalid events are redirected to DLQ path.

## Next

### R1-01: Implement Head pullers baseline
- Priority: P1
- Status: Proposed
- Deliverables:
  - Pull schedule framework and provider adapters.
  - Envelope creation and adapter submission flow.
- Acceptance criteria:
  - At least one provider integration produces valid events.

### R1-02: Add GraphQL read API scaffold
- Priority: P1
- Status: Proposed
- Deliverables:
  - GraphQL service skeleton and schema bootstrap.
  - Basic query path over canonical Cosmos data.
- Acceptance criteria:
  - Health endpoint + sample query works in dev.

## Later

### R2-01: Runtime observability and SLO wiring
- Priority: P2
- Status: Proposed
- Deliverables:
  - Structured logging, trace propagation, error metrics.
  - Service-level dashboards and SLO candidate metrics.
- Acceptance criteria:
  - Correlated traces visible across head/adapter/tail.

### R2-02: Runtime resiliency patterns
- Priority: P2
- Status: Proposed
- Deliverables:
  - Retry policies, dead-letter handling, idempotency safeguards.
  - Backpressure/failure-mode documentation.
- Acceptance criteria:
  - Replay tests confirm no duplicate canonical records.
