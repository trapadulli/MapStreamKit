# infra-bootstrap
This module provisions the Azure resource group, storage account, and blob container required for Terraform state.

## Variables
- `location`: Azure region where the Terraform state resource group and storage account will be created (e.g., eastus).
- `resource_group_name`: Name of the Azure Resource Group that will contain the Terraform  state storage account.
- `storage_account_name`: Globally unique Azure Storage Account name used to store Terraform state.  
  Must be 3–24 characters, lowercase letters and numbers only, no hyphens.
- `container_name`: Name of the Blob container inside the storage account where Terraform state files are stored (typically tfstate).

## Usage
Create local config files (do not commit):  
(steps assume you are Azure authenticated as pointed out in root README.md)
1. Copy `bootstrap.auto.tfvars.example` → `bootstrap.auto.tfvars`
2. Edit values as needed. **Note:** Storage account name must be globally unique.
3. Run:
   ```sh
   cd infra-bootstrap
   terraform init
   terraform plan
   terraform apply -var-file=bootstrap.auto.tfvars
   ```

This will create the resource group, storage account, and blob container needed for remote state. Run this before deploying the main infra stack.
