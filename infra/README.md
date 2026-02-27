# MapStreamKit Infra

This directory contains the Terraform code for provisioning all core Azure infrastructure required by MapStreamKit.

## What is provisioned?
- Resource Group
- Azure Event Hubs (namespace, event hub, consumer groups)
- Azure Cosmos DB (serverless, with canonical containers)
- Azure Storage Account (for schema registry, DLQ, checkpoints, replay)
- Azure Key Vault (RBAC model)
- User Assigned Managed Identities (for Functions, Adapter, Processor, GraphQL)
- Application Insights & Log Analytics (observability)
- Role assignments for secure access

## Prerequisites
- [Terraform >= 1.5.0](https://www.terraform.io/downloads.html)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Contributor access to the target Azure subscription

## Usage

> **Note:** The following usage steps are duplicated from the root README for convenience. If in doubt, refer to the root README for the most up-to-date instructions.

1. Authenticate with Azure:
   ```sh
   az login
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```
2. Initialize and apply Terraform:
   ```sh
   cd infra
   terraform init
   terraform plan -var="env=dev" -var="location=eastus" -out=tfplan
   terraform apply tfplan
   ```

## Variables
- `env`: Environment name (dev, stage, prod)
- `location`: Azure region
- `enable_replay`: Enable replay consumer group and container (default: true)
- `eventhub_partitions`: Number of Event Hub partitions (default: 4)
- `eventhub_retention_days`: Event Hub retention (default: 2)
- `tags`: Map of tags to apply to all resources

## Outputs
See `outputs.tf` for all exported values, including resource names, connection strings, and managed identity IDs.

## Destroying Infrastructure
To remove all resources created by this module:
```sh
terraform destroy
```

## Notes
- For production, configure remote state in `backend.tf`.
- Adjust variables as needed for your environment.

---

## Remote State Backend Bootstrap (Required)

If you are using remote state (see backend.tf), you must pre-create the following resources before running `terraform init`:

- Resource Group: `rg-msk-tfstate`
- Storage Account: `stmsktfstate`
- Blob Container: `tfstate`

Terraform cannot provision its own backend resources in the same state. You must create these manually (via Azure Portal, CLI, or a separate bootstrap script) before initializing this stack.
