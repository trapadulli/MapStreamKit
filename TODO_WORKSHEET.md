# TODO Worksheet

Use this as the working checklist for the DAB migration and related cleanup.

## Phase 0 — Alignment
- [ ] Confirm target architecture: `head -> adapter -> eventhub -> tail -> cosmos -> DAB`
- [ ] Confirm DAB scope: GraphQL only or GraphQL + REST
- [ ] Confirm auth model for DAB (Managed Identity vs connection string secret)
- [ ] Confirm whether legacy GraphQL runtime is removed immediately or in Phase 2

## Phase 1 — Add DAB (safe migration)
- [ ] Add `runtime/dab/` folder with DAB config and runtime docs
- [ ] Add DAB container app resource in `infra/compute_shells.tf`
- [ ] Add DAB variables in `infra/variables.tf`
- [ ] Add DAB outputs in `infra/outputs.tf`
- [ ] Add RBAC/secret wiring needed for Cosmos access
- [ ] Deploy infra and confirm DAB container app is healthy
- [ ] Verify DAB endpoint responds for GraphQL query

## Phase 1 Docs Updates
- [ ] Update `README.md` architecture section to show DAB as read API layer
- [ ] Update `TLDR_DEPLOY.md` with DAB deploy and smoke test steps
- [ ] Update `scripts/README.md` release flow notes for DAB
- [ ] Update `infra/README.md` to include DAB resource and outputs

## Phase 2 — Switch + Cleanup
- [x] Switch release workflow from legacy read API script to `release-dab.sh`
- [x] Remove legacy read API runtime code after DAB is validated in env
- [x] Remove GraphQL container app resource from `infra/compute_shells.tf`
- [x] Remove GraphQL image variables from `infra/variables.tf`
- [x] Remove GraphQL outputs from `infra/outputs.tf`
- [x] Remove stale GraphQL docs references

## Validation
- [ ] `terraform -chdir=infra validate`
- [ ] `./scripts/iac.sh dev infra`
- [ ] DAB GraphQL smoke test passes
- [ ] Head health check passes
- [ ] Adapter ingress test passes
- [ ] Tail function trigger still healthy

## Rollback / Safety
- [ ] Keep old GraphQL path available until DAB passes smoke tests
- [ ] Capture rollback command sequence
- [ ] Confirm no cross-service image rollback behavior in release scripts

## Release Readiness
- [ ] README sections reviewed for correctness and consistency
- [ ] Commands tested exactly as documented
- [ ] CI workflow updates complete (if applicable)
- [ ] Final architecture diagram updated (optional)
