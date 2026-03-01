# Script Workflow Guide

This document explains why and how to use the one-command Terraform workflow script.

## Why this script exists
The script standardizes infrastructure operations across environments and reduces operator mistakes.

Key rationale:
- One consistent command interface for `bootstrap`, `infra`, and optional advanced actions.
- Predictable file resolution for environment-specific backend and variable files.
- Safer execution flow by always running `init` and creating a plan before apply.
- Less manual command repetition and fewer copy/paste errors.

## Script location
- `scripts/iac.sh`

## Quickstart
Run from repository root:

```sh
# 0) First-time config setup (create local config files)
cp infra-bootstrap/bootstrap.auto.tfvars.example infra-bootstrap/bootstrap.auto.tfvars
cp infra/backend.hcl.example infra/backend.hcl
cp infra/config.auto.tfvars.example infra/config.auto.tfvars

# 1) Edit config values for your environment
# - set your org/env/location
# - ensure tfstate storage account name is globally unique
# - keep names lowercase where required by Azure resources

# 2) Authenticate once per session
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# 2) One-command full workflow (preflight + bootstrap + infra)
./scripts/iac.sh dev all
```

Naming notes:
- `infra-bootstrap/bootstrap.auto.tfvars` includes `storage_account_name`; this must be globally unique in Azure Storage.
- `infra/config.auto.tfvars` controls environment-scoped names (`env`, `org`, region). Keep these consistent to avoid naming drift.

## Command interface
```sh
./scripts/iac.sh <environment> <action>
```

Supported actions:
- `all` — runs preflight, then bootstrap, then infra as a single command.
- `preflight` — validates tools, Azure auth/subscription context, and resolved config files.
- `bootstrap` — runs `infra-bootstrap` init/plan/apply.
- `infra` — runs `infra` init/plan/apply as a one-command workflow.
- `plan` — runs init and writes a plan file.
- `apply` — runs init, creates a plan, then applies that exact plan (kept for explicit review workflows).
- `recreate` — confirmation-gated destroy + apply for the selected environment.

Examples:
```sh
./scripts/iac.sh dev all
./scripts/iac.sh dev preflight
./scripts/iac.sh dev bootstrap
./scripts/iac.sh dev infra

# optional explicit review flow
./scripts/iac.sh dev plan
./scripts/iac.sh dev apply
./scripts/iac.sh dev recreate
```

## Environment file resolution
The script resolves files in this order.

Backend config:
1. `env/<environment>/backend.hcl`
2. `infra/backend.hcl`

Terraform variables:
1. `env/<environment>/<environment>.tfvars`
2. `infra/config.auto.tfvars`

Bootstrap variables:
1. `env/<environment>/bootstrap.tfvars`
2. `infra-bootstrap/bootstrap.auto.tfvars`

## Safety notes
- `all` executes preflight checks first and fails fast if prerequisites are missing.
- Always inspect `plan` output before applying in shared or production environments.
- `recreate` is destructive and prompts for explicit `YES` confirmation.
- For CI/non-interactive use, set `IAC_SKIP_CONFIRM=true` only in controlled pipelines.
- `bootstrap` uses auto-approve by default to keep bootstrap non-interactive.

## Common gotcha
If you run from inside `infra/`, `./scripts/iac.sh` will not resolve.
Use either:
- run from repo root: `./scripts/iac.sh dev plan`
- or from `infra/`: `../scripts/iac.sh dev plan`
