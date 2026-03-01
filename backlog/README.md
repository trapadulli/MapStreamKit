# MapStreamKit Production Hardening Backlog

Purpose: track production-readiness work for the Azure platform and Terraform codebase.

How to use:
- Move items from Proposed -> In Progress -> Done.
- Implement all P0 items before production go-live.
- Validate each item against its acceptance criteria.

Status legend: Proposed | In Progress | Blocked | Done

## P0 (Must do before production)

### P0-01: Enforce secure Key Vault retention and purge protection
- Priority: P0
- Status: Proposed
- Risk: accidental or malicious secret deletion with no recovery guarantees.
- Current state:
  - Key Vault uses short soft delete retention and purge protection disabled.
- Terraform change proposal:
  - In infra/main.tf:
    - set soft_delete_retention_days to >= 30
    - set purge_protection_enabled = true
  - Add variable toggles and environment-specific defaults in infra/variables.tf + config.auto.tfvars.example.
- Acceptance criteria:
  - terraform plan shows Key Vault hardening changes only.
  - Key Vault has purge protection enabled after apply.
  - Soft-delete retention is configured to approved value.

### P0-02: Remove broad storage permissions and scope access by container role
- Priority: P0
- Status: Proposed
- Risk: over-privileged managed identities increase blast radius.
- Current state:
  - Identities are assigned broad Storage Blob roles at account scope.
- Terraform change proposal:
  - Replace account-level assignments with container-scoped role assignments:
    - ingest: contributor on schemas only.
    - processor: reader on schemas; contributor on dlq/checkpoints.
  - Keep least-privilege policy in role assignment resources.
- Acceptance criteria:
  - No storage data-plane role assignment remains at full account scope for runtime identities.
  - Ingest can write schemas only.
  - Processor can read schemas and write checkpoints/dlq.

### P0-03: Pin runtime images and remove placeholder container image
- Priority: P0
- Status: Proposed
- Risk: non-deterministic deploys and supply chain exposure from floating tags.
- Current state:
  - Container App uses placeholder image with latest tag.
- Terraform change proposal:
  - Add variable adapter_image with immutable digest default format.
  - Update azurerm_container_app.adapter_ingress to use approved registry image digest.
  - Add validation rule to block latest tag in production env.
- Acceptance criteria:
  - Terraform config contains no latest runtime image tags.
  - Production image is pinned by digest.
  - CI policy fails if image is not pinned.

### P0-04: Add baseline alerting and action groups
- Priority: P0
- Status: Proposed
- Risk: silent failures in ingestion and processing path.
- Current state:
  - Logging is configured, but actionable alert rules are not present.
- Terraform change proposal:
  - Add azurerm_monitor_action_group.
  - Add alert rules for:
    - Function failures/exceptions.
    - Event Hub consumer lag / incoming-outgoing mismatch.
    - Cosmos RU throttling and high server-side latency.
    - Storage error spikes for checkpoint/dlq paths.
- Acceptance criteria:
  - Alerts fire in test scenario and route to action group.
  - Alert severity and thresholds documented.
  - On-call runbook link attached in alert descriptions.

### P0-05: Resolve backend config strategy drift
- Priority: P0
- Status: Proposed
- Risk: accidental state collision or incorrect environment targeting.
- Current state:
  - backend.tf contains concrete backend values while docs imply backend.hcl-driven init.
- Terraform change proposal:
  - Keep backend block minimal (empty azurerm backend block).
  - Use backend.hcl per environment for real values.
  - Add explicit env examples: dev/stage/prod backend keys.
- Acceptance criteria:
  - backend.tf contains no hardcoded environment-specific values.
  - infra/README.md has tested init commands per env.
  - Team can initialize any env without editing tracked files.

## P1 (Should do soon after go-live)

### P1-01: Introduce private endpoints and public network lockdown
- Priority: P1
- Status: Proposed
- Risk: public exposure of data plane services.
- Terraform change proposal:
  - Add VNet/subnets and private endpoints for Storage, Key Vault, Cosmos, Event Hubs.
  - Disable public network access where supported.
  - Configure private DNS zones and links.
- Acceptance criteria:
  - Data services resolve via private endpoints from runtime subnets.
  - Public network access disabled for production resources.

### P1-02: Move Function host storage access toward identity-based model
- Priority: P1
- Status: Proposed
- Risk: long-lived access keys in app settings increase secret management burden.
- Terraform change proposal:
  - Migrate storage authentication path to managed identity where platform support allows.
  - Remove storage account key references from app settings.
- Acceptance criteria:
  - No storage account keys required in Function app settings in production.
  - Runtime still passes cold start and trigger processing tests.

### P1-03: Add budget and cost guardrails
- Priority: P1
- Status: Proposed
- Risk: serverless and event burst patterns can produce unexpected spend.
- Terraform change proposal:
  - Add budget resources and cost anomaly alerting.
  - Add usage dashboards for Event Hubs ingress, Cosmos RU, and Function execution.
- Acceptance criteria:
  - Budget alerts exist for monthly thresholds.
  - Dashboard available for platform owners.

### P1-04: Separate Terraform into logical modules
- Priority: P1
- Status: Proposed
- Risk: monolithic files increase change risk and reduce reusability.
- Terraform change proposal:
  - Split into modules: core-data, security-identity, observability, compute.
  - Keep root composition and environment tfvars stable.
- Acceptance criteria:
  - Module boundaries documented.
  - terraform plan output unchanged for equivalent inputs.

## P2 (Scale, governance, and long-term resilience)

### P2-01: Add policy-as-code guardrails
- Priority: P2
- Status: Proposed
- Risk: future drift away from security baseline.
- Terraform change proposal:
  - Add Azure Policy assignments for:
    - required tags
    - deny public network on data services
    - diagnostic settings required
    - approved regions/SKUs
- Acceptance criteria:
  - Non-compliant resources are denied or remediated per policy intent.
  - Compliance dashboard is visible to platform owners.

### P2-02: Multi-region recovery design
- Priority: P2
- Status: Proposed
- Risk: regional outage affects control-plane availability and data continuity.
- Terraform change proposal:
  - Define DR strategy for Event Hubs/Cosmos/Storage and failover runbooks.
  - Add secondary region primitives where justified by RTO/RPO.
- Acceptance criteria:
  - RTO/RPO documented and tested in tabletop exercise.
  - Failover steps validated in non-prod.

### P2-03: CI/CD hardening gates
- Priority: P2
- Status: Proposed
- Risk: unsafe or non-compliant changes reaching production.
- Terraform change proposal:
  - Add pipeline checks: fmt/validate/tflint/tfsec/checkov + policy checks.
  - Require manual approval for production apply.
- Acceptance criteria:
  - Merge is blocked on failed IaC security/compliance checks.
  - Production apply requires explicit approval.

## Suggested implementation sequence
1. Execute P0-05 (backend strategy) first to protect state operations.
2. Execute P0-01 and P0-02 (security baseline).
3. Execute P0-03 and P0-04 (runtime deploy safety + alerting).
4. Run production readiness review and sign-off.

## Notes
- This backlog assumes existing runtime code is still scaffolding stage.
- Any item that can break existing behavior should land behind environment-specific toggles for safe rollout.
