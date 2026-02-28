terraform {
	backend "azurerm" {
		resource_group_name  = "rg-msk-tfstate"
		storage_account_name = "stmsktfstate"
		container_name       = "tfstate"
		key                  = "terraform.tfstate"
	}
}