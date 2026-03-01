# MapStreamKit Tooling Backlog

Purpose: track tooling workstreams for schema lifecycle and GraphQL generation.

Status legend: Proposed | In Progress | Blocked | Done

## Scope
- `tooling/schema-registry`
- `tooling/graphql-gen`

## Now (MVP)

### T0-01: Schema registry scaffolding
- Priority: P0
- Status: Proposed
- Deliverables:
  - CLI/tool structure for schema publish/version operations.
  - Blob storage path conventions and metadata schema.
  - Validation workflow for schema compatibility rules.
- Acceptance criteria:
  - Team can add and retrieve versioned schemas with documented commands.

### T0-02: GraphQL codegen baseline
- Priority: P0
- Status: Proposed
- Deliverables:
  - Generator config from canonical model source.
  - Output conventions for types/resolvers/contracts.
  - Regeneration command integrated with runtime build flow.
- Acceptance criteria:
  - Codegen output is reproducible and committed/ignored by policy.

## Next

### T1-01: Developer experience automation
- Priority: P1
- Status: Proposed
- Deliverables:
  - Pre-commit or CI checks for schema/codegen drift.
  - Make/npm task wrappers for common tooling commands.
- Acceptance criteria:
  - CI fails when generated artifacts are stale.

### T1-02: Tooling docs and examples
- Priority: P1
- Status: Proposed
- Deliverables:
  - Example workflows for new schema and GraphQL update.
  - Troubleshooting guide for common generation errors.
- Acceptance criteria:
  - New contributor can run tooling flow in <30 minutes.

## Later

### T2-01: Policy and governance integration
- Priority: P2
- Status: Proposed
- Deliverables:
  - Version policy enforcement and approval gates.
  - Audit trail for schema and generated contract changes.
- Acceptance criteria:
  - All production schema changes are traceable and policy-validated.
