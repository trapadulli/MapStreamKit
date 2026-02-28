# Infra
This directory contains the Terraform code for provisioning all core Azure infrastructure required by MapStreamKit.

## Remote State Backend Bootstrap (Required)
Before running `terraform init` for the main infra stack, you must provision the remote state resources. Run infra-bootstrap first, or create tfstate resources as configured in your backend.hcl.

Terraform cannot provision its own backend resources in the same state. You must create these manually (via Azure Portal, CLI, or a separate bootstrap script) before initializing this stack.

## Azure Resource Provider Registration (required)
Before running terraform init, ensure your subscription is registered for all required resource providers:

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

Registration may take a few minutes to complete. You only need to do this once per subscription.

## Variables
- `env`: Environment name (dev, stage, prod)
- `location`: Azure region
- `enable_replay`: Enable replay consumer group and container (default: true)
- `eventhub_partitions`: Number of Event Hub partitions (default: 4)
- `eventhub_retention_days`: Event Hub retention (default: 2)
- `tags`: Map of tags to apply to all resources

## Usage
Create local config files (do not commit):  
(steps assume you are Azure authenticated as pointed out in root README.md)
1. Copy `backend.hcl.example` → `backend.hcl`
2. Copy `config.auto.tfvars.example` → `config.auto.tfvars`
3. Edit values as needed.
4. Initialize and apply Terraform:
   ```sh
   cd infra
   terraform init -backend-config=backend.hcl
   terraform plan
   terraform apply
   ```

## What is provisioned?
- Resource Group
- Azure Event Hubs (namespace, event hub, consumer groups)
- Azure Cosmos DB (serverless, with canonical containers)
- Azure Storage Account (for schema registry, DLQ, checkpoints, replay)
- Azure Key Vault (RBAC model)
- User Assigned Managed Identities (for Functions, Adapter, Processor, GraphQL)
- Application Insights & Log Analytics (observability)
- Role assignments for secure access


## Outputs
See `outputs.tf` for all exported values, including resource names, connection strings, and managed identity IDs.

## Destroying Infrastructure
To remove all resources created by this module:
```sh
terraform destroy
```