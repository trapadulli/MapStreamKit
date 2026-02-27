# MapStreamKit

## Overview
MapStreamKit is an Azure-native event control plane for ingesting, normalizing, and exposing external API data streams. It leverages Azure Event Hubs, Cosmos DB, Blob Storage, and more, with all infrastructure managed via Terraform.

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
│  ├─ backend.tf                  # (optional) remote state, add later
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
+------------------+       POST /events        +----------------------+
| Head Pullers      |------------------------->| Adapter Ingress       |
| (Azure Functions) |                          | (Function or Container|
| - pull providers  |                          |  App)                 |
| - build envelope  |                          | - validate envelope   |
+------------------+                          | - produce to Event Hub|
                                              +----------+-----------+
                                                         |
                                                         v
                                              +----------------------+
                                              | Azure Event Hubs     |
                                              | hub: eh-smk-events   |
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
| db: smk                   |
| container: raw_envelopes  |
| pk: /partitionKey         |
+---------------------------+
```

- All core Azure resources are provisioned via Terraform modules in `infra/`.
- See each `.tf` file for resource details and outputs.

---


## Getting Started

### 1. Bootstrap Remote State Backend
Before deploying the main infrastructure, you must provision the remote state backend using the infra-bootstrap module:

```sh
cd infra-bootstrap
terraform init
terraform apply
```
This will create the resource group, storage account, and blob container needed for Terraform remote state.

### 2. Review and Customize Variables
Edit variables in `infra/variables.tf` as needed for your environment.

### 3. Authenticate with Azure CLI
```sh
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 4. Deploy Main Infrastructure
```sh
cd infra
terraform init
terraform plan -var="env=dev" -var="location=eastus" -out=tfplan
terraform apply tfplan
```

---

## Roadmap
- [x] Core infra (Event Hubs, Cosmos, Storage, Key Vault, Identities)
- [ ] Runtime code scaffolding (Functions, GraphQL)
- [ ] Tooling (schema registry, GraphQL codegen)

---

## License
MIT
