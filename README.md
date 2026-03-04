# MapStreamKit

## Overview
MapStreamKit is an Azure-native event control plane for ingesting, normalizing, and exposing external API data streams. It leverages Azure Event Hubs, Cosmos DB, Blob Storage, and more, with all infrastructure managed via Terraform.

## Prerequisites
- [Terraform >= 1.5.0](https://www.terraform.io/downloads.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Contributor access to the target Azure subscription
- Adjust variables as needed for your environment.

## Azure Resource Provider Registration (required)
Before running Terraform, ensure your subscription is registered for required resource providers (one-time per subscription):

```sh
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.EventHub
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.AlertsManagement
```

## Quickstart
Run from repository root:

```sh
# 0) First-time config setup (create local config files)
cp infra-bootstrap/bootstrap.auto.tfvars.example infra-bootstrap/bootstrap.auto.tfvars
cp env/dev/backend.hcl.example env/dev/backend.hcl
cp env/dev/dev.tfvars.example env/dev/dev.tfvars

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

Script details and rationale: [scripts/README.md](scripts/README.md)

## GraphQL Consumer: code + deploy workflow

GraphQL runtime code is now in `runtime/graphql/`.

Local release (build + push + Terraform deploy in one command):

```sh
./scripts/release-graphql.sh dev <acr_name> [image_tag]
```

This script will:
1. Build `runtime/graphql/Dockerfile`
2. Push image to `<acr_name>.azurecr.io/msk-graphql:<tag>`
3. Deploy infra with `TF_VAR_graphql_container_image` set to that image

CI release workflow is available at `.github/workflows/graphql-release.yml` and can be run manually via GitHub Actions `workflow_dispatch`.

### Architecture
```
MapStreamKit/
├─ README.md
├─ infra-bootstrap/  # creates tfstate RG + storage + container (runs with local state)
│  ├─ providers.tf
│  ├─ main.tf
│  ├─ outputs.tf
│  └─ variables.tf
├─ infra/                         # main stack (uses azurerm backend)
│  ├─ providers.tf
│  ├─ variables.tf
│  ├─ main.tf
│  ├─ outputs.tf
│  ├─ backend.tf                  # declares azurerm backend (configured via backend.hcl)
│  └─ .gitignore                  # or root .gitignore
├─ runtime/
│  ├─ head/                       # Head Puller: pull external APIs, build envelopes, POST to Adapter
│  ├─ adapter/                    # Adapter: POST /events -> Event Hubs (internal-only)
│  ├─ tail/                       # Tail Processor: EventHubTrigger -> validate -> map -> Canonical Store
│  └─ graphql/                    # GraphQL Consumer runtime + Dockerfile
└─ tooling/
   ├─ schema-registry/            # (later) manage payload schemas (Blob)
   └─ graphql-gen/                # (later) generate GraphQL/types from canonical model
```

### Dataflow (MVP)
```
+-------------------+       POST /events       +-----------------------+
| Head Pullers      |------------------------->| Adapter               |
| (AF In Container) |                          | (Function App)        |
| - pull providers  |                          | - validate envelope   | 
| - build envelope  |                          | - produce to Event Hub|
+-------------------+                          +-----------+-----------+
      ^                                                    |
      |                                                    |
      |                                                    v
      |                                              +----------------------+
      |                                              | Azure Event Hubs     |
      |                                              | hub: eh-msk-events   |
      |                                              | CG: processor        |
      |                                              +----------+-----------+
      |                                                         |
      |                                                         v
      |                                               +------------------+
      |                                               | Tail Processor   |
      |                                               | (EventHub Func)  |
      |                                               | - validate env   |
      |                                               | - validate payload
      |                                               | - map canonical
      |                                               | - dedupe in Cosmos (id = f(dedupeKey))
      |                                               +---------+--------+
      |     +---------------------------+                      /|
      |     | Checkpoint Store + DLQ    |<--------------------/ |
      |     +---------------------------+                       V
      |                                               +---------------------------+
      |                                               | Canonical Store (Cosmos)  |
      |                                               | db: msk                   |
      |                                               | container: raw_envelopes  |
      |                                               | pk: /partitionKey         |
      |                                               +---------------------------+   
      |                                                           ^
      |                                                           |
      V                                                           V
+---------------------------------+                   +------------------------------+   
|      Registrar Job              |                   | GraphQL Consumer             |          
| - reads deploy events           |<----------------->| - consumes registrar updates |         
| - validates & updates contracts |                   | - refreshes query schema     |
+---------------------------------+                   +---------------o--------------+
            
```

Naming note: Tail Processor is a backend Event Hubs consumer/mapper; client-facing reads are served by the GraphQL Consumer.

- All core Azure resources are provisioned via Terraform modules in `infra/`.
- See each `.tf` file for resource details and outputs.

---


## Getting Started
To set up MapStreamKit infrastructure step by step (if you don't want to use the Quickstart)
1. Authenticate with Azure:
   ```sh
   az login
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```
Then follow the appropriate step-by-step instructions in:
- `infra-bootstrap/README.md` (for remote state backend bootstrap)
- `infra/README.md` (for main infrastructure deployment)

Each README contains the most up-to-date commands and configuration guidance for its respective module.

---

## Roadmap
Backlog index: [Backlog](backlog/README.md)
Execution plan: [Implementation Plan](backlog/implementation-plan/README.md)

- [x] Core infra (Event Hubs, Cosmos, Storage, Key Vault, Identities)
- [ ] Production hardening (security, networking, observability, guardrails) — [Production Hardening Backlog](backlog/production-hardening/README.md)
- [ ] Runtime code scaffolding (Head Puller, Adapter, Tail Processor, GraphQL Consumer) — [Runtime Scaffolding Backlog](backlog/runtime-scaffolding/README.md)
- [ ] Tooling (schema registry, GraphQL codegen) — [Tooling Backlog](backlog/tooling/README.md)

---

## License
MIT
