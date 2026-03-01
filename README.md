# MapStreamKit

## Overview
MapStreamKit is an Azure-native event control plane for ingesting, normalizing, and exposing external API data streams. It leverages Azure Event Hubs, Cosmos DB, Blob Storage, and more, with all infrastructure managed via Terraform.

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
│  ├─ head/                       # Azure Functions: pull external APIs, build envelopes, POST ingress
│  ├─ adapter/                    # Adapter Ingress: POST /events -> Event Hubs (internal-only)
│  ├─ tail/                       # Azure Functions: EventHubTrigger -> validate -> map -> Cosmos
│  └─ graphql/                    # GraphQL API (later): reads canonical Cosmos + Redis
└─ tooling/
   ├─ schema-registry/            # (later) manage payload schemas (Blob)
   └─ graphql-gen/                # (later) generate GraphQL/types from canonical model
```

### Dataflow (MVP)
```
+-------------------+       POST /events       +----------------------+
| Head Pullers      |------------------------->| Adapter Ingress       |
| (Azure Functions) |                          | (Function or Container|
| - pull providers  |                          |  App)                 |
| - build envelope  |                          | - validate envelope   |
+-------------------+                          | - produce to Event Hub|
                                               +-----------+-----------+
                                                           |
                                                           v
                                                +----------------------+
                                                | Azure Event Hubs     |
                                                | hub: eh-msk-events   |
                                                | CG: processor        |
                                                +----------+-----------+
                                                           |
                                                           v
+------------------+      validate payload schema (Blob)  +----------------------+
| Tail Processor   |<-------------------------------------| Storage (schemas)    |
| (EventHub Func)  |                                      | dlq/checkpoints      |
| - validate env   |                                      +----------------------+
| - validate payload
| - map canonical
| - dedupe in Cosmos (id = f(dedupeKey))
+---------+--------+
          |
          v
+---------------------------+
| Cosmos DB (serverless)    |
| db: msk                   |
| container: raw_envelopes  |
| pk: /partitionKey         |
+---------------------------+
```

- All core Azure resources are provisioned via Terraform modules in `infra/`.
- See each `.tf` file for resource details and outputs.

---

## Prerequisites
- [Terraform >= 1.5.0](https://www.terraform.io/downloads.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Contributor access to the target Azure subscription
- Adjust variables as needed for your environment.

## Getting Started
To set up MapStreamKit infrastructure
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
- [x] Core infra (Event Hubs, Cosmos, Storage, Key Vault, Identities)
- [ ] Runtime code scaffolding (Functions, GraphQL)
- [ ] Tooling (schema registry, GraphQL codegen)

---

## License
MIT
