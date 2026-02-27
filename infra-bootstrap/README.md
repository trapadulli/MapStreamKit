# infra-bootstrap

This module provisions the Azure resource group, storage account, and blob container required for Terraform remote state.

## Usage

> **Note:** The following usage steps are duplicated from the root README for convenience. If in doubt, refer to the root README for the most up-to-date instructions.

1. Authenticate with Azure:
   ```sh
   az login
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```
2. Initialize and apply Terraform:
   ```sh
   cd infra-bootstrap
   terraform init
   terraform apply
   ```

This will create the resource group, storage account, and blob container needed for remote state. Run this before deploying the main infra stack.
